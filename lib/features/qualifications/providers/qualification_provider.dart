import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/qualification_api.dart';
import '../data/qualification_repository.dart';
import '../domain/boletin_data.dart';
import '../domain/classroom_grades_summary.dart';
import '../domain/qualification_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final qualificationApiProvider = Provider<QualificationApi>((ref) {
  return QualificationApi(ref.watch(apiClientProvider));
});

final qualificationRepositoryProvider =
    Provider<QualificationRepository>((ref) {
  return QualificationRepository(ref.watch(qualificationApiProvider));
});

// ---------------------------------------------------------------------------
// List State
// ---------------------------------------------------------------------------

class QualificationListState {
  final CursorPagination<QualificationModel> pagination;
  final bool isLoading;
  final String? error;
  final String search;

  QualificationListState({
    CursorPagination<QualificationModel>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
  }) : pagination = pagination ?? CursorPagination<QualificationModel>.empty();

  QualificationListState copyWith({
    CursorPagination<QualificationModel>? pagination,
    bool? isLoading,
    String? error,
    String? search,
    bool clearError = false,
  }) {
    return QualificationListState(
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

class QualificationListNotifier extends StateNotifier<QualificationListState> {
  final QualificationRepository _repository;

  QualificationListNotifier(this._repository)
      : super(QualificationListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getQualifications(search: state.search);
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getQualifications(search: state.search);
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
      final result = await _repository.getQualifications(
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

final qualificationListProvider =
    StateNotifierProvider<QualificationListNotifier, QualificationListState>(
        (ref) {
  return QualificationListNotifier(ref.watch(qualificationRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Classroom grades summary
// ---------------------------------------------------------------------------

final classroomGradesProvider =
    FutureProvider.autoDispose.family<ClassroomGradesSummary, String>(
  (ref, classroomId) {
    return ref
        .watch(qualificationRepositoryProvider)
        .getClassroomGradesSummary(classroomId);
  },
);

// ---------------------------------------------------------------------------
// Boletin
// ---------------------------------------------------------------------------

final boletinProvider = FutureProvider.family<BoletinData,
    ({String studentId, String classroomId})>(
  (ref, key) {
    return ref
        .watch(qualificationRepositoryProvider)
        .getBoletin(key.studentId, key.classroomId);
  },
);
