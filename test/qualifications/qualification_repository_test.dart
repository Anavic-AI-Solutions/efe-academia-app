import 'package:dio/dio.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_api.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/qualifications'),
      statusCode: 200,
      data: data,
    );

class _FakeQualificationApi implements QualificationApi {
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) async {
    lastQuery = {
      'studentId': studentId,
      'cursor': cursor,
      'page': page,
      'limit': limit,
    };
    return _response({
      'data': [
        {
          'type': 'qualifications',
          'id': 'q1',
          'attributes': {
            'score': '8.5',
            'type': 'Parcial',
            'period': '1',
            'created_at': '12/03/2026',
          },
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }

  @override
  Future<Response> getQualification(String id) async => _response({});
}

void main() {
  group('QualificationRepository', () {
    test('getStudentQualifications forwards student and page to the api',
        () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      final result =
          await repository.getStudentQualifications('s1', page: 2, limit: 10);

      expect(api.lastQuery?['studentId'], 's1');
      expect(api.lastQuery?['page'], 2);
      expect(api.lastQuery?['cursor'], isNull);
      expect(result.data.single.score, 8.5);
      expect(result.data.single.type, 'Parcial');
      expect(result.data.single.period, '1');
      expect(result.data.single.date, '12/03/2026');
      expect(result.page, 2);
      expect(result.perPage, 10);
      expect(result.total, 1);
    });

    test('keeps the cursor flow for the list screen', () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      await repository.getQualifications(search: 'Ana', cursor: 'cursor-1');

      expect(api.lastQuery?['cursor'], 'cursor-1');
      expect(api.lastQuery?['page'], isNull);
    });
  });
}
