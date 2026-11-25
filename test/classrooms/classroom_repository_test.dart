import 'package:dio/dio.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_api.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/classrooms'),
      statusCode: 200,
      data: data,
    );

class _FakeClassroomApi implements ClassroomApi {
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastRelated;
  int filtersCalls = 0;

  @override
  Future<Response> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
    String? studentId,
  }) async {
    lastQuery = {
      'search': search,
      'page': page,
      'limit': limit,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
    };
    return _response({
      'data': [
        {
          'type': 'classrooms',
          'id': 'room-1',
          'attributes': {'name': 'A2 A', 'level': 'A2'},
        },
      ],
      'meta': {'cursor': 'next-cursor', 'has_more': true, 'total': 57},
    });
  }

  @override
  Future<Response> getClassroom(String id) async => _response({});

  @override
  Future<Response> getClassroomFilters() async {
    filtersCalls++;
    return _response({
      'data': {
        'branches': ['Reconquista'],
        'levels': ['A2'],
        'years': ['2026'],
        'statuses': ['active', 'archived'],
      },
    });
  }

  @override
  Future<Response> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    lastRelated = {'kind': 'students', 'id': id, 'page': page, 'limit': limit};
    return _response({
      'data': [
        {
          'type': 'students',
          'id': 's1',
          'attributes': {'fullname': 'Ana', 'email': 'ana@example.com'},
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }

  @override
  Future<Response> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    lastRelated = {
      'kind': 'professors',
      'id': id,
      'page': page,
      'limit': limit,
    };
    return _response({
      'data': [
        {
          'type': 'professor_data',
          'id': 'p1',
          'attributes': {'fullname': 'Ana Pérez', 'specialty': 'Matemática'},
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }

  @override
  Future<Response> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    lastRelated = {
      'kind': 'materials',
      'id': id,
      'page': page,
      'limit': limit,
    };
    return _response({
      'data': [
        {
          'type': 'materials',
          'id': 'm1',
          'attributes': {'name': 'Apunte 1', 'download_count': 4},
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }

  @override
  Future<Response> createClassroom(Map<String, dynamic> data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> updateClassroom(String id, Map<String, dynamic> data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> deleteClassroom(String id) =>
      Future.error(UnimplementedError());
}

void main() {
  group('ClassroomRepository', () {
    test('forwards filters, search and page to the api', () async {
      final api = _FakeClassroomApi();
      final repository = ClassroomRepository(api);

      await repository.getClassrooms(
        search: 'A2',
        page: 3,
        branch: 'Vera',
        level: 'A2',
        year: '2026',
        status: 'archived',
      );

      expect(api.lastQuery?['search'], 'A2');
      expect(api.lastQuery?['page'], 3);
      expect(api.lastQuery?['branch'], 'Vera');
      expect(api.lastQuery?['level'], 'A2');
      expect(api.lastQuery?['year'], '2026');
      expect(api.lastQuery?['status'], 'archived');
    });

    test('parses classrooms and page meta from the response', () async {
      final repository = ClassroomRepository(_FakeClassroomApi());

      final result = await repository.getClassrooms(page: 2, limit: 20);

      expect(result.data.single.id, 'room-1');
      expect(result.data.single.level, 'A2');
      expect(result.page, 2);
      expect(result.perPage, 20);
      expect(result.total, 57);
      expect(result.totalPages, 3);
    });

    test('getFilters parses filter options', () async {
      final repository = ClassroomRepository(_FakeClassroomApi());

      final filters = await repository.getFilters();

      expect(filters.branches, ['Reconquista']);
      expect(filters.levels, ['A2']);
      expect(filters.years, ['2026']);
      expect(filters.statuses, ['active', 'archived']);
    });

    test('getClassroomStudents forwards pagination and parses students',
        () async {
      final api = _FakeClassroomApi();
      final repository = ClassroomRepository(api);

      final result =
          await repository.getClassroomStudents('c1', page: 2, limit: 10);

      expect(api.lastRelated?['kind'], 'students');
      expect(api.lastRelated?['id'], 'c1');
      expect(api.lastRelated?['page'], 2);
      expect(api.lastRelated?['limit'], 10);
      expect(result.data.single.fullname, 'Ana');
      expect(result.page, 2);
      expect(result.perPage, 10);
      expect(result.total, 1);
    });

    test('getClassroomProfessors forwards pagination and parses professors',
        () async {
      final api = _FakeClassroomApi();
      final repository = ClassroomRepository(api);

      final result =
          await repository.getClassroomProfessors('c1', page: 3, limit: 5);

      expect(api.lastRelated?['kind'], 'professors');
      expect(api.lastRelated?['page'], 3);
      expect(result.data.single.fullname, 'Ana Pérez');
      expect(result.data.single.specialty, 'Matemática');
      expect(result.page, 3);
      expect(result.perPage, 5);
    });

    test('getClassroomMaterials forwards pagination and parses materials',
        () async {
      final api = _FakeClassroomApi();
      final repository = ClassroomRepository(api);

      final result = await repository.getClassroomMaterials('c1', page: 1);

      expect(api.lastRelated?['kind'], 'materials');
      expect(result.data.single.name, 'Apunte 1');
      expect(result.data.single.downloadCount, 4);
      expect(result.total, 1);
    });
  });
}
