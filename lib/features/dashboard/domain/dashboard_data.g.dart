// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardDataImpl _$$DashboardDataImplFromJson(Map<String, dynamic> json) =>
    _$DashboardDataImpl(
      role: json['role'] as String? ?? '',
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalClassrooms: (json['totalClassrooms'] as num?)?.toInt() ?? 0,
      totalProfessors: (json['totalProfessors'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toInt() ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingFees: (json['pendingFees'] as num?)?.toInt() ?? 0,
      unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
      absencesToday: (json['absencesToday'] as num?)?.toInt() ?? 0,
      classrooms: (json['classrooms'] as List<dynamic>?)
              ?.map((e) =>
                  ProfessorClassroomSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$DashboardDataImplToJson(_$DashboardDataImpl instance) =>
    <String, dynamic>{
      'role': instance.role,
      'totalStudents': instance.totalStudents,
      'totalClassrooms': instance.totalClassrooms,
      'totalProfessors': instance.totalProfessors,
      'attendanceRate': instance.attendanceRate,
      'monthlyRevenue': instance.monthlyRevenue,
      'pendingFees': instance.pendingFees,
      'unreadNotifications': instance.unreadNotifications,
      'absencesToday': instance.absencesToday,
      'classrooms': instance.classrooms,
    };
