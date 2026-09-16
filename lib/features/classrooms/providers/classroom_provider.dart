import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/classroom_api.dart';
import '../data/classroom_repository.dart';
import '../domain/classroom_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final classroomApiProvider = Provider<ClassroomApi>((ref) {
  return ClassroomApi(ref.watch(apiClientProvider));
});

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  return ClassroomRepository(ref.watch(classroomApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class ClassroomListState {
  final CursorPagination<ClassroomModel> pagination;
  final bool isLoading;
  final String? error;
  final String search;

  ClassroomListState({
    CursorPagination<ClassroomModel>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
  }) : pagination = pagination ?? CursorPagination<ClassroomModel>.empty();

  ClassroomListState copyWith({
    CursorPagination<ClassroomModel>? pagination,
    bool? isLoading,
    String? error,
    String? search,
    bool clearError = false,
  }) {
    return ClassroomListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
    );
  }
}

// ---------------------------------------------------------------------------
// List Notifier
// ---------------------------------------------------------------------------

class ClassroomListNotifier extends StateNotifier<ClassroomListState> {
  final ClassroomRepository _repository;

  ClassroomListNotifier(this._repository) : super(ClassroomListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getClassrooms(search: state.search);
      debugPrint('[Classrooms] Loaded ${result.data.length} items (search="${state.search}")');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Classrooms] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getClassrooms(search: state.search);
      debugPrint('[Classrooms] Refreshed ${result.data.length} items');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      debugPrint('[Classrooms] refresh ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value);
    await load();
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getClassrooms(
        search: state.search,
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

final classroomListProvider =
    StateNotifierProvider<ClassroomListNotifier, ClassroomListState>((ref) {
  return ClassroomListNotifier(ref.watch(classroomRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final classroomDetailProvider =
    FutureProvider.family<ClassroomModel, String>((ref, id) async {
  final repository = ref.watch(classroomRepositoryProvider);
  return repository.getClassroom(id);
});
