import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/supabase/supabase_config.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/utils/logging/app_bloc_observer.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/t_store.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Global safety net: uncaught cubit/bloc errors reach AppLogger.
  Bloc.observer = AppBlocObserver();

  // Initialize logger first - before anything else
  await AppLogger.instance.initialize();
  await AppLogger.instance.recordStartup();

  // Preserve native splash until we explicitly remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Log app start
  AppLogger.instance.info(
    message: 'Application started',
    category: LogCategory.startup,
    event: 'APP_START',
    screen: 'main',
    operation: 'appStart',
  );

  // Detect a previous launch that never finished starting up.
  await AppLogger.instance.logPreviousSessionCrashIfNeeded();

  // Load environment variables (optional: CI supplies --dart-define instead).
  AppLogger.instance.info(
    message: 'Loading configuration',
    category: LogCategory.startup,
    event: 'CONFIG_LOADING',
    screen: 'main',
    operation: 'configLoad',
  );
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY must come
    // from --dart-define. SupabaseConfig fails clearly if both are missing.
  }

  // Report ONLY whether each value is configured — never the values.
  AppLogger.instance.info(
    message:
        'SUPABASE_URL configured: ${SupabaseConfig.isUrlConfigured ? 'YES' : 'NO'}',
    category: LogCategory.startup,
    event: 'CONFIG_RESOLVED',
    screen: 'main',
    operation: 'configLoad',
  );
  AppLogger.instance.info(
    message:
        'SUPABASE_PUBLISHABLE_KEY configured: ${SupabaseConfig.isKeyConfigured ? 'YES' : 'NO'}',
    category: LogCategory.startup,
    event: 'CONFIG_RESOLVED',
    screen: 'main',
    operation: 'configLoad',
  );

  // Initialize Supabase with timeout to prevent indefinite hang
  AppLogger.instance.info(
    message: 'Supabase initialization started',
    category: LogCategory.supabase,
    event: 'SUPABASE_INIT_START',
    screen: 'main',
    operation: 'supabaseInit',
  );
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Supabase initialization timed out after 15 seconds');
      },
    );
    AppLogger.instance.info(
      message: 'Supabase initialization completed',
      category: LogCategory.supabase,
      event: 'SUPABASE_INIT_SUCCESS',
      screen: 'main',
      operation: 'supabaseInit',
    );
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      message: 'Supabase initialization failed',
      category: LogCategory.supabase,
      event: 'SUPABASE_INIT_FAILURE',
      screen: 'main',
      operation: 'supabaseInit',
      error: e,
      stackTrace: stackTrace,
    );
    // Show error UI instead of hanging on splash
    _showStartupError('Supabase initialization failed: $e');
    return;
  }

  // Setup dependency injection (Supabase-based services)
  AppLogger.instance.info(
    message: 'Service locator setup started',
    category: LogCategory.startup,
    event: 'DI_INIT_START',
    screen: 'main',
    operation: 'serviceLocatorInit',
  );
  try {
    await setupServiceLocator();
    AppLogger.instance.info(
      message: 'Service locator setup completed',
      category: LogCategory.startup,
      event: 'DI_INIT_SUCCESS',
      screen: 'main',
      operation: 'serviceLocatorInit',
    );
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      message: 'Service locator setup failed',
      category: LogCategory.startup,
      event: 'DI_INIT_FAILURE',
      screen: 'main',
      operation: 'serviceLocatorInit',
      error: e,
      stackTrace: stackTrace,
    );
    _showStartupError('Service initialization failed: $e');
    return;
  }

  // Setup global error handlers
  _setupGlobalErrorHandlers();

  // Mark startup as completed
  await AppLogger.instance.markStartupComplete();

  // Log app ready
  AppLogger.instance.info(
    message: 'Application ready',
    category: LogCategory.startup,
    event: 'APP_READY',
    screen: 'main',
    operation: 'appReady',
  );

  // Remove native splash screen. Guarded so a failure here can never
  // skip runApp() and strand the user on the splash logo.
  try {
    FlutterNativeSplash.remove();
  } catch (_) {
    // Splash already removed or unavailable — continue to the app.
  }

  runApp(const TStore());
}

/// Remove the native splash (if still present) and show the startup error UI.
///
/// The splash MUST be removed on every failure path: FlutterNativeSplash
/// was preserved at startup, so showing the error screen WITHOUT removing
/// the splash leaves the error UI hidden underneath the logo forever —
/// which is exactly the "stuck on splash" symptom.
void _showStartupError(String error) {
  try {
    FlutterNativeSplash.remove();
  } catch (_) {
    // Splash already removed or unavailable — error screen must still show.
  }
  runApp(_StartupErrorScreen(error: error));
}

/// Setup global error handlers for uncaught errors
void _setupGlobalErrorHandlers() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.error(
      message: 'Flutter error: ${details.exceptionAsString()}',
      category: LogCategory.system,
      screen: details.library ?? 'unknown',
      operation: 'flutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Handle platform dispatcher errors (uncaught async errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.fatal(
      message: 'Unhandled platform error: $error',
      category: LogCategory.system,
      screen: 'unknown',
      operation: 'platformError',
      error: error,
      stackTrace: stack,
    );
    return true; // Prevent the error from propagating further
  };
}

/// Error screen shown when startup fails.
/// Never leaves the user on the splash: callers must route through
/// [_showStartupError] so the native splash is removed first.
class _StartupErrorScreen extends StatelessWidget {
  final String error;

  const _StartupErrorScreen({required this.error});

  void _showLogsDialog(BuildContext context) {
    final logsText = AppLogger.instance.exportLogsAsText();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Application Logs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: SingleChildScrollView(
              child: SelectableText(
                logsText.isEmpty ? 'No logs recorded yet.' : logsText,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CLOSE'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: logsText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('COPY LOG'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Unable to connect to the application service.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Restart the app
                        exit(0);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showLogsDialog(context),
                      icon: const Icon(Icons.description),
                      label: const Text('VIEW ERROR LOG'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
