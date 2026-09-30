import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// Tests for the live, local-first application logger:
/// creation, live stream, persistence helpers, error capture,
/// startup-interruption detection, redaction, filtering, clearing,
/// and logger failure isolation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLogger.instance.initialize();
  });

  group('Log creation', () {
    test('entry records event, session, screen and operation', () {
      const marker = 'creation-marker-event-session';
      AppLogger.instance.info(
        message: 'probe $marker',
        category: LogCategory.startup,
        event: 'CONFIG_RESOLVED',
        screen: 'main',
        operation: 'configLoad',
      );

      final matches = AppLogger.instance.searchLogs(marker);
      expect(matches, isNotEmpty);
      final entry = matches.last;
      expect(entry.event, 'CONFIG_RESOLVED');
      expect(entry.sessionId, AppLogger.instance.sessionId);
      expect(entry.sessionId, isNotEmpty);
      expect(entry.screen, 'main');
      expect(entry.operation, 'configLoad');
      expect(entry.level, LogLevel.info);
    });

    test('error captures type and stack trace', () {
      const marker = 'creation-marker-error-stack';
      final stack = StackTrace.current;
      AppLogger.instance.error(
        message: 'probe $marker',
        category: LogCategory.supabase,
        event: 'SUPABASE_INIT_FAILURE',
        error: StateError('bad state'),
        stackTrace: stack,
      );

      final entry = AppLogger.instance.searchLogs(marker).last;
      expect(entry.errorType, 'StateError');
      expect(entry.stackTrace, isNotNull);
      expect(entry.stackTrace, contains('app_logger_test'));
    });
  });

  group('Live stream', () {
    test('new entries are emitted on logStream immediately', () async {
      const marker = 'stream-marker-live-update';
      final future = expectLater(
        AppLogger.instance.logStream,
        emits(
          isA<AppLogEntry>().having(
            (e) => e.message,
            'message',
            contains(marker),
          ),
        ),
      );

      AppLogger.instance.warning(
        message: 'probe $marker',
        category: LogCategory.system,
        event: 'LIVE_PROBE',
      );

      await future;
    });
  });

  group('Secret redaction', () {
    test('sensitive context values are redacted', () {
      const marker = 'redaction-marker-secrets';
      AppLogger.instance.info(
        message: 'probe $marker',
        category: LogCategory.authentication,
        context: {
          'password': 'hunter2',
          'Authorization': 'Bearer real-jwt-value',
          'api_key': 'sk-live-value',
          'username': 'plain-user',
        },
      );

      final entry = AppLogger.instance.searchLogs(marker).last;
      final context = entry.context!;
      expect(context['password'], '[REDACTED]');
      expect(context['Authorization'], '[REDACTED]');
      expect(context['api_key'], '[REDACTED]');
      expect(context['username'], 'plain-user');

      final exported = AppLogger.instance.exportLogsAsText();
      expect(exported, isNot(contains('hunter2')));
      expect(exported, isNot(contains('real-jwt-value')));
    });
  });

  group('Log filtering', () {
    AppLogEntry makeEntry(String message, LogLevel level, LogCategory cat) {
      return AppLogEntry.create(level: level, category: cat, message: message);
    }

    test('level filter keeps only selected levels', () {
      const filter = LogFilter(levels: {LogLevel.error, LogLevel.fatal});
      expect(
        filter.matches(makeEntry('m', LogLevel.error, LogCategory.system)),
        isTrue,
      );
      expect(
        filter.matches(makeEntry('m', LogLevel.info, LogCategory.system)),
        isFalse,
      );
    });

    test('search matches message, event, screen and operation', () {
      const filter = LogFilter(searchQuery: 'supabase_init');
      final byEvent = makeEntry(
        'unrelated text',
        LogLevel.info,
        LogCategory.system,
      );
      expect(filter.matches(byEvent), isFalse);

      final withEvent = AppLogEntry.create(
        level: LogLevel.info,
        category: LogCategory.supabase,
        event: 'SUPABASE_INIT_SUCCESS',
        message: 'unrelated text',
      );
      expect(filter.matches(withEvent), isTrue);

      final byMessage = makeEntry(
        'Supabase_Init done',
        LogLevel.info,
        LogCategory.other,
      );
      expect(filter.matches(byMessage), isTrue);
    });
  });

  group('Startup interruption detection', () {
    test('incomplete startup is detected and logged', () async {
      await AppLogger.instance.recordStartup();
      expect(
        await AppLogger.instance.didPreviousSessionEndUnexpectedly(),
        isTrue,
      );

      await AppLogger.instance.logPreviousSessionCrashIfNeeded();
      final markers = AppLogger.instance.searchLogs(
        'PREVIOUS_STARTUP_INTERRUPTED',
      );
      expect(markers, isNotEmpty);
      expect(markers.last.level, LogLevel.warning);

      await AppLogger.instance.markStartupComplete();
      expect(
        await AppLogger.instance.didPreviousSessionEndUnexpectedly(),
        isFalse,
      );
    });
  });

  group('Diagnostic report', () {
    test('copy diagnostic contains full technical detail', () {
      const marker = 'report-marker-full-detail';
      AppLogger.instance.error(
        message: 'probe $marker',
        category: LogCategory.supabase,
        event: 'SUPABASE_INIT_FAILURE',
        screen: 'main',
        operation: 'supabaseInit',
        error: StateError('missing config'),
        stackTrace: StackTrace.current,
      );

      final entry = AppLogger.instance.searchLogs(marker).last;
      final report = AppLogger.instance.formatDiagnosticReport(entry);
      expect(report, contains('Event:'));
      expect(report, contains('SUPABASE_INIT_FAILURE'));
      expect(report, contains('Session ID:'));
      expect(report, contains('Error Type:'));
      expect(report, contains('Stack Trace:'));
      expect(report, contains('App Version:'));
    });
  });

  group('Logger failure isolation', () {
    test('unencodable context never throws and entry is kept', () {
      const marker = 'isolation-marker-unencodable';
      expect(
        () => AppLogger.instance.info(
          message: 'probe $marker',
          category: LogCategory.system,
          context: {'callback': () {}},
        ),
        returnsNormally,
      );
      expect(AppLogger.instance.searchLogs(marker), isNotEmpty);
    });
  });

  group('Clearing logs', () {
    test('clearLogs empties history after confirmation flow', () async {
      AppLogger.instance.info(message: 'probe clear-me-marker');
      expect(AppLogger.instance.searchLogs('clear-me-marker'), isNotEmpty);

      await AppLogger.instance.clearLogs();
      expect(AppLogger.instance.getLogs(), isEmpty);
    });
  });
}
