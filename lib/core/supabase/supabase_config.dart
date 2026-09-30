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
/// CRITICAL: `--dart-define` values are read through `static const`
/// [String.fromEnvironment] fields with literal key names below. In
/// AOT/release builds the compiler substitutes define values ONLY into
/// `const` evaluations — a runtime call such as
/// `String.fromEnvironment(variableKey)` always yields `''` in release
/// (while still working in debug/JIT), which previously produced
/// "SUPABASE_URL not configured" in the release APK even though CI
/// passed the defines correctly. Never refactor these reads into a
/// runtime loop over key names.
///
/// Missing configuration fails fast with a clear message instead of
/// silently connecting anywhere. Only the publishable/anon key may be
/// shipped in the app — never a service_role / secret key.
class SupabaseConfig {
  static const _urlKey = 'SUPABASE_URL';
  static const _publishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const _anonKey = 'SUPABASE_ANON_KEY';

  // Compile-time define reads. MUST remain `static const` with literal
  // names — see the class documentation above.
  static const _defineUrl = String.fromEnvironment(_urlKey);
  static const _definePublishableKey = String.fromEnvironment(_publishableKey);
  static const _defineAnonKey = String.fromEnvironment(_anonKey);

  /// Pure resolution logic for the Supabase URL, testable via injection.
  /// [defineUrl] is the compile-time `--dart-define` value, [envUrl] the
  /// `.env` fallback. Throws [StateError] when both are missing/empty —
  /// never returns an empty string.
  static String resolveSupabaseUrl({
    required String defineUrl,
    String? envUrl,
  }) {
    if (defineUrl.isNotEmpty) return defineUrl;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    throw StateError(
      'SUPABASE_URL not configured. Provide it via '
      '--dart-define=SUPABASE_URL=... '
      'or a local .env file (see .env.example).',
    );
  }

  /// Pure resolution logic for the publishable key, testable via injection.
  /// Throws [StateError] when every source is missing/empty — never
  /// returns an empty string.
  static String resolveSupabaseKey({
    required String defineKey,
    required String legacyDefineKey,
    String? envKey,
    String? legacyEnvKey,
  }) {
    if (defineKey.isNotEmpty) return defineKey;
    if (legacyDefineKey.isNotEmpty) return legacyDefineKey;
    if (envKey != null && envKey.isNotEmpty) return envKey;
    if (legacyEnvKey != null && legacyEnvKey.isNotEmpty) return legacyEnvKey;
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) not configured. '
      'Provide it via --dart-define=SUPABASE_PUBLISHABLE_KEY=... '
      'or a local .env file (see .env.example).',
    );
  }

  /// Non-throwing probe for diagnostics: reports whether the URL is
  /// configured WITHOUT exposing its value. Safe to log.
  static bool get isUrlConfigured {
    try {
      return supabaseUrl.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Non-throwing probe for diagnostics: reports whether the publishable
  /// key is configured WITHOUT exposing its value. Safe to log.
  static bool get isKeyConfigured {
    try {
      return supabaseAnonKey.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// `.env` lookup that treats missing/uninitialized/empty as absent.
  static String? _dotenvValue(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    try {
      return resolveSupabaseUrl(
        defineUrl: _defineUrl,
        envUrl: _dotenvValue(_urlKey),
      );
    } on StateError catch (e) {
      // Re-throw with more context
      throw StateError('SUPABASE_URL not configured. ${e.message}');
    }
  }

  /// Supabase publishable (anon) key — safe to expose in the client.
  /// Protected server-side by RLS; never use a service_role key here.
  static String get supabaseAnonKey {
    try {
      return resolveSupabaseKey(
        defineKey: _definePublishableKey,
        legacyDefineKey: _defineAnonKey,
        envKey: _dotenvValue(_publishableKey),
        legacyEnvKey: _dotenvValue(_anonKey),
      );
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
