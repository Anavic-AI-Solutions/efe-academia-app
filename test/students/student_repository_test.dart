import 'package:dio/dio.dart';
import 'package:efe_mobile/features/students/data/student_api.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/students'),
      statusCode: 200,
      data: data,
    );

class _FakeStudentApi implements StudentApi {
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    lastQuery = {
      'search': search,
      'status': status,
      'year': year,
      'branch': branch,
      'page': page,
      'limit': limit,
    };
    return _response({
      'data': [
        {
          'type': 'student_data',
          'id': 's1',
          'attributes': {'fullname': 'Ana Gómez'},
          'relationships': {
            'classrooms': {
              'data': [
                {'type': 'classrooms', 'id': 'c1'},
              ],
            },
          },
        },
      ],
      'meta': {'cursor': 'next', 'has_more': true, 'total': 57},
    });
  }

  @override
  Future<Response> getStudent(String id) async => _response({
        'type': 'student_data',
        'id': id,
        'attributes': {'fullname': 'Ana Gómez'},
      });

  @override
  Future<Response> getClassrooms(String studentId) async => _response({
        'data': [
          {'id': 'c1', 'name': '3G X', 'shift': 'Mañana'},
        ],
      });
}

void main() {
  group('StudentRepository', () {
    test('forwards filters and page to the api', () async {
      final api = _FakeStudentApi();
      final repository = StudentRepository(api);

      await repository.getStudents(
        search: 'Ana',
        status: 'active',
        year: '2026',
        branch: 'Reconquista',
        page: 3,
      );

      expect(api.lastQuery?['search'], 'Ana');
      expect(api.lastQuery?['status'], 'active');
      expect(api.lastQuery?['year'], '2026');
      expect(api.lastQuery?['branch'], 'Reconquista');
      expect(api.lastQuery?['page'], 3);
    });

    test('parses students and page meta from the response', () async {
      final repository = StudentRepository(_FakeStudentApi());

      final result = await repository.getStudents(page: 2, limit: 20);

      expect(result.data.single.id, 's1');
      expect(result.data.single.fullname, 'Ana Gómez');
      expect(result.data.single.classroomCount, 1);
      expect(result.page, 2);
      expect(result.perPage, 20);
      expect(result.total, 57);
      expect(result.totalPages, 3);
    });

    test('parses the student detail', () async {
      final repository = StudentRepository(_FakeStudentApi());

      final student = await repository.getStudent('s1');

      expect(student.id, 's1');
      expect(student.fullname, 'Ana Gómez');
    });

    test('parses the student classrooms from raw items', () async {
      final repository = StudentRepository(_FakeStudentApi());

      final classrooms = await repository.getClassrooms('s1');

      expect(classrooms.single.id, 'c1');
      expect(classrooms.single.name, '3G X');
      expect(classrooms.single.shift, 'Mañana');
    });
  });
}
