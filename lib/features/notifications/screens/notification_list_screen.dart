import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/notification_provider.dart';
import '../domain/notification_model.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.profileNotifications,
            actions: [
              if (state.notifications.any((n) => !n.read))
                TextButton(
                  onPressed: () =>
                      ref.read(notificationListProvider.notifier).markAllRead(),
                  child: Text(
                    l10n.notificationsMarkAllRead,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accentFor(isDark),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: state.isLoading && state.notifications.isEmpty
                ? const ListShimmer()
                : state.error != null && state.notifications.isEmpty
                    ? ErrorView(
                        message: l10n.notificationsLoadError,
                        detail: state.error,
                        onRetry: () => ref
                            .read(notificationListProvider.notifier)
                            .refresh(),
                      )
                    : state.notifications.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.bell,
                            title: l10n.notificationsEmptyTitle,
                            subtitle: l10n.notificationsEmptySubtitle,
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
    final l10n = context.l10n;
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionHeader(l10n.notificationsToday, isDark),
          ...today.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref.read(notificationListProvider.notifier).markRead(n.id);
                },
              )),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader(l10n.notificationsYesterday, isDark),
          ...yesterday.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref.read(notificationListProvider.notifier).markRead(n.id);
                },
              )),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionHeader(l10n.notificationsEarlier, isDark),
          ...earlier.map((n) => _NotificationTile(
                notification: n,
                onTap: () {
                  ref.read(notificationListProvider.notifier).markRead(n.id);
                },
              )),
        ],
        if (state.pagination.hasMore)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: LoadingShimmer(
              width: double.infinity,
              height: 68,
            ),
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
          color: AppColors.mutedFor(isDark),
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
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = !notification.read;
    final accent = AppColors.accentFor(isDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      color: hasUnread ? accent.withOpacity(0.06) : null,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: hasUnread ? accent : Colors.transparent,
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(l10n, notification.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat('MMM d').format(date);
  }
}
