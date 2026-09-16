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
      debugPrint('[Chat] Loaded ${result.data.length} conversations');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Chat] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getChats();
      debugPrint('[Chat] Refreshed ${result.data.length} conversations');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Chat] refresh ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
      debugPrint('[Chat] loadMore ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier(ref.watch(chatRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Messages State
// ---------------------------------------------------------------------------

class MessagesState {
  final CursorPagination<MessageModel> pagination;
  final bool isLoading;
  final String? error;

  MessagesState({
    CursorPagination<MessageModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<MessageModel>.empty();

  List<MessageModel> get messages => pagination.data;
  bool get hasMore => pagination.hasMore;

  MessagesState copyWith({
    CursorPagination<MessageModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MessagesState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Messages Notifier
// ---------------------------------------------------------------------------

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository _repository;
  final String chatId;

  MessagesNotifier(this._repository, this.chatId) : super(MessagesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMessages(chatId);
      debugPrint('[Chat:$chatId] Loaded ${result.data.length} messages');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Chat:$chatId] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMessages(chatId);
      debugPrint('[Chat:$chatId] Refreshed ${result.data.length} messages');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Chat:$chatId] refresh ERROR: $e');
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
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Chat:$chatId] loadMore ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String body) async {
    try {
      final message = await _repository.sendMessage(chatId, body);
      debugPrint('[Chat:$chatId] Sent message');
      state = state.copyWith(
        pagination: state.pagination.copyWith(
          data: [...state.pagination.data, message],
        ),
      );
    } catch (e) {
      debugPrint('[Chat:$chatId] send ERROR: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, chatId) {
  return MessagesNotifier(ref.watch(chatRepositoryProvider), chatId);
});
