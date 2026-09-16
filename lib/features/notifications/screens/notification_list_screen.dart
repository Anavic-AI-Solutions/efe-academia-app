import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/notification_provider.dart';
import '../domain/notification_model.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      body: Column(
        children: [
          LargeTitleBar(
            title: 'Notifications',
            actions: [
              if (state.notifications.any((n) => !n.read))
                TextButton(
                  onPressed: () =>
                      ref.read(notificationListProvider.notifier).markAllRead(),
                  child: Text(
                    'Mark all read',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF6366F1)
                          : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: state.isLoading && state.notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.notifications.isEmpty
                    ? ErrorView(
                        message: 'Failed to load notifications',
                        detail: state.error,
                        onRetry: () => ref
                            .read(notificationListProvider.notifier)
                            .refresh(),
                      )
                    : state.notifications.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.bell,
                            title: 'No notifications',
                            subtitle: "You're all caught up!",
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(notificationListProvider.notifier)
                                .refresh(),
                            child: _buildGroupedList(context, state, ref),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
      BuildContext context, NotificationListState state, WidgetRef ref) {
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final n in state.notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inDays < 1) {
        today.add(n);
      } else if (diff.inDays < 2) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionHeader('Today', isDark),
          ...today.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref
                      .read(notificationListProvider.notifier)
                      .markRead(n.id);
                },
              )),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader('Yesterday', isDark),
          ...yesterday.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref
                      .read(notificationListProvider.notifier)
                      .markRead(n.id);
                },
              )),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionHeader('Earlier', isDark),
          ...earlier.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref
                      .read(notificationListProvider.notifier)
                      .markRead(n.id);
                },
              )),
        ],
        if (state.pagination.hasMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          letterSpacing: 0.8,
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
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = !notification.read;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: hasUnread
            ? BoxDecoration(
                color: (isDark ? const Color(0xFF6366F1) : AppColors.primary)
                    .withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                color: hasUnread
                    ? (isDark ? const Color(0xFF6366F1) : AppColors.primary)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
