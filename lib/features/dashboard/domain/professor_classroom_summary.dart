import 'package:freezed_annotation/freezed_annotation.dart';

part 'professor_classroom_summary.freezed.dart';
part 'professor_classroom_summary.g.dart';

@freezed
class ProfessorClassroomSummary with _$ProfessorClassroomSummary {
  const factory ProfessorClassroomSummary({
    required String id,
    @Default('') String name,
    @Default(0) int studentsCount,
  }) = _ProfessorClassroomSummary;

  factory ProfessorClassroomSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfessorClassroomSummaryFromJson(json);
}
