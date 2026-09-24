import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/attendance_api.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_day.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(apiClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(attendanceApiProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AttendanceState {
  final AttendanceDay? day;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? saveError;
  final bool saved;
  final bool hasChanges;

  const AttendanceState({
    this.day,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.saveError,
    this.saved = false,
    this.hasChanges = false,
  });

  AttendanceState copyWith({
    AttendanceDay? day,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? saveError,
    bool? saved,
    bool? hasChanges,
    bool clearError = false,
    bool clearSaveError = false,
  }) {
    return AttendanceState(
      day: day ?? this.day,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      saved: saved ?? this.saved,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final String classroomId;

  Set<String> _originalAbsentIds = {};

  AttendanceNotifier(this._repository, this.classroomId)
      : super(const AttendanceState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, saved: false);
    try {
      final day = await _repository.getAttendance(classroomId);
      _originalAbsentIds = _absentIdsOf(day);
      state = state.copyWith(
        day: day,
        isLoading: false,
        hasChanges: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggle(String studentId) {
    final day = state.day;
    if (day == null) return;

    final students = day.students.map((student) {
      if (student.id != studentId) return student;
      return student.copyWith(
        status: student.isAbsent ? 'present' : 'absent',
      );
    }).toList();

    final updatedDay = day.copyWith(
      students: students,
      absentCount: students.where((student) => student.isAbsent).length,
    );

    state = state.copyWith(
      day: updatedDay,
      hasChanges: _absentIdsOf(updatedDay).difference(_originalAbsentIds).isNotEmpty ||
          _originalAbsentIds.difference(_absentIdsOf(updatedDay)).isNotEmpty,
      clearSaveError: true,
    );
  }

  Future<bool> save() async {
    final day = state.day;
    if (day == null || day.date.isEmpty) return false;

    state = state.copyWith(
      isSaving: true,
      clearSaveError: true,
      saved: false,
    );

    try {
      final absentIds = _absentIdsOf(day).toList();
      await _repository.saveAttendance(
        classroomId,
        date: day.date,
        absentStudentIds: absentIds,
      );
      _originalAbsentIds = _absentIdsOf(day);
      state = state.copyWith(
        isSaving: false,
        hasChanges: false,
        saved: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        saveError: e.toString(),
      );

      return false;
    }
  }

  Set<String> _absentIdsOf(AttendanceDay day) => day.students
      .where((student) => student.isAbsent)
      .map((student) => student.id)
      .toSet();
}

final attendanceProvider = StateNotifierProvider.autoDispose
    .family<AttendanceNotifier, AttendanceState, String>((ref, classroomId) {
  return AttendanceNotifier(
    ref.watch(attendanceRepositoryProvider),
    classroomId,
  );
});
