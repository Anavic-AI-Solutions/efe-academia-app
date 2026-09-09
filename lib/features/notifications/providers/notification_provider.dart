import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
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
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
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

  NotificationListNotifier(this._repository) : super(const NotificationListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _repository.getNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _repository.getNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repository.markRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>((ref) {
  return NotificationListNotifier(ref.watch(notificationRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Unread Count Provider
// ---------------------------------------------------------------------------

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});
