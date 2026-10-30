import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/fees/data/fee_api.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/fees'),
      statusCode: 200,
      data: data,
    );

class _FakeFeeApi implements FeeApi {
  Map<String, dynamic>? lastQuery;
  (String, FormData)? lastUploadProof;
  String? lastInvoiceLinkId;
  String? lastInvoiceBytesUrl;
  DioException? uploadError;
  DioException? invoiceBytesError;
  Object feePayload = {};
  Object invoicePayload = {
    'data': {'url': 'https://x/fees/1/invoice-file?signature=abc'},
  };
  List<int> invoiceBytes = const [37, 80, 68, 70];

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
  Future<Response> getFee(String id) async => _response(feePayload);

  @override
  Future<Response> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) async {
    if (uploadError != null) throw uploadError!;
    final form = FormData()
      ..files.add(
        MapEntry('proof', MultipartFile.fromBytes(bytes, filename: filename)),
      );
    lastUploadProof = (feeId, form);
    return _response({
      'data': {'id': feeId},
    });
  }

  @override
  Future<Response> getInvoiceLink(String feeId) async {
    lastInvoiceLinkId = feeId;
    return _response(invoicePayload);
  }

  @override
  Future<Response<List<int>>> getInvoiceBytes(String url) async {
    lastInvoiceBytesUrl = url;
    final error = invoiceBytesError;
    if (error != null) throw error;
    return Response<List<int>>(
      requestOptions: RequestOptions(path: url),
      statusCode: 200,
      data: invoiceBytes,
    );
  }
}

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> saveToken(String token) async => values['auth_token'] = token;

  @override
  Future<String?> getToken() async => values['auth_token'];

  @override
  Future<void> deleteToken() async => values.remove('auth_token');

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> saveThemeMode(String mode) async => values['theme_mode'] = mode;

  @override
  Future<String?> getThemeMode() async => values['theme_mode'];

  @override
  Future<void> saveLanguageCode(String code) async =>
      values['language_code'] = code;

  @override
  Future<String?> getLanguageCode() async => values['language_code'];

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<String?> getFcmToken() async => null;

  @override
  Future<void> deleteFcmToken() async {}

  @override
  Future<String> getOrCreateDeviceId() async => 'test-device';

  @override
  Future<bool> hasSeenPushPrimer() async => false;

  @override
  Future<void> savePushPrimerSeen() async {}
}

