import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// App Logs screen accessible from Settings.
/// Shows persistent log history with search, filter, copy, and clear.
class AppLogsScreen extends StatefulWidget {
  const AppLogsScreen({super.key});

  @override
  State<AppLogsScreen> createState() => _AppLogsScreenState();
}

class _AppLogsScreenState extends State<AppLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  LogFilter _filter = const LogFilter();
  List<AppLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    setState(() {
      _logs = AppLogger.instance.getLogs(filter: _filter);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filter = _filter.copyWith(searchQuery: query.isEmpty ? null : query);
      _logs = AppLogger.instance.getLogs(filter: _filter);
    });
  }

  void _onLevelFilterChanged(Set<LogLevel> levels) {
    setState(() {
      _filter = _filter.copyWith(levels: levels);
      _logs = AppLogger.instance.getLogs(filter: _filter);
    });
  }

  void _onCategoryFilterChanged(Set<LogCategory> categories) {
    setState(() {
      _filter = _filter.copyWith(categories: categories);
      _logs = AppLogger.instance.getLogs(filter: _filter);
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text(
          'Are you sure you want to clear all application logs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppLogger.instance.clearLogs();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logs cleared.')));
      }
    }
  }

  void _copyLog(AppLogEntry entry) {
    final report = AppLogger.instance.formatDiagnosticReport(entry);
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error log copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewLogDetail(AppLogEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LogDetailScreen(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildLevelFilterChips(),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChips(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Log list
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _LogListTile(
                        entry: log,
                        onTap: () => _viewLogDetail(log),
                        onCopy: () => _copyLog(log),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilterChips() {
    final levels = _filter.levels;
    return Wrap(
      spacing: 8,
      children: LogLevel.values.map((level) {
        final isSelected = levels.contains(level);
        return FilterChip(
          label: Text(level.name.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            final current = Set<LogLevel>.from(levels);
            if (selected) {
              current.add(level);
            } else {
              current.remove(level);
            }
            _onLevelFilterChanged(current);
          },
          selectedColor: Color(level.levelColor).withValues(alpha: 0.3),
          checkmarkColor: Color(level.levelColor),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryFilterChips() {
    final categories = _filter.categories;
    return Wrap(
      spacing: 8,
      children: LogCategory.values.map((category) {
        final isSelected = categories.contains(category);
        return FilterChip(
          label: Text(category.name.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            final current = Set<LogCategory>.from(categories);
            if (selected) {
              current.add(category);
            } else {
              current.remove(category);
            }
            _onCategoryFilterChanged(current);
          },
        );
      }).toList(),
    );
  }
}

/// Single log entry tile in the list
class _LogListTile extends StatelessWidget {
  final AppLogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _LogListTile({
    required this.entry,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(entry.levelColor).withValues(alpha: 0.2),
        child: Icon(
          _getIconForLevel(entry.level),
          color: Color(entry.levelColor),
          size: 20,
        ),
      ),
      title: Text(
        entry.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${entry.categoryDisplay} • ${entry.shortTimestamp}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: IconButton(
        onPressed: onCopy,
        icon: const Icon(Icons.copy, size: 20),
        tooltip: 'Copy Log',
      ),
      onTap: onTap,
    );
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.fatal:
        return Icons.dangerous;
    }
  }
}

/// Log detail screen with full diagnostic information
class LogDetailScreen extends StatelessWidget {
  final AppLogEntry entry;

  const LogDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Detail'),
        actions: [
          IconButton(
            onPressed: () => _copyLog(context),
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDetailSection('Message', entry.message),
            if (entry.errorType != null)
              _buildDetailSection('Error Type', entry.errorType!),
            if (entry.stackTrace != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Stack Trace',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  entry.stackTrace!,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (entry.context != null && entry.context!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Context',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  entry.context.toString(),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildMetadataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(entry.levelColor).withValues(alpha: 0.2),
          child: Icon(
            _getIconForLevel(entry.level),
            color: Color(entry.levelColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.levelDisplay,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(entry.levelColor),
                  fontSize: 16,
                ),
              ),
              Text(
                entry.categoryDisplay,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metadata',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetadataRow('Timestamp', entry.formattedTimestamp),
        _buildMetadataRow('App Version', entry.appVersion),
        _buildMetadataRow('Build', entry.buildNumber),
        _buildMetadataRow('Platform', entry.platform),
        _buildMetadataRow('OS Version', entry.osVersion),
        _buildMetadataRow('Screen', entry.screen),
        _buildMetadataRow('Operation', entry.operation),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.fatal:
        return Icons.dangerous;
    }
  }

  void _copyLog(BuildContext context) {
    final report = AppLogger.instance.formatDiagnosticReport(entry);
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error log copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
