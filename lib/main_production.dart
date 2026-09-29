import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/t_store.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first - before anything else
  await AppLogger.instance.initialize();
  await AppLogger.instance.recordStartup();

  // Preserve native splash until we explicitly remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Log app start
  AppLogger.instance.info(
    message: 'Application started',
    category: LogCategory.startup,
    screen: 'main',
    operation: 'appStart',
  );

  // Load environment variables (optional: CI supplies --dart-define instead).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY must come
    // from --dart-define. SupabaseConfig fails clearly if both are missing.
  }

  // Initialize Supabase with timeout to prevent indefinite hang
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
      screen: 'main',
      operation: 'supabaseInit',
    );
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      message: 'Supabase initialization failed',
      category: LogCategory.supabase,
      screen: 'main',
      operation: 'supabaseInit',
      error: e,
      stackTrace: stackTrace,
    );
    // Show error UI instead of hanging on splash
    runApp(const _StartupErrorScreen(error: 'Supabase initialization failed'));
    return;
  }

  // Setup dependency injection (Supabase-based services)
  try {
    await setupServiceLocator();
    AppLogger.instance.info(
      message: 'Service locator setup completed',
      category: LogCategory.startup,
      screen: 'main',
      operation: 'serviceLocatorInit',
    );
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      message: 'Service locator setup failed',
      category: LogCategory.startup,
      screen: 'main',
      operation: 'serviceLocatorInit',
      error: e,
      stackTrace: stackTrace,
    );
    runApp(const _StartupErrorScreen(error: 'Service initialization failed'));
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
    screen: 'main',
    operation: 'appReady',
  );

  // Remove native splash screen
  FlutterNativeSplash.remove();

  runApp(const TStore());
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

/// Error screen shown when startup fails
class _StartupErrorScreen extends StatelessWidget {
  final String error;

  const _StartupErrorScreen({required this.error});

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
                      onPressed: () {
                        // Navigate to app logs - for now just show snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logs are available in Settings > App Logs'),
                          ),
                        );
                      },
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
