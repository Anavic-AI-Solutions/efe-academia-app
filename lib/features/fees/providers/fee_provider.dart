import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/fee_api.dart';
import '../data/fee_repository.dart';
import '../domain/fee_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final feeApiProvider = Provider<FeeApi>((ref) {
  return FeeApi(ref.watch(apiClientProvider));
});

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository(ref.watch(feeApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class FeeListState {
  final CursorPagination<FeeModel> pagination;
  final bool isLoading;
  final String? error;
  final String search;
  final String? studentId;

  FeeListState({
    CursorPagination<FeeModel>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.studentId,
  }) : pagination = pagination ?? CursorPagination<FeeModel>.empty();

  FeeListState copyWith({
    CursorPagination<FeeModel>? pagination,
    bool? isLoading,
    String? error,
    String? search,
    String? studentId,
    bool clearStudentId = false,
    bool clearError = false,
  }) {
    return FeeListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      studentId: clearStudentId ? null : (studentId ?? this.studentId),
    );
  }
}

// ---------------------------------------------------------------------------
// List Notifier
// ---------------------------------------------------------------------------

class FeeListNotifier extends StateNotifier<FeeListState> {
  final FeeRepository _repository;

  FeeListNotifier(this._repository) : super(FeeListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getFees(
        studentId: state.studentId,
        search: state.search,
      );
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getFees(
        studentId: state.studentId,
        search: state.search,
      );
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value);
    await load();
  }

  Future<void> setStudent(String? studentId) async {
    if (studentId == null) {
      state = state.copyWith(clearStudentId: true);
    } else {
      state = state.copyWith(studentId: studentId);
    }
    await load();
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getFees(
        studentId: state.studentId,
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

final feeListProvider =
    StateNotifierProvider<FeeListNotifier, FeeListState>((ref) {
  return FeeListNotifier(ref.watch(feeRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final feeDetailProvider =
    FutureProvider.family<FeeModel, String>((ref, id) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFee(id);
});
