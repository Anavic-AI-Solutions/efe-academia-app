import 'package:freezed_annotation/freezed_annotation.dart';

part 'parent_home_data.freezed.dart';

@freezed
class ParentChildSummary with _$ParentChildSummary {
  const factory ParentChildSummary({
    @Default(0) int userId,
    @Default('') String studentId,
    @Default('') String name,
    @Default('') String classroomName,
    @Default(0) int classroomsCount,
    @Default('') String year,
    double? averageGrade,
    double? attendanceRate,
  }) = _ParentChildSummary;

  factory ParentChildSummary.fromJson(Map<String, dynamic> json) {
    return ParentChildSummary(
      userId: _asInt(json['user_id']),
      studentId: json['student_id']?.toString() ?? '',
      name: json['child_name']?.toString() ?? '',
      classroomName: json['classroom_name']?.toString() ?? '',
      classroomsCount: _asInt(json['classrooms_count']),
      year: json['year']?.toString() ?? '',
      averageGrade: _asDouble(json['average_grade']),
      attendanceRate: _asDouble(json['attendance_rate']),
    );
  }
}

@freezed
class ParentHomeData with _$ParentHomeData {
  const factory ParentHomeData({
    @Default(0) int overdueFeesCount,
    @Default(0.0) double moraTotal,
    @Default([]) List<ParentChildSummary> children,
  }) = _ParentHomeData;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
