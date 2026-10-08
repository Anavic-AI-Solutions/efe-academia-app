import 'package:freezed_annotation/freezed_annotation.dart';

part 'birthday_model.freezed.dart';

@freezed
class BirthdayModel with _$BirthdayModel {
  const factory BirthdayModel({
    required String id,
    required String name,
    required int ageTurning,
    String? studentAppId,
    DateTime? birthDate,
    @Default(0) int daysUntil,
  }) = _BirthdayModel;

  factory BirthdayModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return BirthdayModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      name: attrs['name'] ?? '',
      ageTurning: _parseInt(attrs['age_turning'] ?? attrs['ageTurning']),
      studentAppId: attrs['student_app_id']?.toString() ??
          attrs['studentAppId']?.toString(),
      birthDate: attrs['birth_date'] != null
          ? DateTime.tryParse(attrs['birth_date'].toString())
          : attrs['birthDate'] != null
              ? DateTime.tryParse(attrs['birthDate'].toString())
              : null,
      daysUntil: _parseInt(attrs['days_until'] ?? attrs['daysUntil']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
