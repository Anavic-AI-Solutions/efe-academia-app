import '../domain/dashboard_data.dart';
import '../domain/parent_home_data.dart';
import '../domain/professor_classroom_summary.dart';
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

    final role = rawData['role']?.toString() ?? '';

    // Metrics use role-specific keys (e.g. professors get classrooms_count).
    final metrics = rawData['metrics'];
    final m = metrics is Map<String, dynamic> ? metrics : rawData;

    final details = rawData['details'];
    final d = details is Map<String, dynamic> ? details : <String, dynamic>{};

    final parentHome = role == 'parent' ? _parseParentHome(m, d) : null;

    return DashboardData(
      role: role,
      totalStudents:
          _asInt(m['total_students'] ?? m['totalStudents']),
      totalClassrooms: _asInt(
        m['classrooms_count'] ?? m['total_classrooms'] ?? m['totalClassrooms'],
      ),
      totalProfessors: _asInt(m['total_professors'] ?? d['totalProfessors']),
      attendanceRate: _asInt(m['attendance_rate'] ?? d['attendanceRate']),
      monthlyRevenue:
          _asDouble(m['total_owed'] ?? m['monthlyRevenue'] ?? d['monthlyRevenue']),
      pendingFees: _asInt(m['fees_overdue'] ?? m['pendingFees']),
      unreadNotifications:
          _asInt(m['open_tickets'] ?? m['unreadNotifications']),
      absencesToday: _asInt(m['absences_today']),
      classrooms: _parseClassrooms(m['classrooms_detail']),
      parentHome: parentHome,
    );
  }

  ParentHomeData _parseParentHome(
      Map<String, dynamic> m, Map<String, dynamic> d) {
    final raw = d['myChildrenSummary'];
    final children = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(ParentChildSummary.fromJson)
            .toList()
        : <ParentChildSummary>[];
    return ParentHomeData(
      overdueFeesCount: _asInt(m['fees_overdue']),
      moraTotal: _asDouble(m['total_owed']),
      children: children,
    );
  }

  List<ProfessorClassroomSummary> _parseClassrooms(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ProfessorClassroomSummary(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            studentsCount: _asInt(item['students_count']),
          ),
        )
        .where((classroom) => classroom.id.isNotEmpty)
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
