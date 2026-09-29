import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// Regression tests for the Phase 1 splash-screen hang.
///
/// Contract: a startup failure (e.g. Supabase init throwing in main())
/// MUST produce a persistent, viewable, copyable log entry. If logging the
/// failure ever throws or drops the entry, the error screen has nothing to
/// show and diagnosis is impossible.
void main() {
  group('Startup failure logging', () {
    test('supabase init failure is recorded as persistent error log', () async {
      await AppLogger.instance.initialize();

      const marker = 'startup-failure-marker-supabase-init';
      final error = StateError('SUPABASE_URL not configured');
      final stackTrace = StackTrace.current;

      AppLogger.instance.error(
        message: 'Supabase initialization failed: $marker',
        category: LogCategory.supabase,
        screen: 'main',
        operation: 'supabaseInit',
        error: error,
        stackTrace: stackTrace,
      );

      final matches = AppLogger.instance.searchLogs(marker);
      expect(matches, isNotEmpty);

      final entry = matches.last;
      expect(entry.level, LogLevel.error);
      expect(entry.category, LogCategory.supabase);
      expect(entry.screen, 'main');
      expect(entry.operation, 'supabaseInit');
      expect(entry.errorType, 'StateError');
      expect(entry.stackTrace, isNotNull);
    });

    test('recorded failure is included in the copyable log export', () async {
      await AppLogger.instance.initialize();

      const marker = 'startup-failure-marker-log-export';
      AppLogger.instance.error(
        message: 'Service initialization failed: $marker',
        category: LogCategory.startup,
        screen: 'main',
        operation: 'serviceLocatorInit',
      );

      final exported = AppLogger.instance.exportLogsAsText();
      expect(exported, contains(marker));
      expect(exported, contains('serviceLocatorInit'));
    });

    test('logger never throws, even for startup failures', () async {
      await AppLogger.instance.initialize();

      expect(
        () => AppLogger.instance.error(
          message: 'boom',
          category: LogCategory.startup,
          screen: 'main',
          operation: 'appStart',
        ),
        returnsNormally,
      );
    });
  });
}
