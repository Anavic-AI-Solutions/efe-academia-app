import 'package:dio/dio.dart';
import 'package:efe_mobile/features/students/data/absence_api.dart';
import 'package:efe_mobile/features/students/data/absence_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/absences'),
      statusCode: 200,
      data: data,
    );

class _FakeAbsenceApi implements AbsenceApi {
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async {
    lastQuery = {'studentId': studentId, 'page': page, 'limit': limit};
    return _response({
      'data': [
        {
          'type': 'absences',
          'id': '1',
          'attributes': {'quantity': 2, 'description': 'Fiebre'},
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }
}

void main() {
  group('AbsenceRepository', () {
    test('forwards the student and page to the api', () async {
      final api = _FakeAbsenceApi();
      final repository = AbsenceRepository(api);

      await repository.getAbsences(studentId: 's1', page: 2);

      expect(api.lastQuery?['studentId'], 's1');
      expect(api.lastQuery?['page'], 2);
    });

    test('parses absences and page meta from the response', () async {
      final repository = AbsenceRepository(_FakeAbsenceApi());

      final result = await repository.getAbsences(studentId: 's1');

      expect(result.data.single.id, '1');
      expect(result.data.single.quantity, 2);
      expect(result.data.single.description, 'Fiebre');
      expect(result.page, 1);
      expect(result.total, 1);
    });
  });
}
