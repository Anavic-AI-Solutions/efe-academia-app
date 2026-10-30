import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/chat_api.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';
import '../domain/message_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(chatApiProvider));
});

// ---------------------------------------------------------------------------
// Chat List State
// ---------------------------------------------------------------------------

class ChatListState {
  final CursorPagination<ChatModel> pagination;
  final bool isLoading;
  final String? error;

  ChatListState({
    CursorPagination<ChatModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<ChatModel>.empty();

  List<ChatModel> get chats => pagination.data;

  ChatListState copyWith({
    CursorPagination<ChatModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat List Notifier
// ---------------------------------------------------------------------------

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ChatRepository _repository;

  ChatListNotifier(this._repository) : super(ChatListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getChats();
      print('[Chat] Loaded ${result.data.length} conversations');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      print('[Chat] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getChats();
      print('[Chat] Refreshed ${result.data.length} conversations');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      print('[Chat] refresh ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresca la primera página sin activar el estado de carga, para que los
  /// refrescos disparados por realtime no hagan parpadear la lista visible.
  Future<void> refreshFirstPage() async {
    try {
      final result = await _repository.getChats();
      state = state.copyWith(pagination: result, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pone en cero el contador local de un chat al abrirlo. El backend ya lo
  /// marcó como leído; así la lista no muestra el badge viejo al volver.
  void clearUnread(String chatId) {
    state = state.copyWith(
      pagination: state.pagination.copyWith(
        data: state.chats
            .map((chat) =>
                chat.id == chatId ? chat.copyWith(unreadCount: 0) : chat)
            .toList(),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getChats(
        cursor: state.pagination.nextCursor,
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      print('[Chat] loadMore ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref.watch(chatRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Unread Count
// ---------------------------------------------------------------------------

/// Contador global de mensajes sin leer (badge de la nav).
final chatUnreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(chatApiProvider).getUnreadCount();
});

/// Acciones sobre el contador: abrir un chat y refrescarlo a mano.
class ChatUnreadCountController {
  ChatUnreadCountController(this._ref);

  final Ref _ref;

  /// Marca el chat como leído y, solo si el POST tuvo éxito, limpia el badge
  /// por chat y lo invalida para que se relea el contador global.
  Future<void> markRead(String chatId) async {
    try {
      await _ref.read(chatApiProvider).markRead(chatId);
    } catch (_) {
      // El badge conserva su valor; el próximo refresh lo reconcilia.
      return;
    }
    // Solo actualiza la lista si ya está montada; no fuerza una carga extra
    // cuando se abre un chat desde un enlace directo.
    if (_ref.container.exists(chatListProvider)) {
      _ref.read(chatListProvider.notifier).clearUnread(chatId);
    }
    _ref.invalidate(chatUnreadCountProvider);
  }

  /// Fuerza la relectura del contador sin depender del WebSocket.
  void refresh() => _ref.invalidate(chatUnreadCountProvider);
}

final chatUnreadCountControllerProvider = Provider<ChatUnreadCountController>(
    (ref) => ChatUnreadCountController(ref));

// ---------------------------------------------------------------------------
// Messages State
// ---------------------------------------------------------------------------

/// Estado de entrega de una burbuja local.
enum MessageStatus { sending, sent, failed }

/// Distingue "no provisto" de "null" en los campos anulables de
/// [MessagesState.copyWith].
const Object _unset = Object();

/// Orden ascendente por `id` numérico; los envíos locales (id temporal) van al
/// final, ordenados por fecha.
int _compareMessages(MessageModel a, MessageModel b) {
  final aId = int.tryParse(a.id);
  final bId = int.tryParse(b.id);
  if (aId != null && bId != null) return aId.compareTo(bId);
  if (aId != null) return -1;
  if (bId != null) return 1;
  return a.createdAt.compareTo(b.createdAt);
}

class MessagesState {
  final CursorPagination<MessageModel> pagination;
  final bool isLoading;
  final String? error;

  /// Estado de entrega por id de mensaje. Los mensajes sin entrada se
  /// consideran [MessageStatus.sent]: los que llegan del servidor ya lo están.
  final Map<String, MessageStatus> statuses;

  /// Usuario que está escribiendo, si el último whisper de typing sigue vivo.
  final String? typingUserId;

  /// Mayor id leído por el otro participante (read receipt).
  final int? lastReadMessageId;

  MessagesState({
    CursorPagination<MessageModel>? pagination,
    this.isLoading = false,
    this.error,
    Map<String, MessageStatus>? statuses,
    this.typingUserId,
    this.lastReadMessageId,
  })  : pagination = pagination ?? CursorPagination<MessageModel>.empty(),
        statuses = statuses ?? const {};

  List<MessageModel> get messages => pagination.data;
  bool get hasMore => pagination.hasMore;

  MessageStatus statusOf(String messageId) =>
      statuses[messageId] ?? MessageStatus.sent;

  /// `true` mientras la burbuja corresponde a un envío local de este cliente
  /// (optimista), incluso después de confirmarse.
  bool isOwn(String messageId) => statuses.containsKey(messageId);

  /// `true` si el mensaje fue leído por el otro participante.
  bool isRead(String messageId) {
    final last = lastReadMessageId;
    final id = int.tryParse(messageId);
    return last != null && id != null && id <= last;
  }

  MessagesState copyWith({
    CursorPagination<MessageModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, MessageStatus>? statuses,
    Object? typingUserId = _unset,
    Object? lastReadMessageId = _unset,
  }) {
    return MessagesState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statuses: statuses ?? this.statuses,
      typingUserId: identical(typingUserId, _unset)
          ? this.typingUserId
          : typingUserId as String?,
      lastReadMessageId: identical(lastReadMessageId, _unset)
          ? this.lastReadMessageId
          : lastReadMessageId as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// Messages Notifier
// ---------------------------------------------------------------------------

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository _repository;
  final String chatId;

  /// Cuánto sobrevive el indicador "escribiendo…" sin un whisper nuevo.
  final Duration typingTimeout;

  Timer? _typingTimer;

  MessagesNotifier(
    this._repository,
    this.chatId, {
    this.typingTimeout = const Duration(seconds: 3),
  }) : super(MessagesState()) {
    load();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMessages(chatId, direction: 'older');
      print('[Chat:$chatId] Loaded ${result.data.length} messages');
      state = state.copyWith(
        pagination: result.copyWith(data: _sorted(result.data)),
        isLoading: false,
      );
    } catch (e) {
      print('[Chat:$chatId] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMessages(chatId, direction: 'older');
      print('[Chat:$chatId] Refreshed ${result.data.length} messages');
      state = state.copyWith(
        pagination: result.copyWith(data: _sorted(result.data)),
        isLoading: false,
      );
    } catch (e) {
      print('[Chat:$chatId] refresh ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getMessages(
        chatId,
        cursor: state.pagination.nextCursor,
        direction: 'older',
      );
      // La página pedida puede solaparse con mensajes que llegaron en vivo:
      // se fusiona por id para no duplicar.
      state = state.copyWith(
        pagination: result.copyWith(
          data: _mergeMessages(state.messages, result.data),
        ),
        isLoading: false,
      );
    } catch (e) {
      print('[Chat:$chatId] loadMore ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fusiona un mensaje recibido por el canal en vivo: descarta duplicados por
  /// id (el emisor también recibe su propio broadcast) y reordena.
  Future<void> appendIncoming(Map<String, dynamic> event) async {
    final message = MessageModel.fromJson(event);
    if (message.id.isEmpty) return;
    _merge(message);
  }

  /// Marca como leídos los mensajes propios con id <= `last_read_message_id`.
  /// Los recibos viejos se ignoran para no retroceder el marcador y los
  /// propios se descartan: el backend reenvía el evento al lector (spec B4).
  void applyReadReceipt(Map<String, dynamic> event, {String? currentUserId}) {
    final readerId = event['user_id'] ?? event['userId'];
    if (currentUserId != null &&
        readerId != null &&
        readerId.toString() == currentUserId) {
      return;
    }
    final raw = event['last_read_message_id'] ?? event['lastReadMessageId'];
    final value = raw is int ? raw : int.tryParse('$raw');
    if (value == null) return;
    final current = state.lastReadMessageId;
    if (current != null && current >= value) return;
    state = state.copyWith(lastReadMessageId: value);
  }

  /// Indicador transitorio: un whisper `typing: true` expira solo tras
  /// [typingTimeout]; un `typing: false` del mismo usuario lo limpia al
  /// instante. Un `false` de otro usuario no apaga el indicador ajeno.
  void setTyping(Map<String, dynamic> event) {
    final userId = event['user_id']?.toString();
    if (event['typing'] == false) {
      if (userId == null || userId.isEmpty || userId == state.typingUserId) {
        _clearTyping();
      }
      return;
    }
    if (userId == null || userId.isEmpty) return;
    _typingTimer?.cancel();
    _typingTimer = Timer(typingTimeout, _clearTyping);
    state = state.copyWith(typingUserId: userId);
  }

  /// Refresca lo perdido durante una desconexión: pide los mensajes posteriores
  /// al último id visible y los fusiona; la deduplicación hace el resto.
  Future<void> backfill() async {
    String? cursor;
    for (final message in state.messages.reversed) {
      if (int.tryParse(message.id) != null) {
        // El backend espera el id crudo codificado en base64.
        cursor = base64Encode(utf8.encode(message.id));
        break;
      }
    }
    if (cursor == null) {
      await load();
      return;
    }
    try {
      final result = await _repository.getMessages(chatId, cursor: cursor);
      for (final message in result.data) {
        _merge(message);
      }
    } catch (e) {
      debugPrint('[Chat:$chatId] backfill ERROR: $e');
    }
  }

  /// Envía [body] con burbuja optimista: `sending` → `sent` | `failed`.
  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = MessageModel(
      id: tempId,
      body: text,
      senderId: '',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      pagination: state.pagination.copyWith(
        data: _sorted([...state.messages, optimistic]),
      ),
      statuses: {...state.statuses, tempId: MessageStatus.sending},
      clearError: true,
    );
    await _deliver(tempId, text);
  }

  /// Reintenta un envío fallido conservando la burbuja (mismo id temporal).
  Future<void> retrySend(String tempId) async {
    String? body;
    for (final message in state.messages) {
      if (message.id == tempId) {
        body = message.body;
        break;
      }
    }
    if (body == null) return;
    state = state.copyWith(
      statuses: {...state.statuses, tempId: MessageStatus.sending},
    );
    await _deliver(tempId, body);
  }

  void _merge(MessageModel message) {
    if (message.id.isEmpty) return;
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(
        data: _mergeMessages(state.messages, [message]),
      ),
    );
  }

  /// Fusiona [incoming] sobre [current] descartando duplicados por id y
  /// manteniendo el orden ascendente.
  List<MessageModel> _mergeMessages(
    List<MessageModel> current,
    List<MessageModel> incoming,
  ) {
    final merged = [...current];
    final ids = current.map((m) => m.id).toSet();
    for (final message in incoming) {
      if (message.id.isEmpty || !ids.add(message.id)) continue;
      merged.add(message);
    }
    return _sorted(merged);
  }

  List<MessageModel> _sorted(List<MessageModel> messages) =>
      [...messages]..sort(_compareMessages);

  Future<void> _deliver(String tempId, String body) async {
    try {
      final message = await _repository.sendMessage(chatId, body);
      debugPrint('[Chat:$chatId] Sent message');
      if (!mounted) return;
      _replaceOptimistic(tempId, message);
    } catch (e) {
      debugPrint('[Chat:$chatId] send ERROR: $e');
      if (!mounted) return;
      state = state.copyWith(
        statuses: {...state.statuses, tempId: MessageStatus.failed},
      );
    }
  }

  void _replaceOptimistic(String tempId, MessageModel message) {
    final data =
        state.messages.where((m) => m.id != tempId).toList(growable: true);
    // Si el broadcast propio llegó antes que la respuesta del POST, el id
    // real ya está en la lista: se descarta la burbuja temporal sin duplicar.
    final alreadyPresent =
        message.id.isNotEmpty && data.any((m) => m.id == message.id);
    if (!alreadyPresent && message.id.isNotEmpty) {
      data.add(message);
    }
    final statuses = Map<String, MessageStatus>.of(state.statuses)
      ..remove(tempId);
    if (message.id.isNotEmpty) {
      statuses[message.id] = MessageStatus.sent;
    }
    state = state.copyWith(
      pagination: state.pagination.copyWith(data: _sorted(data)),
      statuses: statuses,
    );
  }

  void _clearTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (state.typingUserId == null) return;
    state = state.copyWith(typingUserId: null);
  }
}

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>(
        (ref, chatId) {
  return MessagesNotifier(ref.watch(chatRepositoryProvider), chatId);
});
