import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';

/// Full error dialog shown when a serious error occurs.
/// Provides COPY LOG and CLOSE buttons.
class ErrorDialog extends StatelessWidget {
  final AppLogEntry entry;
  final VoidCallback? onClose;

  const ErrorDialog({super.key, required this.entry, this.onClose});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _TechnicalDetailsSection(entry: entry),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copyLog(context),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('COPY LOG'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('CLOSE'),
        ),
      ],
    );
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

/// Expandable technical details section
class _TechnicalDetailsSection extends StatefulWidget {
  final AppLogEntry entry;

  const _TechnicalDetailsSection({required this.entry});

  @override
  State<_TechnicalDetailsSection> createState() =>
      _TechnicalDetailsSectionState();
}

class _TechnicalDetailsSectionState extends State<_TechnicalDetailsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Show technical details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _buildDetailRow('Error Type', widget.entry.errorType),
          _buildDetailRow('Screen', widget.entry.screen),
          _buildDetailRow('Operation', widget.entry.operation),
          _buildDetailRow('Timestamp', widget.entry.formattedTimestamp),
          _buildDetailRow('App Version', widget.entry.appVersion),
          _buildDetailRow('Build', widget.entry.buildNumber),
          _buildDetailRow('Platform', widget.entry.platform),
          _buildDetailRow('OS Version', widget.entry.osVersion),
          if (widget.entry.stackTrace != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Stack Trace:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                widget.entry.stackTrace!,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}

/// Show error dialog helper
void showErrorDialog(BuildContext context, AppLogEntry entry) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ErrorDialog(entry: entry),
  );
}
