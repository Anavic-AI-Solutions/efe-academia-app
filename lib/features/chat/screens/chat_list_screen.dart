import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/badge_counter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
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

    return Scaffold(
      body: Column(
        children: [
          const LargeTitleBar(
            title: 'Chat',
            showBackButton: false,
          ),
          Expanded(
            child: state.isLoading && chats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && chats.isEmpty
                    ? ErrorView(
                        message: 'Failed to load chats',
                        detail: state.error,
                        onRetry: () =>
                            ref.read(chatListProvider.notifier).refresh(),
                      )
                    : chats.isEmpty
                        ? const EmptyState(
                            icon: PhosphorIconsRegular.chatCircle,
                            title: 'No conversations',
                            subtitle: 'Start a conversation with your classmates',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(chatListProvider.notifier).refresh(),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              itemCount: chats.length +
                                  (state.pagination.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index == chats.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
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
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                _formatTime(chat.lastMessageAt!),
                style: AppTypography.labelSmall.copyWith(
                  color: hasUnread
                      ? (isDark ? const Color(0xFF6366F1) : AppColors.primary)
                      : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(date);
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }
}
