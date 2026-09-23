import 'package:dio/dio.dart';
import 'package:efe_mobile/features/fees/data/fee_api.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/fees'),
      statusCode: 200,
      data: data,
    );

class _FakeFeeApi implements FeeApi {
  Map<String, dynamic>? lastQuery;

  @override
  Future<Response> getFees({
    String? studentId,
    String? studentAppId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) async {
    lastQuery = {
      'studentId': studentId,
      'studentAppId': studentAppId,
      'page': page,
      'limit': limit,
    };
    return _response({
      'data': [
        {
          'type': 'system_collections_fees',
          'id': 'f1',
          'attributes': {
            'number_fee': 1,
            'month': 3,
            'year': 2026,
            'total': 25000,
            'status': 'pending',
          },
        },
      ],
      'meta': {'cursor': null, 'has_more': false, 'total': 1},
    });
  }

  @override
  Future<Response> getFee(String id) async => _response({});
}

void main() {
  group('FeeRepository', () {
    test('getStudentFees forwards student_app_id and page to the api',
        () async {
      final api = _FakeFeeApi();
      final repository = FeeRepository(api);

      final result = await repository.getStudentFees('uuid-1', page: 2);

      expect(api.lastQuery?['studentAppId'], 'uuid-1');
      expect(api.lastQuery?['page'], 2);
      expect(result.data.single.numberFee, 1);
      expect(result.data.single.total, 25000);
      expect(result.data.single.status, 'pending');
      expect(result.page, 2);
      expect(result.total, 1);
    });
  });
}
