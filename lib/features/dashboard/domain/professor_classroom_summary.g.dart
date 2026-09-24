// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'professor_classroom_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfessorClassroomSummaryImpl _$$ProfessorClassroomSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProfessorClassroomSummaryImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProfessorClassroomSummaryImplToJson(
        _$ProfessorClassroomSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'studentsCount': instance.studentsCount,
    };
