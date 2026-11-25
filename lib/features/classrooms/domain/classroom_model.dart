import 'package:freezed_annotation/freezed_annotation.dart';

part 'classroom_model.freezed.dart';

@freezed
class ClassroomModel with _$ClassroomModel {
  const factory ClassroomModel({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String status,
    @Default('') String shift,
    @Default('') String day,
    @Default('') String hour,
    @Default('') String room,
    @Default('') String year,
    @Default('') String branch,
    @Default('') String level,
    @Default('') String grade,
    @Default('') String book,
    @Default('') String commission,
    @Default(0) int courseDays,
    @Default(0) int period1Days,
    @Default(0) int period2Days,
    @Default(0) int period3Days,
    @Default(true) bool isActive,
    @Default(false) bool isArchived,
    @Default(0) int studentCount,
  }) = _ClassroomModel;

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    final relationships = json['relationships'] as Map<String, dynamic>?;
    final students = relationships?['students']?['data'] as List<dynamic>?;
    return ClassroomModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      name: attrs['name'] ?? '',
      description: attrs['description'] ?? '',
      status: attrs['status'] ?? '',
      shift: attrs['shift'] ?? '',
      day: attrs['day'] ?? '',
      hour: attrs['hour'] ?? '',
      room: attrs['room'] ?? '',
      year: attrs['year'] ?? '',
      branch: attrs['branch'] ?? '',
      level: attrs['level'] ?? '',
      grade: attrs['grade'] ?? '',
      book: attrs['book'] ?? '',
      commission: attrs['commission'] ?? '',
      courseDays: _parseInt(attrs['course_days']),
      period1Days: _parseInt(attrs['period_1_days']),
      period2Days: _parseInt(attrs['period_2_days']),
      period3Days: _parseInt(attrs['period_3_days']),
      isActive: attrs['is_active'] as bool? ??
          !((attrs['is_archivated'] as bool?) ?? false),
      isArchived: (attrs['is_archivated'] as bool?) ?? false,
      studentCount: students?.length ?? _parseInt(attrs['student_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
