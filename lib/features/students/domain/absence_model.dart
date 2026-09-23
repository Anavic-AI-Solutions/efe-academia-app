import 'package:freezed_annotation/freezed_annotation.dart';

part 'absence_model.freezed.dart';

@freezed
class AbsenceModel with _$AbsenceModel {
  const factory AbsenceModel({
    required String id,
    @Default(0) int quantity,
    @Default('') String period,
    @Default('') String justified,
    @Default('') String description,
    @Default('') String status,
    @Default('') String date,
  }) = _AbsenceModel;

  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return AbsenceModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      quantity: _parseInt(attrs['quantity']),
      period: attrs['period']?.toString() ?? '',
      justified: attrs['justified']?.toString() ?? '',
      description: attrs['description'] ?? '',
      status: attrs['status'] ?? '',
      date: attrs['date']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
