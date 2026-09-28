import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/t_store.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve native splash until we explicitly remove it
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
  } catch (e) {
    // Log error but continue - app should show error UI rather than hang on splash
    debugPrint('Supabase initialization failed: $e');
    // We'll let the app start and show error UI through the normal flow
  }

  // Setup dependency injection (Supabase-based services)
  try {
    await setupServiceLocator();
  } catch (e) {
    debugPrint('Service locator setup failed: $e');
  }

  // Remove native splash screen
  FlutterNativeSplash.remove();

  runApp(const TStore());
}
