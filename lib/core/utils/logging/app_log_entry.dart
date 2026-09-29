import 'package:intl/intl.dart';

/// Log levels in order of severity
enum LogLevel { debug, info, warning, error, fatal }

/// Extension to provide color for log levels
extension LogLevelColor on LogLevel {
  int get levelColor {
    switch (this) {
      case LogLevel.debug:
        return 0xFF757575; // Grey
      case LogLevel.info:
        return 0xFF2196F3; // Blue
      case LogLevel.warning:
        return 0xFFFF9800; // Orange
      case LogLevel.error:
        return 0xFFF44336; // Red
      case LogLevel.fatal:
        return 0xFFB71C1C; // Dark Red
    }
  }
}

/// Categories for log entries
enum LogCategory {
  startup,
  supabase,
  authentication,
  database,
  storage,
  network,
  ui,
  navigation,
  products,
  cart,
  wishlist,
  orders,
  profile,
  system,
  other,
}

/// Represents a single log entry in the application
class AppLogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? errorType;
  final String? stackTrace;
  final String? screen;
  final String? operation;
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? osVersion;
  final Map<String, dynamic>? context;

  AppLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.errorType,
    this.stackTrace,
    this.screen,
    this.operation,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.context,
  });

  /// Create a log entry with automatic ID and timestamp
  factory AppLogEntry.create({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? errorType,
    String? stackTrace,
    String? screen,
    String? operation,
    String? appVersion,
    String? buildNumber,
    String? platform,
    String? osVersion,
    Map<String, dynamic>? context,
  }) {
    return AppLogEntry(
      id: _generateId(),
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      errorType: errorType,
      stackTrace: stackTrace,
      screen: screen,
      operation: operation,
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      osVersion: osVersion,
      context: context,
    );
  }

  static String _generateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return '${timestamp}_$random';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'category': category.name,
      'message': message,
      'errorType': errorType,
      'stackTrace': stackTrace,
      'screen': screen,
      'operation': operation,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
      'osVersion': osVersion,
      'context': context,
    };
  }

  /// Create from JSON
  factory AppLogEntry.fromJson(Map<String, dynamic> json) {
    return AppLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere((e) => e.name == json['level']),
      category: LogCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      message: json['message'] as String,
      errorType: json['errorType'] as String?,
      stackTrace: json['stackTrace'] as String?,
      screen: json['screen'] as String?,
      operation: json['operation'] as String?,
      appVersion: json['appVersion'] as String?,
      buildNumber: json['buildNumber'] as String?,
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  /// Get level as string for display
  String get levelDisplay => level.name.toUpperCase();

  /// Get category display name
  String get categoryDisplay => category.name.toUpperCase();

  /// Get formatted timestamp for display
  String get formattedTimestamp {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(timestamp);
  }

  /// Get short timestamp for list view
  String get shortTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return DateFormat('MMM d').format(timestamp);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get color for level (for UI)
  int get levelColor {
    switch (level) {
      case LogLevel.debug:
        return 0xFF757575; // Grey
      case LogLevel.info:
        return 0xFF2196F3; // Blue
      case LogLevel.warning:
        return 0xFFFF9800; // Orange
      case LogLevel.error:
        return 0xFFF44336; // Red
      case LogLevel.fatal:
        return 0xFFB71C1C; // Dark Red
    }
  }

  /// Create a copy with updated fields
  AppLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    LogLevel? level,
    LogCategory? category,
    String? message,
    String? errorType,
    String? stackTrace,
    String? screen,
    String? operation,
    String? appVersion,
    String? buildNumber,
    String? platform,
    String? osVersion,
    Map<String, dynamic>? context,
  }) {
    return AppLogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      category: category ?? this.category,
      message: message ?? this.message,
      errorType: errorType ?? this.errorType,
      stackTrace: stackTrace ?? this.stackTrace,
      screen: screen ?? this.screen,
      operation: operation ?? this.operation,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      context: context ?? this.context,
    );
  }

  @override
  String toString() {
    return 'AppLogEntry(id: $id, level: ${level.name}, category: ${category.name}, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for log level filtering
class LogFilter {
  final Set<LogLevel> levels;
  final Set<LogCategory> categories;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const LogFilter({
    this.levels = const {},
    this.categories = const {},
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  bool matches(AppLogEntry entry) {
    if (levels.isNotEmpty && !levels.contains(entry.level)) return false;
    if (categories.isNotEmpty && !categories.contains(entry.category)) {
      return false;
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!entry.message.toLowerCase().contains(query) &&
          (entry.errorType?.toLowerCase().contains(query) ?? false) &&
          (entry.stackTrace?.toLowerCase().contains(query) ?? false) &&
          (entry.screen?.toLowerCase().contains(query) ?? false) &&
          (entry.operation?.toLowerCase().contains(query) ?? false) &&
          (entry.errorType?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }
    if (startDate != null && entry.timestamp.isBefore(startDate!)) return false;
    if (endDate != null && entry.timestamp.isAfter(endDate!)) return false;
    return true;
  }

  LogFilter copyWith({
    Set<LogLevel>? levels,
    Set<LogCategory>? categories,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LogFilter(
      levels: levels ?? this.levels,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
