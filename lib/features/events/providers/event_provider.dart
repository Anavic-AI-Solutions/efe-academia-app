import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/event_api.dart';
import '../data/event_repository.dart';
import '../domain/event_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.watch(apiClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(eventApiProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class EventListState {
  final CursorPagination<EventModel> pagination;
  final bool isLoading;
  final String? error;

  EventListState({
    CursorPagination<EventModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<EventModel>.empty();

  EventListState copyWith({
    CursorPagination<EventModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EventListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class EventListNotifier extends StateNotifier<EventListState> {
  final EventRepository _repository;

  EventListNotifier(this._repository) : super(EventListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getEvents();
      debugPrint('[Events] Loaded ${result.data.length} items');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Events] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getEvents();
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getEvents(
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
}

final eventListProvider =
    StateNotifierProvider<EventListNotifier, EventListState>((ref) {
  return EventListNotifier(ref.watch(eventRepositoryProvider));
});
