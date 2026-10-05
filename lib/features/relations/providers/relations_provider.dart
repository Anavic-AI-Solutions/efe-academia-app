import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/relations_api.dart';
import '../data/relations_repository.dart';
import '../domain/relation_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final relationsApiProvider = Provider<RelationsApi>((ref) {
  return RelationsApi(ref.watch(apiClientProvider));
});

final relationsRepositoryProvider = Provider<RelationsRepository>((ref) {
  return RelationsRepository(ref.watch(relationsApiProvider));
});

// ---------------------------------------------------------------------------
// Relations State
// ---------------------------------------------------------------------------

class RelationsState {
  final CursorPagination<RelationModel> pagination;
  final bool isLoading;
  final String? error;
  final String query;

  RelationsState({
    CursorPagination<RelationModel>? pagination,
    this.isLoading = false,
    this.error,
    this.query = '',
  }) : pagination = pagination ?? CursorPagination<RelationModel>.empty();

  List<RelationModel> get relations => pagination.data;
  bool get hasMore => pagination.hasMore;

  RelationsState copyWith({
    CursorPagination<RelationModel>? pagination,
    bool? isLoading,
    String? error,
    String? query,
    bool clearError = false,
  }) {
    return RelationsState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

// ---------------------------------------------------------------------------
// Relations Notifier
// ---------------------------------------------------------------------------

class RelationsNotifier extends StateNotifier<RelationsState> {
  final RelationsRepository _repository;

  RelationsNotifier(this._repository) : super(RelationsState()) {
    load();
  }

  String? get _query => state.query.isEmpty ? null : state.query;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getRelations(query: _query);
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getRelations(query: _query);
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getRelations(
        query: _query,
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

  Future<void> setQuery(String query) async {
    if (state.query == query) return;
    state = state.copyWith(query: query);
    await load();
  }
}

final relationsProvider =
    StateNotifierProvider<RelationsNotifier, RelationsState>((ref) {
  return RelationsNotifier(ref.watch(relationsRepositoryProvider));
});
