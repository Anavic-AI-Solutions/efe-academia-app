import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/page_pagination.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../fees/domain/fee_model.dart';
import '../../fees/providers/fee_provider.dart';
import '../../qualifications/domain/qualification_model.dart';
import '../../qualifications/providers/qualification_provider.dart';
import '../data/absence_api.dart';
import '../data/absence_repository.dart';
import '../data/student_api.dart';
import '../data/student_repository.dart';
import '../domain/absence_model.dart';
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

final absenceApiProvider = Provider<AbsenceApi>((ref) {
  return AbsenceApi(ref.watch(apiClientProvider));
});

final absenceRepositoryProvider = Provider<AbsenceRepository>((ref) {
  return AbsenceRepository(ref.watch(absenceApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class StudentListState {
  static const statusAll = 'all';
  static const statusActive = 'active';
  static const statusInactive = 'inactive';

  final PageResult<StudentModel> page;
  final bool isLoading;
  final String? error;
  final String search;
  final String status;
  final String? year;
  final String? branch;
  final List<String> yearOptions;
  final List<String> branchOptions;

  StudentListState({
    PageResult<StudentModel>? page,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.status = statusActive,
    this.year,
    this.branch,
    this.yearOptions = const [],
    this.branchOptions = const [],
  }) : page = page ?? PageResult<StudentModel>.empty();

  StudentListState copyWith({
    PageResult<StudentModel>? page,
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
      page: page ?? this.page,
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
  int _requestId = 0;

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

  Future<void> load({int page = 1}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getStudents(
        search: state.search,
        status: _statusParam,
        year: state.year,
        branch: state.branch,
        page: page,
      );
      if (requestId != _requestId) return;
      if (result.data.isEmpty && page > 1 && result.total > 0) {
        await load(page: 1);
        return;
      }
      state = state.copyWith(page: result, isLoading: false);
      _mergeFilterOptions(result.data);
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

  Future<void> setStatus(String status) async {
    if (state.status == status) return;
    state = state.copyWith(status: status);
    await load();
  }

  Future<void> setYear(String? year) async {
    if (state.year == year) return;
    state = state.copyWith(year: year, clearYear: year == null);
    await load();
  }

  Future<void> setBranch(String? branch) async {
    if (state.branch == branch) return;
    state = state.copyWith(branch: branch, clearBranch: branch == null);
    await load();
  }

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.page.totalPages || page == state.page.page) {
      return Future.value();
    }
    return load(page: page);
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

// ---------------------------------------------------------------------------
// Related paged lists
// ---------------------------------------------------------------------------

final studentQualificationsProvider = StateNotifierProvider.family<
    PagedListNotifier<QualificationModel>,
    PagedListState<QualificationModel>,
    String>((ref, studentId) {
  final repository = ref.watch(qualificationRepositoryProvider);
  return PagedListNotifier<QualificationModel>(
    (page) => repository.getStudentQualifications(studentId, page: page),
  );
});

final studentAbsencesProvider = StateNotifierProvider.family<
    PagedListNotifier<AbsenceModel>,
    PagedListState<AbsenceModel>,
    String>((ref, studentId) {
  final repository = ref.watch(absenceRepositoryProvider);
  return PagedListNotifier<AbsenceModel>(
    (page) => repository.getAbsences(studentId: studentId, page: page),
  );
});

final studentFeesProvider = StateNotifierProvider.family<
    PagedListNotifier<FeeModel>,
    PagedListState<FeeModel>,
    String>((ref, studentId) {
  final repository = ref.watch(feeRepositoryProvider);
  return PagedListNotifier<FeeModel>(
    (page) => repository.getStudentFees(studentId, page: page),
  );
});
