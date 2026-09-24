import 'package:freezed_annotation/freezed_annotation.dart';

import 'professor_classroom_summary.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    @Default('') String role,
    @Default(0) int totalStudents,
    @Default(0) int totalClassrooms,
    @Default(0) int totalProfessors,
    @Default(0) int attendanceRate,
    @Default(0.0) double monthlyRevenue,
    @Default(0) int pendingFees,
    @Default(0) int unreadNotifications,
    @Default(0) int absencesToday,
    @Default([]) List<ProfessorClassroomSummary> classrooms,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}
