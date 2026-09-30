import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:t_store/core/common/view_models/app_bar_view_model.dart';
import 'package:t_store/core/common/widgets/app_bar.dart';
import 'package:t_store/core/utils/constants/sizes.dart';
import 'package:t_store/core/utils/logging/app_log_entry.dart';
import 'package:t_store/core/utils/logging/app_logger.dart';
import 'package:t_store/features/notifications/domain/entities/notification_entity.dart';
import 'package:t_store/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:t_store/features/notifications/presentation/cubit/notifications_state.dart';

/// Real notification inbox backed by Supabase through
/// [NotificationsCubit]. Read/unread state, mark-as-read and delete all
/// act on the backend. Honest empty/error states, never fabricated rows.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    AppLogger.instance.info(
      message: 'Notifications loading started',
      category: LogCategory.notifications,
      event: 'NOTIFICATIONS_LOAD_START',
      screen: 'NotificationsView',
      operation: 'loadNotifications',
    );
    context.read<NotificationsCubit>().getNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarModel: AppBarModel(
          hasArrowBack: true,
          title: Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return _NotificationsMessage(
              icon: Iconsax.notification,
              message: state.message,
              actionLabel: 'RETRY',
              onAction: _load,
            );
          }
          final notifications = state is NotificationsLoaded
              ? state.notifications
              : const <NotificationEntity>[];
          if (notifications.isEmpty) {
            return const _NotificationsMessage(
              icon: Iconsax.notification,
              message: 'No notifications yet.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<NotificationsCubit>()
                .getNotifications(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final date = notification.createdAt != null
        ? DateFormat('dd MMM, yyyy').format(notification.createdAt!)
        : '';
    return Card(
      color: notification.isRead
          ? null
          : Theme.of(context).primaryColor.withValues(alpha: 0.08),
      child: ListTile(
        leading: Icon(
          Iconsax.notification,
          color: notification.isRead ? Colors.grey : null,
        ),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            if (date.isNotEmpty)
              Text(date, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        trailing: notification.isRead
            ? null
            : TextButton(
                onPressed: () => context.read<NotificationsCubit>().markAsRead(
                  notification.id,
                ),
                child: const Text('Mark read'),
              ),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationsCubit>().markAsRead(notification.id);
          }
        },
      ),
    );
  }
}

class _NotificationsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NotificationsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
