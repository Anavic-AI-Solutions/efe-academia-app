import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/page_pagination.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../students/domain/student_model.dart';
import '../data/classroom_api.dart';
import '../data/classroom_repository.dart';
import '../domain/classroom_filters.dart';
import '../domain/classroom_model.dart';
import '../domain/material_model.dart';
import '../domain/professor_model.dart';

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
// Filter options
// ---------------------------------------------------------------------------

final classroomFiltersProvider = FutureProvider<ClassroomFilters>((ref) {
  return ref.watch(classroomRepositoryProvider).getFilters();
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class ClassroomListState {
  final PageResult<ClassroomModel> page;
  final bool isLoading;
  final String? error;
  final String search;
  final String? branch;
  final String? level;
  final String? year;
  final String? status;

  ClassroomListState({
    PageResult<ClassroomModel>? page,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.branch,
    this.level,
    this.year,
    this.status,
  }) : page = page ?? PageResult<ClassroomModel>.empty();

  bool get hasActiveFilters =>
      branch != null || level != null || year != null || status != null;

  ClassroomListState copyWith({
    PageResult<ClassroomModel>? page,
    bool? isLoading,
    String? error,
    String? search,
    bool clearError = false,
  }) {
    return ClassroomListState(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      branch: branch,
      level: level,
      year: year,
      status: status,
    );
  }
}

// ---------------------------------------------------------------------------
// List Notifier
// ---------------------------------------------------------------------------

class ClassroomListNotifier extends StateNotifier<ClassroomListState> {
  final ClassroomRepository _repository;
  int _requestId = 0;

  ClassroomListNotifier(this._repository) : super(ClassroomListState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getClassrooms(
        search: state.search,
        page: page,
        branch: state.branch,
        level: state.level,
        year: state.year,
        status: state.status,
      );
      if (requestId != _requestId) return;
      if (result.data.isEmpty && page > 1 && result.total > 0) {
        await load(page: 1);
        return;
      }
      state = state.copyWith(page: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load(page: state.page.page);

  Future<void> search(String value) async {
    state = state.copyWith(search: value);
    await load();
  }

  Future<void> applyFilters({
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async {
    state = ClassroomListState(
      search: state.search,
      branch: branch,
      level: level,
      year: year,
      status: status,
    );
    await load();
  }

  Future<void> clearFilters() => applyFilters();

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.page.totalPages || page == state.page.page) {
      return Future.value();
    }
    return load(page: page);
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

// ---------------------------------------------------------------------------
// Related paged lists
// ---------------------------------------------------------------------------

final classroomStudentsProvider = StateNotifierProvider.family<
    PagedListNotifier<StudentModel>,
    PagedListState<StudentModel>,
    String>((ref, classroomId) {
  final repository = ref.watch(classroomRepositoryProvider);
  return PagedListNotifier<StudentModel>(
    (page) => repository.getClassroomStudents(classroomId, page: page),
  );
});

final classroomProfessorsProvider = StateNotifierProvider.family<
    PagedListNotifier<ProfessorModel>,
    PagedListState<ProfessorModel>,
    String>((ref, classroomId) {
  final repository = ref.watch(classroomRepositoryProvider);
  return PagedListNotifier<ProfessorModel>(
    (page) => repository.getClassroomProfessors(classroomId, page: page),
  );
});

final classroomMaterialsProvider = StateNotifierProvider.family<
    PagedListNotifier<MaterialModel>,
    PagedListState<MaterialModel>,
    String>((ref, classroomId) {
  final repository = ref.watch(classroomRepositoryProvider);
  return PagedListNotifier<MaterialModel>(
    (page) => repository.getClassroomMaterials(classroomId, page: page),
  );
});
