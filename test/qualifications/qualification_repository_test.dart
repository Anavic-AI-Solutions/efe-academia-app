import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_api.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/qualifications'),
      statusCode: 200,
      data: data,
    );

class _FakeQualificationApi implements QualificationApi {
  Map<String, dynamic>? lastQuery;
  (String, String)? lastBoletinIds;
  Object boletinPayload = {};
  Object boletinLinkPayload = {
    'data': {
      'url': 'https://x/qualifications/boletin/s1/c1/file?signature=abc'
    },
  };
  DioException? boletinError;

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

  @override
  Future<Response> getClassroomGradesSummary(String classroomId) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getBoletin(String studentId, String classroomId) async {
    lastBoletinIds = (studentId, classroomId);
    if (boletinError != null) throw boletinError!;
    return _response(boletinPayload);
  }

  @override
  Future<Response> getBoletinLink(String studentId, String classroomId) async {
    lastBoletinIds = (studentId, classroomId);
    if (boletinError != null) throw boletinError!;
    return _response(boletinLinkPayload);
  }

  @override
  Future<Response> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      Future.error(UnimplementedError());
}

/// Stub del transporte HTTP: captura el path sin salir a la red.
class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(_FakeSecureStorage());

  String? lastPath;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    return _response({'data': <String, dynamic>{}});
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

const _boletinPayload = {
  'data': {
    'student': {'id': 's1', 'fullname': 'Marega, Paola'},
    'classroom': {'id': 'c1', 'name': '3G X'},
    'periods': ['1'],
    'qualifications': [
      {'type': 'Escrito', 'category': 'Desempeño', 'period': '1', 'score': '8'},
    ],
    'averages': {'1': 8.0, '2': null},
    'absences': {
      'total': 1,
      'justified': 1,
      'unjustified': 0,
      'attendance_by_period': {'1': 95.0},
      'list': [
        {'date': '2026-03-10', 'quantity': 1, 'justified': true},
      ],
    },
    'observations': [
      {'date': '2026-03-12', 'description': 'Bien', 'period': '1'},
    ],
  },
};

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

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

    test('getBoletin forwards student and classroom and parses the payload',
        () async {
      final api = _FakeQualificationApi()..boletinPayload = _boletinPayload;
      final repository = QualificationRepository(api);

      final boletin = await repository.getBoletin('s1', 'c1');

      expect(api.lastBoletinIds, ('s1', 'c1'));
      expect(boletin.studentFullname, 'Marega, Paola');
      expect(boletin.classroomName, '3G X');
      expect(boletin.periods, ['1']);
      expect(boletin.qualifications.single.type, 'Escrito');
      expect(boletin.averages['1'], 8.0);
      expect(boletin.averages['2'], isNull);
      expect(boletin.absences.total, 1);
      expect(boletin.absences.list.single.justified, isTrue);
      expect(boletin.observations.single.description, 'Bien');
    });

    test('getBoletin maps DioException to ApiException', () async {
      final api = _FakeQualificationApi()
        ..boletinError = DioException(
          requestOptions: RequestOptions(path: '/qualifications/boletin/s1/c1'),
          response: Response(
            requestOptions:
                RequestOptions(path: '/qualifications/boletin/s1/c1'),
            statusCode: 403,
            data: {'message': 'Forbidden'},
          ),
        );
      final repository = QualificationRepository(api);

      await expectLater(
        repository.getBoletin('s1', 'c1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('getBoletinUrl returns the signed url', () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      final url = await repository.getBoletinUrl('s1', 'c1');

      expect(api.lastBoletinIds, ('s1', 'c1'));
      expect(
        url,
        'https://x/qualifications/boletin/s1/c1/file?signature=abc',
      );
    });

    test('getBoletinUrl returns empty string when the url is missing',
        () async {
      final api = _FakeQualificationApi()
        ..boletinLinkPayload = {'data': <String, dynamic>{}};
      final repository = QualificationRepository(api);

      expect(await repository.getBoletinUrl('s1', 'c1'), '');
    });
  });

  group('QualificationApi', () {
    test('getBoletin builds the boletin path', () async {
      final client = _CapturingApiClient();
      final api = QualificationApi(client);

      await api.getBoletin('s1', 'c1');

      expect(client.lastPath, '/qualifications/boletin/s1/c1');
    });

    test('getBoletinLink builds the link path', () async {
      final client = _CapturingApiClient();
      final api = QualificationApi(client);

      await api.getBoletinLink('s1', 'c1');

      expect(client.lastPath, '/qualifications/boletin/s1/c1/link');
    });
  });

  group('boletinProvider', () {
    test('exposes the boletin for the student/classroom record', () async {
      final api = _FakeQualificationApi()..boletinPayload = _boletinPayload;
      final container = ProviderContainer(
        overrides: [
          qualificationRepositoryProvider.overrideWithValue(
            QualificationRepository(api),
          ),
        ],
      );
      addTearDown(container.dispose);

      const key = (studentId: 's1', classroomId: 'c1');
      final subscription = container.listen(
        boletinProvider(key),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      final boletin = container.read(boletinProvider(key)).value;
      expect(boletin?.studentFullname, 'Marega, Paola');
      expect(api.lastBoletinIds, ('s1', 'c1'));
    });
  });
}
