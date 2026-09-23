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
  });
}
