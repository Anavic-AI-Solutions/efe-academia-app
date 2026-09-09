import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
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
  final List<EventModel> events;
  final bool isLoading;
  final String? error;

  const EventListState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventListState copyWith({
    List<EventModel>? events,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EventListState(
      events: events ?? this.events,
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

  EventListNotifier(this._repository) : super(const EventListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.getEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.getEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final eventListProvider =
    StateNotifierProvider<EventListNotifier, EventListState>((ref) {
  return EventListNotifier(ref.watch(eventRepositoryProvider));
});
