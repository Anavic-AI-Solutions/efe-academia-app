import 'package:dio/dio.dart';
import 'package:efe_mobile/features/relations/data/relations_api.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/relations'),
      statusCode: 200,
      data: data,
    );

class _FakeRelationsApi implements RelationsApi {
  _FakeRelationsApi(this.responseData);

  final Object? responseData;
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response> getRelations({
    String? query,
    String? cursor,
    int limit = 50,
  }) async {
    lastQuery = {'query': query, 'cursor': cursor, 'limit': limit};
    return _response(responseData);
  }
}

void main() {
  group('RelationsRepository', () {
    test('parses the json api relation element into a RelationModel', () async {
      final repository = RelationsRepository(_FakeRelationsApi({
        'data': [
          {
            'type': 'relation',
            'id': '7',
            'attributes': {
              'fullname': 'María Pérez',
              'role': 'student',
              'user_id': 7,
            },
          },
        ],
        'meta': {'cursor': 'Mw==', 'has_more': true, 'total': 12},
      }));

      final result = await repository.getRelations();

      final relation = result.data.single;
      expect(relation.id, '7');
      expect(relation.fullname, 'María Pérez');
      expect(relation.role, 'student');
      expect(relation.userId, 7);
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, 'Mw==');
      expect(result.total, 12);
    });

    test('returns an empty pagination when the response has no data', () async {
      final repository = RelationsRepository(_FakeRelationsApi({
        'data': [],
        'meta': {'has_more': false},
      }));

      final result = await repository.getRelations();

      expect(result.data, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('tolerates a missing meta cursor', () async {
      final repository = RelationsRepository(_FakeRelationsApi({
        'data': [
          {
            'type': 'relation',
            'id': '9',
            'attributes': {
              'fullname': 'Juan Gómez',
              'role': 'parent',
              'user_id': 9
            },
          },
        ],
      }));

      final result = await repository.getRelations();

      expect(result.data.single.id, '9');
      expect(result.nextCursor, isNull);
      expect(result.hasMore, isFalse);
    });
  });
}
