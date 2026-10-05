import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/badge_counter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/chat_provider.dart';
import '../domain/chat_model.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
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
      ref.read(chatListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);
    final chats = state.chats;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.navChat,
            showBackButton: false,
            actions: [
              IconButton(
                onPressed: () => context.push('/chat/new'),
                tooltip: l10n.chatNewTitle,
                icon: const Icon(
                  PhosphorIconsRegular.plus,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Expanded(
            child: state.isLoading && chats.isEmpty
                ? const ListShimmer()
                : state.error != null && chats.isEmpty
                    ? ErrorView(
                        message: l10n.chatLoadError,
                        detail: state.error,
                        onRetry: () =>
                            ref.read(chatListProvider.notifier).refresh(),
                      )
                    : chats.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.chatCircle,
                            title: l10n.chatEmptyTitle,
                            subtitle: l10n.chatEmptySubtitle,
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(chatListProvider.notifier).refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: chats.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == chats.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(top: 4, bottom: 12),
                                    child: LoadingShimmer(
                                      width: double.infinity,
                                      height: 68,
                                    ),
                                  );
                                }
                                return _ChatTile(
                                  chat: chats[index],
                                  onTap: () => context.push(
                                    '/chat/${chats[index].id}?name=${Uri.encodeComponent(chats[index].name)}',
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onTap;

  const _ChatTile({required this.chat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          BadgeCounter(
            count: chat.unreadCount,
            child: AppAvatar(
              name: chat.name,
              size: 48,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: hasUnread
                        ? (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                    fontWeight:
                        hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (chat.lastMessageAt != null)
            Text(
              _formatTime(l10n, chat.lastMessageAt!),
              style: AppTypography.labelSmall.copyWith(
                color: hasUnread
                    ? AppColors.accentFor(isDark)
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.chatTimeNow;
    if (diff.inHours < 1) return l10n.chatTimeMinutesShort(diff.inMinutes);
    if (diff.inDays < 1) return DateFormat('HH:mm').format(date);
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }
}
