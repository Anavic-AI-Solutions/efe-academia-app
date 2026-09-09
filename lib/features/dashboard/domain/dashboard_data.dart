import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    @Default(0) int totalStudents,
    @Default(0) int totalClassrooms,
    @Default(0) int totalProfessors,
    @Default(0) int attendanceRate,
    @Default(0.0) double monthlyRevenue,
    @Default(0) int pendingFees,
    @Default(0) int unreadNotifications,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}
