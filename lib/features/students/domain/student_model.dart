import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_model.freezed.dart';

@freezed
class StudentModel with _$StudentModel {
  const factory StudentModel({
    required String id,
    @Default('') String fullname,
    @Default('') String email,
    @Default('') String year,
    @Default('') String status,
    @Default('') String identityNumber,
    @Default('') String branch,
    @Default('') String avatarUrl,
    @Default([]) List<String> classroomNames,
    @Default(0) int classroomCount,
  }) = _StudentModel;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    final relationships = json['relationships'] as Map<String, dynamic>?;
    final classrooms = relationships?['classrooms']?['data'] as List<dynamic>?;
    return StudentModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      fullname: attrs['fullname'] ?? '',
      email: attrs['email'] ?? '',
      year: attrs['year'] ?? '',
      status: attrs['status'] ?? '',
      identityNumber: attrs['identity_number'] ?? '',
      branch: attrs['branch'] ?? '',
      avatarUrl: attrs['avatar_url'] ?? '',
      classroomNames: (attrs['classroom_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      classroomCount: classrooms?.length ?? 0,
    );
  }
}
