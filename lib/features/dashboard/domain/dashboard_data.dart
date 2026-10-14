// `@JsonKey` on a freezed factory parameter is the documented way to configure
// json_serializable; the analyzer flags it as an invalid annotation target.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'parent_home_data.dart';
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
    @JsonKey(includeFromJson: false, includeToJson: false)
    ParentHomeData? parentHome,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}
