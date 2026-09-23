import 'package:freezed_annotation/freezed_annotation.dart';

part 'professor_model.freezed.dart';

@freezed
class ProfessorModel with _$ProfessorModel {
  const factory ProfessorModel({
    required String id,
    @Default('') String fullname,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String address,
    @Default('') String identityNumber,
    @Default('') String bio,
    @Default('') String specialty,
  }) = _ProfessorModel;

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return ProfessorModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      fullname: attrs['fullname'] ?? '',
      email: attrs['email'] ?? '',
      phone: attrs['phone'] ?? '',
      address: attrs['address'] ?? '',
      identityNumber: attrs['identity_number'] ?? '',
      bio: attrs['bio'] ?? '',
      specialty: attrs['specialty'] ?? '',
    );
  }
}