/// Stub del transporte HTTP: captura el path y el body sin salir a la red.
class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(_FakeSecureStorage());

  String? lastPath;
  Object? lastData;
  String? lastBytesPath;
  bool? lastBytesAcceptPdf;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    return _response({
      'data': {'url': 'https://x/fees/f1/invoice-file?signature=abc'},
    });
  }

  @override
  Future<Response<List<int>>> getBytes(
    String path, {
    Map<String, String>? headers,
  }) async {
    lastBytesPath = path;
    lastBytesAcceptPdf = headers?['Accept'] == 'application/pdf';
    return Response<List<int>>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: const [37, 80, 68, 70],
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    lastPath = path;
    lastData = data;
    return _response({
      'data': {'id': 'f1'},
    });
  }
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

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

    test('parses proof status, is_overdue and owe', () async {
      final api = _FakeFeeApi()
        ..feePayload = {
          'data': {
            'type': 'system_collections_fees',
            'id': 'f1',
            'attributes': {
              'number_fee': 1,
              'status': 'pending',
              'proof_status': 'under_review',
              'is_overdue': true,
              'owe': 1200.5,
            },
          },
        };
      final repository = FeeRepository(api);

      final fee = await repository.getFee('f1');

      expect(fee.proofStatus, 'under_review');
      expect(fee.isOverdue, isTrue);
      expect(fee.owe, 1200.5);
    });

    test('parses tolerant is_overdue values (1 and "1")', () async {
      final api = _FakeFeeApi()
        ..feePayload = {
          'id': 'f1',
          'attributes': {'is_overdue': 1},
        };
      final repository = FeeRepository(api);

      expect((await repository.getFee('f1')).isOverdue, isTrue);

      api.feePayload = {
        'id': 'f2',
        'attributes': {'is_overdue': '1'},
      };
      expect((await repository.getFee('f2')).isOverdue, isTrue);

      api.feePayload = {
        'id': 'f3',
        'attributes': {'is_overdue': false},
      };
      final fee = await repository.getFee('f3');
      expect(fee.isOverdue, isFalse);
      expect(fee.proofStatus, '');
      expect(fee.owe, 0);
    });

    test('uploadProof posts multipart with the proof field', () async {
      final api = _FakeFeeApi();
      final repository = FeeRepository(api);

      await repository.uploadProof('f1',
          bytes: [1, 2, 3], filename: 'proof.jpg');

      final captured = api.lastUploadProof!;
      expect(captured.$1, 'f1');
      expect(captured.$2.files.first.key, 'proof');
      expect(captured.$2.files.first.value.filename, 'proof.jpg');
      expect(captured.$2.files.first.value.length, 3);
    });

    test('uploadProof maps DioException to ApiException', () async {
      final api = _FakeFeeApi()
        ..uploadError = DioException(
          requestOptions: RequestOptions(path: '/fees/f1/upload-proof'),
          response: Response(
            requestOptions: RequestOptions(path: '/fees/f1/upload-proof'),
            statusCode: 422,
            data: {'message': 'boom'},
          ),
        );
      final repository = FeeRepository(api);

      await expectLater(
        repository.uploadProof('f1', bytes: [1], filename: 'proof.jpg'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('getInvoiceUrl returns the signed url', () async {
      final api = _FakeFeeApi();
      final repository = FeeRepository(api);

      final url = await repository.getInvoiceUrl('f1');

      expect(api.lastInvoiceLinkId, 'f1');
      expect(url, 'https://x/fees/1/invoice-file?signature=abc');
    });

    test('getInvoiceUrl returns empty string when the url is missing',
        () async {
      final api = _FakeFeeApi()..invoicePayload = {'data': <String, dynamic>{}};
      final repository = FeeRepository(api);

      expect(await repository.getInvoiceUrl('f1'), '');
    });

    test('getInvoiceFile returns the signed url and its bytes', () async {
      final api = _FakeFeeApi();
      final repository = FeeRepository(api);

      final file = await repository.getInvoiceFile('f1');

      expect(api.lastInvoiceLinkId, 'f1');
      expect(api.lastInvoiceBytesUrl,
          'https://x/fees/1/invoice-file?signature=abc');
      expect(file.url, 'https://x/fees/1/invoice-file?signature=abc');
      expect(file.bytes, const [37, 80, 68, 70]);
    });

    test('getInvoiceFile throws 404 when the link has no url', () async {
      final api = _FakeFeeApi()..invoicePayload = {'data': <String, dynamic>{}};
      final repository = FeeRepository(api);

      await expectLater(
        repository.getInvoiceFile('f1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
      expect(api.lastInvoiceBytesUrl, isNull);
    });

    test('getInvoiceFile maps a 404 on the file to ApiException', () async {
      final api = _FakeFeeApi()
        ..invoiceBytesError = DioException(
          requestOptions: RequestOptions(path: '/fees/1/invoice-file'),
          response: Response(
            requestOptions: RequestOptions(path: '/fees/1/invoice-file'),
            statusCode: 404,
            data: {'message': 'Factura no disponible'},
          ),
        );
      final repository = FeeRepository(api);

      await expectLater(
        repository.getInvoiceFile('f1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('FeeApi', () {
    test('uploadProof builds the multipart request with the proof field',
        () async {
      final client = _CapturingApiClient();
      final api = FeeApi(client);

      await api.uploadProof('f1', bytes: [1, 2, 3], filename: 'proof.jpg');

      expect(client.lastPath, '/fees/f1/upload-proof');
      final form = client.lastData as FormData;
      expect(form.files.first.key, 'proof');
      expect(form.files.first.value.filename, 'proof.jpg');
      expect(form.files.first.value.length, 3);
    });

    test('getInvoiceLink hits the invoice-link endpoint', () async {
      final client = _CapturingApiClient();
      final api = FeeApi(client);

      final response = await api.getInvoiceLink('f1');

      expect(client.lastPath, '/fees/f1/invoice-link');
      expect(response.data['data']['url'], contains('/invoice-file'));
    });

    test('getInvoiceBytes requests the signed url accepting a pdf', () async {
      final client = _CapturingApiClient();
      final api = FeeApi(client);

      final response = await api.getInvoiceBytes(
        'https://x/fees/f1/invoice-file?signature=abc',
      );

      expect(
          client.lastBytesPath, 'https://x/fees/f1/invoice-file?signature=abc');
      expect(client.lastBytesAcceptPdf, isTrue);
      expect(response.data, const [37, 80, 68, 70]);
    });
  });
}
