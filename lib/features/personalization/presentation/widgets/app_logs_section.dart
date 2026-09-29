import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logs_screen.dart';

class AppLogsSection extends StatelessWidget {
  const AppLogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Iconsax.document_text, color: Colors.blue),
          title: const Text('App Logs'),
          subtitle: const Text('View Application Error Logs'),
          trailing: const Icon(Iconsax.arrow_right_3, size: 18),
          onTap: () {
            AppLogger.instance.info(
              message: 'User opened App Logs',
              category: LogCategory.system,
              screen: 'Settings',
              operation: 'openAppLogs',
            );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AppLogsScreen()),
            );
          },
        ),
      ],
    );
  }
}
