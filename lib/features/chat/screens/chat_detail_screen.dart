import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';
import '../domain/message_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/realtime/realtime_providers.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? chatName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    this.chatName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _didInitialJump = false;

  VoidCallback? _cancelChatSubscription;
  VoidCallback? _removeReconnectListener;
  Timer? _typingThrottle;

  @override
  void initState() {
    super.initState();
    _didInitialJump = false;
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onComposerChanged);
    _markRead();
    _subscribeRealtime();
  }

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _didInitialJump = false;
    }
  }

  @override
  void dispose() {
    _typingThrottle?.cancel();
    _controller.removeListener(_onComposerChanged);
    _cancelChatSubscription?.call();
    _removeReconnectListener?.call();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Marca el chat como leído para que el badge baja al abrirlo. El
  /// controlador captura sus propios errores; si el POST falla, el badge
  /// conserva su valor y el próximo refresh lo reconcilia.
  void _markRead() {
    unawaited(
      ref.read(chatUnreadCountControllerProvider).markRead(widget.chatId),
    );
  }

  /// Suscribe el canal del chat y el resync de reconexión. Sin realtime
  /// configurado la pantalla sigue funcionando por REST.
  void _subscribeRealtime() {
    try {
      final service = ref.read(realtimeServiceProvider);
      final notifier = ref.read(messagesProvider(widget.chatId).notifier);
      _cancelChatSubscription = service
          .watchChat(
            chatId: widget.chatId,
            onMessage: notifier.appendIncoming,
            // El backend reenvía el recibo al lector; ignorar los propios
            // evita pintar ✓✓ en mensajes que el otro usuario no leyó (B4).
            onRead: (event) => notifier.applyReadReceipt(
              event,
              currentUserId: ref.read(authProvider).user?.id,
            ),
            onTyping: notifier.setTyping,
          )
          .cancel;
      _removeReconnectListener = service.addReconnectListener(() {
        notifier.backfill();
      });
    } catch (e) {
      debugPrint('[Chat:${widget.chatId}] realtime no disponible: $e');
    }
  }

  /// Anuncia `typing: true` como máximo una vez cada 2 s mientras se escribe.
  void _onComposerChanged() {
    if (_controller.text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (_typingThrottle?.isActive ?? false) return;
    _typingThrottle?.cancel();
    _typingThrottle = Timer(const Duration(seconds: 2), () {});
    _sendTyping(true);
  }

  void _stopTyping() {
    final wasAnnounced = _typingThrottle != null;
    _typingThrottle?.cancel();
    _typingThrottle = null;
    if (wasAnnounced) _sendTyping(false);
  }

  void _sendTyping(bool typing) {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      ref.read(realtimeServiceProvider).sendTyping(
            chatId: widget.chatId,
            typing: typing,
            userId: userId,
          );
    } catch (e) {
      debugPrint('[Chat:${widget.chatId}] typing no disponible: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 200) _loadOlder();
  }

  /// Carga la página anterior preservando la posición visual: mide el extent
  /// antes y después y desplaza el offset en el delta ganado por arriba.
  Future<void> _loadOlder() async {
    if (!_scrollController.hasClients) return;
    final notifier = ref.read(messagesProvider(widget.chatId).notifier);
    final beforeExtent = _scrollController.position.maxScrollExtent;
    final beforeCount =
        ref.read(messagesProvider(widget.chatId)).messages.length;
    await notifier.loadMore();
    if (!mounted || !_scrollController.hasClients) return;
    final afterCount =
        ref.read(messagesProvider(widget.chatId)).messages.length;
    if (afterCount == beforeCount) return;
    final delta = _scrollController.position.maxScrollExtent - beforeExtent;
    if (delta <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.pixels + delta);
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _stopTyping();
    ref.read(messagesProvider(widget.chatId).notifier).send(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider(widget.chatId));
    final currentUserId = ref.watch(authProvider).user?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = state.messages;
    final l10n = context.l10n;

    // Apertura al último mensaje: salto instantáneo una sola vez cuando la
    // primera página ya está pintada.
    if (!state.isLoading && messages.isNotEmpty && !_didInitialJump) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _didInitialJump = true;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: widget.chatName ?? l10n.navChat,
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: state.isLoading && messages.isEmpty
                ? const ListShimmer()
                : state.error != null && messages.isEmpty
                    ? Center(
                        child: Text(
                          l10n.chatMessagesLoadError,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : messages.isEmpty
                        ? Center(
                            child: Text(
                              l10n.chatMessagesEmpty,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length +
                                (state.pagination.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (state.pagination.hasMore && index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 4, bottom: 12),
                                  child: LoadingShimmer(
                                    width: double.infinity,
                                    height: 68,
                                  ),
                                );
                              }
                              final message = state.pagination.hasMore
                                  ? messages[index - 1]
                                  : messages[index];
                              final isMe = message.senderId == currentUserId ||
                                  state.isOwn(message.id);
                              return _MessageBubble(
                                message: message,
                                isMe: isMe,
                                status: state.statusOf(message.id),
                                isRead: state.isRead(message.id),
                                onRetry: () => ref
                                    .read(messagesProvider(widget.chatId)
                                        .notifier)
                                    .retrySend(message.id),
                              );
                            },
                          ),
          ),
          _buildTypingRow(state, theme, l10n),
          _buildInputBar(theme, l10n),
        ],
      ),
    );
  }

  /// Fila "escribiendo…" sobre la barra de input, con aparición animada.
  Widget _buildTypingRow(
    MessagesState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: state.typingUserId == null
          ? const SizedBox.shrink()
          : Align(
              key: const Key('chatTyping'),
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  l10n.chatTyping,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l10n.chatInputHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(PhosphorIconsFill.paperPlaneRight, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final MessageStatus status;
  final bool isRead;
  final VoidCallback onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.status,
    required this.isRead,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.body,
                style: TextStyle(
                  color: isMe
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (isMe && status == MessageStatus.failed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.chatSendFailed,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 10,
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(context.l10n.chatRetry),
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead
                          ? PhosphorIconsFill.checks
                          : PhosphorIconsFill.check,
                      size: 12,
                      color: isRead
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
