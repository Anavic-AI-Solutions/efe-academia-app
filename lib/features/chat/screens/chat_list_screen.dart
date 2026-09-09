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
import '../providers/chat_provider.dart';
import '../domain/chat_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: state.isLoading && state.chats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.chats.isEmpty
              ? ErrorView(
                  message: 'Failed to load chats',
                  detail: state.error,
                  onRetry: () => ref.read(chatListProvider.notifier).refresh(),
                )
              : state.chats.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsRegular.chatCircle,
                      title: 'No conversations',
                      subtitle: 'Start a conversation with your classmates',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
                      child: ListView.builder(
                        itemCount: state.chats.length,
                        itemBuilder: (context, index) => _ChatTile(
                          chat: state.chats[index],
                          onTap: () => context.push('/chat/${state.chats[index].id}'),
                        ),
                      ),
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

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          BadgeCounter(
            count: chat.unreadCount,
            child: AppAvatar(
              name: chat.name,
              size: 48,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chat.unreadCount > 0
                        ? theme.textTheme.bodySmall?.color
                        : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (chat.lastMessageAt != null)
            Text(
              _formatTime(chat.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: chat.unreadCount > 0
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
        ],
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
