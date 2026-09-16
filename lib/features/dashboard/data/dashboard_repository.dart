import '../domain/dashboard_data.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  final DashboardApi _api;

  DashboardRepository(this._api);

  Future<DashboardData> getDashboard() async {
    final response = await _api.getDashboard();
    final rawData = response.data['data'];

    if (rawData is! Map<String, dynamic>) {
      return const DashboardData();
    }

    // Extract metrics (snake_case from API)
    final metrics = rawData['metrics'];
    final m = metrics is Map<String, dynamic> ? metrics : rawData;

    final details = rawData['details'];
    final d = details is Map<String, dynamic> ? details : <String, dynamic>{};

    return DashboardData(
      totalStudents: (m['total_students'] ?? m['totalStudents'] ?? 0) as int,
      totalClassrooms: (m['total_classrooms'] ?? m['totalClassrooms'] ?? 0) as int,
      totalProfessors: (m['total_professors'] ?? d['totalProfessors'] ?? 0) as int,
      attendanceRate: (m['attendance_rate'] ?? d['attendanceRate'] ?? 0) as int,
      monthlyRevenue: (m['total_owed'] ?? m['monthlyRevenue'] ?? 0).toDouble(),
      pendingFees: (m['fees_overdue'] ?? m['pendingFees'] ?? 0) as int,
      unreadNotifications: (m['open_tickets'] ?? m['unreadNotifications'] ?? 0) as int,
    );
  }
}
