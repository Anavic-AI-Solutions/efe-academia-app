import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_day.freezed.dart';

@freezed
class AttendanceStudent with _$AttendanceStudent {
  const factory AttendanceStudent({
    required String id,
    @Default('') String fullname,
    @Default('present') String status,
    int? absenceId,
  }) = _AttendanceStudent;

  const AttendanceStudent._();

  bool get isAbsent => status == 'absent';

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    final absenceId = json['absence_id'];

    return AttendanceStudent(
      id: json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      status: json['status']?.toString() ?? 'present',
      absenceId: absenceId is int
          ? absenceId
          : int.tryParse(absenceId?.toString() ?? ''),
    );
  }
}

@freezed
class AttendanceDay with _$AttendanceDay {
  const factory AttendanceDay({
    @Default('') String date,
    @Default('') String classroomId,
    @Default('') String classroomName,
    @Default(0) int studentsCount,
    @Default(0) int absentCount,
    @Default([]) List<AttendanceStudent> students,
  }) = _AttendanceDay;

  const AttendanceDay._();

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;

    final students = (attrs['students'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AttendanceStudent.fromJson)
        .toList();

    return AttendanceDay(
      date: attrs['date']?.toString() ?? '',
      classroomId: attrs['classroom_id']?.toString() ?? '',
      classroomName: attrs['classroom_name']?.toString() ?? '',
      studentsCount:
          (attrs['students_count'] as num?)?.toInt() ?? students.length,
      absentCount: (attrs['absent_count'] as num?)?.toInt() ??
          students.where((student) => student.isAbsent).length,
      students: students,
    );
  }
}
