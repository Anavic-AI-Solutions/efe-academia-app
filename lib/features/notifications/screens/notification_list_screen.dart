import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/notification_provider.dart';
import '../domain/notification_model.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => ref.read(notificationListProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.notifications.isEmpty
              ? ErrorView(
                  message: 'Failed to load notifications',
                  detail: state.error,
                  onRetry: () => ref.read(notificationListProvider.notifier).refresh(),
                )
              : state.notifications.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsRegular.bell,
                      title: 'No notifications',
                      subtitle: 'You\'re all caught up!',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
                      child: ListView.builder(
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) => _NotificationTile(
                          notification: state.notifications[index],
                          onTap: () {
                            ref.read(notificationListProvider.notifier).markRead(state.notifications[index].id);
                          },
                        ),
                      ),
                    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      tileColor: notification.read ? null : theme.colorScheme.primaryContainer.withOpacity(0.1),
      leading: CircleAvatar(
        backgroundColor: notification.read
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.primary,
        child: Icon(
          _getIcon(notification.type),
          color: notification.read
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'message':
        return PhosphorIconsRegular.chatCircle;
      case 'announcement':
        return PhosphorIconsRegular.megaphone;
      case 'grade':
        return PhosphorIconsRegular.graduationCap;
      case 'attendance':
        return PhosphorIconsRegular.calendarCheck;
      default:
        return PhosphorIconsRegular.bell;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}
