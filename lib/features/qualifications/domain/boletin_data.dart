import 'package:freezed_annotation/freezed_annotation.dart';

part 'boletin_data.freezed.dart';

@freezed
class BoletinQualification with _$BoletinQualification {
  const factory BoletinQualification({
    @Default('') String type,
    @Default('') String category,
    @Default('') String period,
    @Default('') String score,
  }) = _BoletinQualification;

  factory BoletinQualification.fromJson(Map<String, dynamic> json) {
    return BoletinQualification(
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
    );
  }
}

@freezed
class BoletinAbsence with _$BoletinAbsence {
  const factory BoletinAbsence({
    @Default('') String date,
    @Default(0) int quantity,
    @Default(false) bool justified,
  }) = _BoletinAbsence;

  factory BoletinAbsence.fromJson(Map<String, dynamic> json) {
    return BoletinAbsence(
      date: json['date']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
      justified: _asBool(json['justified']),
    );
  }
}

@freezed
class BoletinAbsences with _$BoletinAbsences {
  const factory BoletinAbsences({
    @Default(0) int total,
    @Default(0) int justified,
    @Default(0) int unjustified,
    @Default({}) Map<String, double?> attendanceByPeriod,
    @Default([]) List<BoletinAbsence> list,
  }) = _BoletinAbsences;

  factory BoletinAbsences.fromJson(Map<String, dynamic> json) {
    final attendance = <String, double?>{};
    final raw = json['attendance_by_period'];
    if (raw is Map) {
      raw.forEach((key, value) {
        attendance[key.toString()] = _asDouble(value);
      });
    }

    return BoletinAbsences(
      total: _asInt(json['total']),
      justified: _asInt(json['justified']),
      unjustified: _asInt(json['unjustified']),
      attendanceByPeriod: attendance,
      list: (json['list'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BoletinAbsence.fromJson)
          .toList(),
    );
  }
}

@freezed
class BoletinObservation with _$BoletinObservation {
  const factory BoletinObservation({
    @Default('') String date,
    @Default('') String description,
    @Default('') String period,
  }) = _BoletinObservation;

  factory BoletinObservation.fromJson(Map<String, dynamic> json) {
    return BoletinObservation(
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
    );
  }
}

@freezed
class BoletinData with _$BoletinData {
  const factory BoletinData({
    @Default('') String studentId,
    @Default('') String studentFullname,
    @Default('') String classroomId,
    @Default('') String classroomName,
    @Default([]) List<String> periods,
    @Default([]) List<BoletinQualification> qualifications,
    @Default({}) Map<String, double?> averages,
    @Default(BoletinAbsences()) BoletinAbsences absences,
    @Default([]) List<BoletinObservation> observations,
  }) = _BoletinData;

  factory BoletinData.fromJson(Map<String, dynamic> json) {
    final attrs = json['data'] as Map<String, dynamic>? ?? json;
    final student = attrs['student'] as Map<String, dynamic>? ?? {};
    final classroom = attrs['classroom'] as Map<String, dynamic>? ?? {};

    final averages = <String, double?>{};
    final rawAverages = attrs['averages'];
    if (rawAverages is Map) {
      rawAverages.forEach((key, value) {
        averages[key.toString()] = _asDouble(value);
      });
    }

    final rawAbsences = attrs['absences'];

    return BoletinData(
      studentId: student['id']?.toString() ?? '',
      studentFullname: student['fullname']?.toString() ?? '',
      classroomId: classroom['id']?.toString() ?? '',
      classroomName: classroom['name']?.toString() ?? '',
      periods: (attrs['periods'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      qualifications: (attrs['qualifications'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BoletinQualification.fromJson)
          .toList(),
      averages: averages,
      absences: rawAbsences is Map
          ? BoletinAbsences.fromJson(Map<String, dynamic>.from(rawAbsences))
          : const BoletinAbsences(),
      observations: (attrs['observations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BoletinObservation.fromJson)
          .toList(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
