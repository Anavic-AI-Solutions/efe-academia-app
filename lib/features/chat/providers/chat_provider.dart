import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
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
  final List<ChatModel> chats;
  final bool isLoading;
  final String? error;

  const ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<ChatModel>? chats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
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

  ChatListNotifier(this._repository) : super(const ChatListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final chats = await _repository.getChats();
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final chats = await _repository.getChats();
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
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
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    bool? hasMore,
    bool clearError = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ---------------------------------------------------------------------------
// Messages Notifier
// ---------------------------------------------------------------------------

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository _repository;
  final String chatId;

  MessagesNotifier(this._repository, this.chatId) : super(const MessagesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await _repository.getMessages(chatId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await _repository.getMessages(chatId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> send(String body) async {
    try {
      final message = await _repository.sendMessage(chatId, body);
      state = state.copyWith(messages: [...state.messages, message]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, chatId) {
  return MessagesNotifier(ref.watch(chatRepositoryProvider), chatId);
});
