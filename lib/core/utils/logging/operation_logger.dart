import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// Runs a Supabase-backed [action] with START/SUCCESS/FAILURE lifecycle
/// logging through the single shared [AppLogger].
///
/// - START and SUCCESS are logged at DEBUG level. Only the operation name
///   is recorded — NEVER arguments (they may contain passwords, tokens,
///   or other credentials).
/// - FAILURE is logged at ERROR level with the exception type and stack
///   trace, then the exception is rethrown so repository/cubit layers can
///   attach their own context and user-facing handling.
///
/// Every layer uses this same [AppLogger]: local-first, persisted,
/// published on the live stream, and visible in App Logs history.
Future<T> logSupabaseOperation<T>({
  required LogCategory category,
  required String operation,
  String? screen,
  String? startEvent,
  String? successEvent,
  String? failureEvent,
  required Future<T> Function() action,
}) async {
  AppLogger.instance.debug(
    message: '$operation started',
    category: category,
    event: startEvent ?? '${operation}_START',
    screen: screen,
    operation: operation,
  );
  try {
    final result = await action();
    AppLogger.instance.debug(
      message: '$operation succeeded',
      category: category,
      event: successEvent ?? '${operation}_SUCCESS',
      screen: screen,
      operation: operation,
    );
    return result;
  } catch (e, stackTrace) {
    AppLogger.instance.error(
      message: '$operation failed',
      category: category,
      event: failureEvent ?? '${operation}_FAILURE',
      screen: screen,
      operation: operation,
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
