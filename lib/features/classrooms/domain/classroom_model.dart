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
    @Default(0) int studentCount,
  }) = _ClassroomModel;

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return ClassroomModel(
      id: json['data']?['id']?.toString() ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? '',
      description: attrs['description'] ?? '',
      status: attrs['status'] ?? '',
      shift: attrs['shift'] ?? '',
      day: attrs['day'] ?? '',
      hour: attrs['hour'] ?? '',
      room: attrs['room'] ?? '',
      year: attrs['year'] ?? '',
      branch: attrs['branch'] ?? '',
      studentCount: _parseInt(attrs['student_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
