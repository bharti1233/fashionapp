import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';

/// Centralized application logger with local persistence.
///
/// Records all important events, errors, and crashes to local storage
/// so they survive app restarts and can be viewed/copied by the user.
class AppLogger {
  static const String _logsKey = 'app_logs';
  static const String _startupMarkerKey = 'app_startup_marker';
  static const int _maxLogEntries = 500;

  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();

  AppLogger._();

  SharedPreferences? _prefs;
  final List<AppLogEntry> _inMemoryLogs = [];
  bool _initialized = false;

  /// Initialize the logger. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadLogsFromStorage();
      _initialized = true;
    } catch (e) {
      // Logger must never crash the app
      debugPrint('AppLogger initialization failed: $e');
    }
  }

  /// Load persisted logs from SharedPreferences
  Future<void> _loadLogsFromStorage() async {
    try {
      final logsJson = _prefs?.getString(_logsKey);
      if (logsJson != null && logsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _inMemoryLogs.clear();
        for (final item in decoded) {
          try {
            _inMemoryLogs.add(AppLogEntry.fromJson(item as Map<String, dynamic>));
          } catch (_) {
            // Skip corrupted entries
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load logs: $e');
    }
  }

  /// Persist logs to SharedPreferences
  Future<void> _persistLogs() async {
    try {
      // Keep only the most recent entries
      while (_inMemoryLogs.length > _maxLogEntries) {
        _inMemoryLogs.removeAt(0);
      }
      final encoded = jsonEncode(_inMemoryLogs.map((e) => e.toJson()).toList());
      await _prefs?.setString(_logsKey, encoded);
    } catch (e) {
      debugPrint('Failed to persist logs: $e');
    }
  }

  /// Log a debug message
  void debug({
    required String message,
    LogCategory category = LogCategory.other,
    String? screen,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: LogLevel.debug,
      category: category,
      message: message,
      screen: screen,
      operation: operation,
      context: context,
    );
  }

  /// Log an info message
  void info({
    required String message,
    LogCategory category = LogCategory.other,
    String? screen,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: LogLevel.info,
      category: category,
      message: message,
      screen: screen,
      operation: operation,
      context: context,
    );
  }

  /// Log a warning
  void warning({
    required String message,
    LogCategory category = LogCategory.other,
    String? screen,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: LogLevel.warning,
      category: category,
      message: message,
      screen: screen,
      operation: operation,
      context: context,
    );
  }

  /// Log an error
  void error({
    required String message,
    LogCategory category = LogCategory.other,
    String? screen,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: LogLevel.error,
      category: category,
      message: message,
      screen: screen,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log a fatal error
  void fatal({
    required String message,
    LogCategory category = LogCategory.other,
    String? screen,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: LogLevel.fatal,
      category: category,
      message: message,
      screen: screen,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Core logging method
  void _log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? screen,
    String? operation,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    try {
      // Redact sensitive data from context
      final safeContext = _redactSensitiveData(context);

      final entry = AppLogEntry.create(
        level: level,
        category: category,
        message: message,
        errorType: error?.runtimeType.toString(),
        stackTrace: stackTrace?.toString(),
        screen: screen,
        operation: operation,
        appVersion: _getAppVersion(),
        buildNumber: _getBuildNumber(),
        platform: _getPlatform(),
        osVersion: _getOsVersion(),
        context: safeContext,
      );

      _inMemoryLogs.add(entry);

      // Also print to console in debug mode
      if (kDebugMode) {
        debugPrint('[${level.name.toUpperCase()}] [${category.name}] $message');
        if (error != null) debugPrint('  Error: $error');
      }

      // Persist asynchronously (don't block)
      _persistLogs();
    } catch (e) {
      // Logger must never crash the app
      debugPrint('AppLogger failed to log: $e');
    }
  }

  /// Redact sensitive information from context data
  Map<String, dynamic>? _redactSensitiveData(Map<String, dynamic>? context) {
    if (context == null) return null;

    final sensitiveKeys = {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'api_key',
      'apikey',
      'secret',
      'authorization',
      'auth',
      'credential',
      'credentials',
      'otp',
      'pin',
      'credit_card',
      'card_number',
      'cvv',
    };

    final redacted = <String, dynamic>{};
    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      if (sensitiveKeys.any((sk) => key.contains(sk))) {
        redacted[entry.key] = '[REDACTED]';
      } else if (entry.value is Map<String, dynamic>) {
        redacted[entry.key] = _redactSensitiveData(entry.value as Map<String, dynamic>);
      } else {
        redacted[entry.key] = entry.value;
      }
    }
    return redacted;
  }

  /// Get all log entries
  List<AppLogEntry> getLogs({LogFilter? filter}) {
    if (filter == null) return List.unmodifiable(_inMemoryLogs);
    return _inMemoryLogs.where(filter.matches).toList();
  }

  /// Get logs filtered by level
  List<AppLogEntry> getLogsByLevel(LogLevel level) {
    return _inMemoryLogs.where((e) => e.level == level).toList();
  }

  /// Get logs filtered by category
  List<AppLogEntry> getLogsByCategory(LogCategory category) {
    return _inMemoryLogs.where((e) => e.category == category).toList();
  }

  /// Search logs by query string
  List<AppLogEntry> searchLogs(String query) {
    final q = query.toLowerCase();
    return _inMemoryLogs.where((e) {
      return e.message.toLowerCase().contains(q) ||
          (e.errorType?.toLowerCase().contains(q) ?? false) ||
          (e.stackTrace?.toLowerCase().contains(q) ?? false) ||
          (e.screen?.toLowerCase().contains(q) ?? false) ||
          (e.operation?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    try {
      await _prefs?.remove(_logsKey);
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Export all logs as formatted text
  String exportLogsAsText({LogFilter? filter}) {
    final logs = getLogs(filter: filter);
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln('FASHION APP — APPLICATION LOGS');
    buffer.writeln('==================================================');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('==================================================');
    buffer.writeln();

    for (final log in logs) {
      buffer.writeln('--- ${log.levelDisplay} | ${log.categoryDisplay} ---');
      buffer.writeln('Timestamp: ${log.formattedTimestamp}');
      if (log.screen != null) buffer.writeln('Screen: ${log.screen}');
      if (log.operation != null) buffer.writeln('Operation: ${log.operation}');
      buffer.writeln('Message: ${log.message}');
      if (log.errorType != null) buffer.writeln('Error Type: ${log.errorType}');
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace);
      }
      if (log.context != null && log.context!.isNotEmpty) {
        buffer.writeln('Context: ${jsonEncode(log.context)}');
      }
      buffer.writeln();
    }

    buffer.writeln('==================================================');
    buffer.writeln('END OF LOGS');
    buffer.writeln('==================================================');

    return buffer.toString();
  }

  /// Export logs as JSON
  String exportLogsAsJson({LogFilter? filter}) {
    final logs = getLogs(filter: filter);
    return jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEntries': logs.length,
      'logs': logs.map((e) => e.toJson()).toList(),
    });
  }

  /// Get app version string
  String _getAppVersion() {
    try {
      return '1.0.0';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get build number
  String _getBuildNumber() {
    try {
      return '1';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get platform string
  String _getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  /// Get OS version
  String _getOsVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Record startup marker for crash detection
  Future<void> recordStartup() async {
    try {
      await _prefs?.setString(_startupMarkerKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to record startup: $e');
    }
  }

  /// Mark startup as completed successfully
  Future<void> markStartupComplete() async {
    try {
      await _prefs?.setString(_startupMarkerKey, 'completed');
    } catch (e) {
      debugPrint('Failed to mark startup complete: $e');
    }
  }

  /// Check if previous session ended unexpectedly
  Future<bool> didPreviousSessionEndUnexpectedly() async {
    try {
      final marker = _prefs?.getString(_startupMarkerKey);
      if (marker == null) return false; // First launch
      if (marker == 'completed') return false; // Previous session completed
      return true; // Previous session started but didn't complete
    } catch (e) {
      return false;
    }
  }

  /// Log previous session crash if detected
  Future<void> logPreviousSessionCrashIfNeeded() async {
    if (await didPreviousSessionEndUnexpectedly()) {
      warning(
        message: 'Previous application session may have ended unexpectedly.',
        category: LogCategory.system,
        screen: 'App Startup',
        operation: 'checkPreviousSession',
      );
    }
  }

  /// Format a single log entry as a complete diagnostic report
  String formatDiagnosticReport(AppLogEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln('FASHION APP — ERROR REPORT');
    buffer.writeln('==================================================');
    buffer.writeln();
    buffer.writeln('Timestamp:');
    buffer.writeln(entry.formattedTimestamp);
    buffer.writeln();
    buffer.writeln('Level:');
    buffer.writeln(entry.levelDisplay);
    buffer.writeln();
    buffer.writeln('Category:');
    buffer.writeln(entry.categoryDisplay);
    if (entry.screen != null) {
      buffer.writeln();
      buffer.writeln('Screen:');
      buffer.writeln(entry.screen);
    }
    if (entry.operation != null) {
      buffer.writeln();
      buffer.writeln('Operation:');
      buffer.writeln(entry.operation);
    }
    buffer.writeln();
    buffer.writeln('Message:');
    buffer.writeln(entry.message);
    if (entry.errorType != null) {
      buffer.writeln();
      buffer.writeln('Error Type:');
      buffer.writeln(entry.errorType);
    }
    if (entry.stackTrace != null) {
      buffer.writeln();
      buffer.writeln('Stack Trace:');
      buffer.writeln(entry.stackTrace);
    }
    buffer.writeln();
    buffer.writeln('Application:');
    buffer.writeln('Fashion App');
    buffer.writeln();
    buffer.writeln('App Version:');
    buffer.writeln(entry.appVersion ?? 'Unknown');
    buffer.writeln();
    buffer.writeln('Build:');
    buffer.writeln(entry.buildNumber ?? 'Unknown');
    buffer.writeln();
    buffer.writeln('Platform:');
    buffer.writeln(entry.platform ?? 'Unknown');
    buffer.writeln();
    buffer.writeln('OS Version:');
    buffer.writeln(entry.osVersion ?? 'Unknown');
    buffer.writeln();
    buffer.writeln('Flutter Version:');
    buffer.writeln(_getFlutterVersion());
    buffer.writeln();
    buffer.writeln('Environment:');
    buffer.writeln(kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug');
    buffer.writeln();
    buffer.writeln('==================================================');
    buffer.writeln('END ERROR REPORT');
    buffer.writeln('==================================================');
    return buffer.toString();
  }

  /// Get Flutter version
  String _getFlutterVersion() {
    try {
      return '3.38.4';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get in-memory log count
  int get logCount => _inMemoryLogs.length;

  /// Get all logs (unmodifiable)
  List<AppLogEntry> get allLogs => List.unmodifiable(_inMemoryLogs);
}
