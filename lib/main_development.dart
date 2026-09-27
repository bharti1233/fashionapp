import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:t_store/core/supabase/supabase_service.dart';
import 'package:t_store/core/dependency_injection/service_locator.dart';
import 'package:t_store/t_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional: --dart-define works too).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env present — SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY must come
    // from --dart-define. SupabaseConfig fails clearly if both are missing.
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  // Setup dependency injection (Supabase-based services)
  await setupServiceLocator();

  runApp(const TStore());
}
