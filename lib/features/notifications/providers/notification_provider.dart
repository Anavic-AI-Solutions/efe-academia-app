import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/notification_api.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class NotificationListState {
  final CursorPagination<NotificationModel> pagination;
  final bool isLoading;
  final String? error;

  NotificationListState({
    CursorPagination<NotificationModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<NotificationModel>.empty();

  List<NotificationModel> get notifications => pagination.data;

  NotificationListState copyWith({
    CursorPagination<NotificationModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// List Notifier
// ---------------------------------------------------------------------------

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationListNotifier(this._repository, this._ref)
      : super(NotificationListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNotifications();
      print('[Notifications] Loaded ${result.data.length} items');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      print('[Notifications] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNotifications();
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getNotifications(
        cursor: state.pagination.nextCursor,
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      state = state.copyWith(
        pagination: state.pagination.copyWith(
          data: state.notifications.map((n) => n.copyWith(read: true)).toList(),
        ),
      );
      _ref.invalidate(unreadCountProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repository.markRead(id);
      state = state.copyWith(
        pagination: state.pagination.copyWith(
          data: state.notifications
              .map((n) => n.id == id ? n.copyWith(read: true) : n)
              .toList(),
        ),
      );
      _ref.invalidate(unreadCountProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
        (ref) {
  return NotificationListNotifier(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});

// ---------------------------------------------------------------------------
// Unread Count Provider
// ---------------------------------------------------------------------------

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});
