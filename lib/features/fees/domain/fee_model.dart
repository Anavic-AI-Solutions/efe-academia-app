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
    @Default('') String proofStatus,
    @Default(false) bool isOverdue,
    @Default(0.0) double owe,
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
      month: attrs['month']?.toString() ?? '',
      year: attrs['year']?.toString() ?? '',
      toPay: _parseDouble(attrs['to_pay']),
      paid: _parseDouble(attrs['paid']),
      total: _parseDouble(attrs['total']),
      status: attrs['status'] ?? '',
      proofStatus: attrs['proof_status']?.toString() ?? '',
      isOverdue: _parseBool(attrs['is_overdue']),
      owe: _parseDouble(attrs['owe']),
      paymentMethod: attrs['payment_method'] ?? '',
      paymentDate: attrs['payment_date'] ?? '',
    );
  }

  static bool _parseBool(dynamic value) =>
      value == true || value == 1 || value == '1';

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
