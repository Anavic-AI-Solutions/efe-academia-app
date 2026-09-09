import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/student_api.dart';
import '../data/student_repository.dart';
import '../domain/student_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final studentApiProvider = Provider<StudentApi>((ref) {
  return StudentApi(ref.watch(apiClientProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(studentApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class StudentListState {
  final CursorPagination<StudentModel> pagination;
  final bool isLoading;
  final String? error;
  final String search;

  StudentListState({
    CursorPagination<StudentModel>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
  }) : pagination = pagination ?? CursorPagination<StudentModel>.empty();

  StudentListState copyWith({
    CursorPagination<StudentModel>? pagination,
    bool? isLoading,
    String? error,
    String? search,
    bool clearError = false,
  }) {
    return StudentListState(
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

class StudentListNotifier extends StateNotifier<StudentListState> {
  final StudentRepository _repository;

  StudentListNotifier(this._repository) : super(StudentListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getStudents(search: state.search);
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getStudents(search: state.search);
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
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
      final result = await _repository.getStudents(
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

final studentListProvider =
    StateNotifierProvider<StudentListNotifier, StudentListState>((ref) {
  return StudentListNotifier(ref.watch(studentRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final studentDetailProvider =
    FutureProvider.family<StudentModel, String>((ref, id) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudent(id);
});
