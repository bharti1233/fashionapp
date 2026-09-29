import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/core/supabase/supabase_config.dart';

/// Regression tests for the Phase 1 splash-screen hang.
///
/// Root cause contract: when Supabase configuration is missing, the app must
/// fail FAST with a clear [StateError] so main() can route to the visible
/// startup error screen. If these getters ever returned an empty string
/// instead, `Supabase.initialize` would fail deep inside the SDK (or hang on
/// network), and the user would be stranded on the splash logo.
void main() {
  group('SupabaseConfig fail-fast contract', () {
    test('supabaseUrl throws StateError when unconfigured', () {
      // flutter test provides no --dart-define and no .env,
      // so this must throw rather than return an empty URL.
      expect(
        () => SupabaseConfig.supabaseUrl,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test('supabaseAnonKey throws StateError when unconfigured', () {
      expect(
        () => SupabaseConfig.supabaseAnonKey,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_PUBLISHABLE_KEY'),
          ),
        ),
      );
    });

    test('missing config never yields an empty string', () {
      for (final getter in [
        () => SupabaseConfig.supabaseUrl,
        () => SupabaseConfig.supabaseAnonKey,
      ]) {
        try {
          final value = getter();
          // If configured (e.g. defines supplied), value must be non-empty.
          expect(value, isNotEmpty);
        } on StateError {
          // Expected when unconfigured: fail fast, never empty.
        }
      }
    });
  });
}
