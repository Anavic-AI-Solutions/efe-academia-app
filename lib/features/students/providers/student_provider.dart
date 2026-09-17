import 'package:flutter/foundation.dart';
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
  static const statusAll = 'all';
  static const statusActive = 'active';
  static const statusInactive = 'inactive';

  final CursorPagination<StudentModel> pagination;
  final bool isLoading;
  final String? error;
  final String search;
  final String status;
  final String? year;
  final String? branch;
  final List<String> yearOptions;
  final List<String> branchOptions;

  StudentListState({
    CursorPagination<StudentModel>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.status = statusActive,
    this.year,
    this.branch,
    this.yearOptions = const [],
    this.branchOptions = const [],
  }) : pagination = pagination ?? CursorPagination<StudentModel>.empty();

  StudentListState copyWith({
    CursorPagination<StudentModel>? pagination,
    bool? isLoading,
    String? error,
    String? search,
    String? status,
    String? year,
    String? branch,
    bool clearYear = false,
    bool clearBranch = false,
    List<String>? yearOptions,
    List<String>? branchOptions,
    bool clearError = false,
  }) {
    return StudentListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      status: status ?? this.status,
      year: clearYear ? null : (year ?? this.year),
      branch: clearBranch ? null : (branch ?? this.branch),
      yearOptions: yearOptions ?? this.yearOptions,
      branchOptions: branchOptions ?? this.branchOptions,
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

  String? get _statusParam =>
      state.status == StudentListState.statusAll ? null : state.status;

  void _mergeFilterOptions(List<StudentModel> students) {
    final years = {
      ...state.yearOptions,
      ...students.map((s) => s.year).where((v) => v.isNotEmpty),
    }.toList()
      ..sort();
    final branches = {
      ...state.branchOptions,
      ...students.map((s) => s.branch).where((v) => v.isNotEmpty),
    }.toList()
      ..sort();
    state = state.copyWith(yearOptions: years, branchOptions: branches);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getStudents(
        search: state.search,
        status: _statusParam,
        year: state.year,
        branch: state.branch,
      );
      print(
          '[Students] Loaded ${result.data.length} items (search="${state.search}", status=${state.status}, year=${state.year}, branch=${state.branch})');
      state = state.copyWith(pagination: result, isLoading: false);
      _mergeFilterOptions(result.data);
    } catch (e) {
      print('[Students] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getStudents(
        search: state.search,
        status: _statusParam,
        year: state.year,
        branch: state.branch,
      );
      print('[Students] Refreshed ${result.data.length} items');
      state = state.copyWith(pagination: result, isLoading: false);
      _mergeFilterOptions(result.data);
    } catch (e) {
      print('[Students] refresh ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(
      search: value,
      pagination: CursorPagination<StudentModel>.empty(),
    );
    await load();
  }

  Future<void> setStatus(String status) async {
    if (state.status == status) return;
    state = state.copyWith(
      status: status,
      pagination: CursorPagination<StudentModel>.empty(),
    );
    await load();
  }

  Future<void> setYear(String? year) async {
    if (state.year == year) return;
    state = state.copyWith(
      year: year,
      clearYear: year == null,
      pagination: CursorPagination<StudentModel>.empty(),
    );
    await load();
  }

  Future<void> setBranch(String? branch) async {
    if (state.branch == branch) return;
    state = state.copyWith(
      branch: branch,
      clearBranch: branch == null,
      pagination: CursorPagination<StudentModel>.empty(),
    );
    await load();
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getStudents(
        search: state.search,
        status: _statusParam,
        year: state.year,
        branch: state.branch,
        cursor: state.pagination.nextCursor,
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
      _mergeFilterOptions(result.data);
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
