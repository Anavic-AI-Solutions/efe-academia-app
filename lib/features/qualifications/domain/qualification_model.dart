import 'package:freezed_annotation/freezed_annotation.dart';

part 'qualification_model.freezed.dart';

@freezed
class QualificationModel with _$QualificationModel {
  const factory QualificationModel({
    required String id,
    @Default('') String studentId,
    @Default('') String classroomId,
    @Default('') String studentName,
    @Default('') String classroomName,
    @Default(0.0) double score,
    @Default('') String scoreLabel,
    @Default('') String type,
    @Default('') String category,
    @Default('') String period,
    @Default('') String description,
    @Default('') String date,
  }) = _QualificationModel;

  factory QualificationModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    final classroom = attrs['classroom'] as Map<String, dynamic>?;
    return QualificationModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      studentId: attrs['student_id']?.toString() ?? '',
      classroomId: attrs['classroom_id']?.toString() ?? '',
      studentName: attrs['student_name'] ?? '',
      classroomName: attrs['classroom_name']?.toString() ??
          classroom?['name']?.toString() ??
          '',
      score: _parseDouble(attrs['score']),
      scoreLabel: attrs['score']?.toString() ?? '',
      type: attrs['type'] ?? '',
      category: attrs['category'] ?? '',
      period: attrs['period']?.toString() ?? '',
      description: attrs['description'] ?? '',
      date: attrs['date']?.toString() ?? attrs['created_at']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
