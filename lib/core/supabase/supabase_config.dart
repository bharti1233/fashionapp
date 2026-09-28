import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration (build-time, no committed secrets).
///
/// Resolution order for each value:
///   1. `--dart-define` (CI / release builds via GitHub Secrets)
///   2. `.env` file (local development only, never committed)
///
/// Precedence of key names: `SUPABASE_PUBLISHABLE_KEY` (preferred, current
/// Supabase terminology) then `SUPABASE_ANON_KEY` (legacy name, still
/// accepted by the `supabase_flutter` SDK as the `anonKey` parameter).
///
/// Missing configuration fails fast with a clear message instead of
/// silently connecting anywhere. Only the publishable/anon key may be
/// shipped in the app — never a service_role / secret key.
class SupabaseConfig {
  static const _urlKey = 'SUPABASE_URL';
  static const _publishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const _anonKey = 'SUPABASE_ANON_KEY';

  static String _resolve(List<String> defineKeys, List<String> envKeys) {
    for (final key in defineKeys) {
      final value = String.fromEnvironment(key);
      if (value.isNotEmpty) return value;
    }
    if (dotenv.isInitialized) {
      for (final key in envKeys) {
        final value = dotenv.env[key];
        if (value != null && value.isNotEmpty) return value;
      }
    }
    throw StateError(
      'Missing Supabase configuration. Provide it via '
      '--dart-define=${defineKeys.first}=... '
      'or a local .env file (see .env.example).',
    );
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    try {
      return _resolve([_urlKey], [_urlKey]);
    } on StateError catch (e) {
      // Re-throw with more context
      throw StateError('SUPABASE_URL not configured. ${e.message}');
    }
  }

  /// Supabase publishable (anon) key — safe to expose in the client.
  /// Protected server-side by RLS; never use a service_role key here.
  static String get supabaseAnonKey {
    try {
      return _resolve([_publishableKey, _anonKey], [_publishableKey, _anonKey]);
    } on StateError catch (e) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) not configured. ${e.message}',
      );
    }
  }

  // Storage bucket names
  static const String productImagesBucket = 'product-images';
  static const String categoryImagesBucket = 'category-images';
  static const String brandLogosBucket = 'brand-logos';
  static const String bannerImagesBucket = 'banner-images';
  static const String avatarsBucket = 'avatars';
  static const String reviewImagesBucket = 'review-images';
}
