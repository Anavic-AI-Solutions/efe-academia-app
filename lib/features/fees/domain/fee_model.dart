import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_model.freezed.dart';

@freezed
class FeeModel with _$FeeModel {
  const factory FeeModel({
    required String id,
    @Default('') String studentId,
    @Default('') String studentName,
    @Default(0) int numberFee,
    @Default('') String month,
    @Default('') String year,
    @Default(0.0) double toPay,
    @Default(0.0) double paid,
    @Default(0.0) double total,
    @Default('') String status,
    @Default('') String paymentMethod,
    @Default('') String paymentDate,
  }) = _FeeModel;

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json['data']?['attributes'] as Map<String, dynamic>? ?? json;
    return FeeModel(
      id: json['data']?['id']?.toString() ?? json['id']?.toString() ?? attrs['id']?.toString() ?? '',
      studentId: attrs['student_id']?.toString() ?? '',
      studentName: attrs['student_name'] ?? '',
      numberFee: _parseInt(attrs['number_fee']),
      month: attrs['month'] ?? '',
      year: attrs['year'] ?? '',
      toPay: _parseDouble(attrs['to_pay']),
      paid: _parseDouble(attrs['paid']),
      total: _parseDouble(attrs['total']),
      status: attrs['status'] ?? '',
      paymentMethod: attrs['payment_method'] ?? '',
      paymentDate: attrs['payment_date'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
