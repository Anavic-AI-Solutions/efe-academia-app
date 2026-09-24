import 'package:efe_mobile/features/dashboard/data/dashboard_api.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardApi implements DashboardApi {
  final Map<String, dynamic> payload;

  _FakeDashboardApi(this.payload);

  @override
  Future<Response> getDashboard() async => Response(
        requestOptions: RequestOptions(path: '/statistics/dashboard'),
        data: payload,
      );
}

void main() {
  group('DashboardRepository', () {
    test('maps professor metrics and classrooms detail', () async {
      final repository = DashboardRepository(
        _FakeDashboardApi({
          'data': {
            'role': 'professor',
            'metrics': {
              'classrooms_count': 3,
              'total_students': 78,
              'absences_today': 4,
              'open_tickets': 1,
              'classrooms_detail': [
                {'id': 'a1', 'name': '3G X', 'students_count': 24},
                {'id': 'a2', 'name': '1G X', 'students_count': 30},
              ],
            },
            'details': <String, dynamic>{},
          },
        }),
      );

      final data = await repository.getDashboard();

      expect(data.role, 'professor');
      expect(data.totalClassrooms, 3);
      expect(data.totalStudents, 78);
      expect(data.absencesToday, 4);
      expect(data.classrooms, hasLength(2));
      expect(data.classrooms.first.id, 'a1');
      expect(data.classrooms.first.name, '3G X');
      expect(data.classrooms.first.studentsCount, 24);
    });

    test('keeps admin metrics working', () async {
      final repository = DashboardRepository(
        _FakeDashboardApi({
          'data': {
            'role': 'admin',
            'metrics': {
              'total_students': 120,
              'total_classrooms': 12,
              'total_owed': 1500.5,
              'fees_overdue': 7,
            },
            'details': <String, dynamic>{},
          },
        }),
      );

      final data = await repository.getDashboard();

      expect(data.role, 'admin');
      expect(data.totalStudents, 120);
      expect(data.totalClassrooms, 12);
      expect(data.pendingFees, 7);
      expect(data.monthlyRevenue, 1500.5);
      expect(data.classrooms, isEmpty);
    });

    test('returns empty data when the payload is unexpected', () async {
      final repository = DashboardRepository(_FakeDashboardApi({}));

      final data = await repository.getDashboard();

      expect(data.role, '');
      expect(data.totalClassrooms, 0);
      expect(data.classrooms, isEmpty);
    });
  });
}
