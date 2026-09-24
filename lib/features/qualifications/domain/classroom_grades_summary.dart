import 'package:freezed_annotation/freezed_annotation.dart';

part 'classroom_grades_summary.freezed.dart';

double? _parseAverage(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@freezed
class ClassroomGradeStudent with _$ClassroomGradeStudent {
  const factory ClassroomGradeStudent({
    required String studentId,
    @Default('') String fullname,
    double? average,
  }) = _ClassroomGradeStudent;

  factory ClassroomGradeStudent.fromJson(Map<String, dynamic> json) {
    return ClassroomGradeStudent(
      studentId: json['student_id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      average: _parseAverage(json['average']),
    );
  }
}

@freezed
class ClassroomGradesSummary with _$ClassroomGradesSummary {
  const factory ClassroomGradesSummary({
    @Default('') String classroomId,
    @Default('') String classroomName,
    double? classroomAverage,
    @Default(0) int studentsCount,
    @Default([]) List<ClassroomGradeStudent> students,
  }) = _ClassroomGradesSummary;

  factory ClassroomGradesSummary.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;

    final students = (attrs['students'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ClassroomGradeStudent.fromJson)
        .toList();

    return ClassroomGradesSummary(
      classroomId: attrs['classroom_id']?.toString() ?? '',
      classroomName: attrs['classroom_name']?.toString() ?? '',
      classroomAverage: _parseAverage(attrs['classroom_average']),
      studentsCount:
          (attrs['students_count'] as num?)?.toInt() ?? students.length,
      students: students,
    );
  }
}
