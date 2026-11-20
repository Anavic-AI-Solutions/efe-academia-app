import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_api.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/qualifications'),
      statusCode: 200,
      data: data,
    );

class _FakeQualificationApi implements QualificationApi {
  String? updatedId;
  Map<String, dynamic>? updatedData;
  String? deletedId;
  Object? error;

  @override
  Future<Response> updateQualification(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (error != null) throw error!;
    updatedId = id;
    updatedData = data;
    return _response({
      'data': {
        'type': 'qualifications',
        'id': id,
      },
    });
  }

  @override
  Future<Response> deleteQualification(String id) async {
    if (error != null) throw error!;
    deletedId = id;
    return _response(null);
  }

  @override
  Future<Response> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getQualification(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getClassroomGradesSummary(String classroomId) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getBoletin(String studentId, String classroomId) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getBoletinLink(String studentId, String classroomId) =>
      Future.error(UnimplementedError());

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

/// Stub del transporte HTTP: captura el path y el payload sin salir a la red.
class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(_FakeSecureStorage());

  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;
  String? lastDeletePath;

  @override
  Future<Response> patch(String path, {dynamic data}) async {
    lastPatchPath = path;
    lastPatchData = data as Map<String, dynamic>?;
    return _response({'data': <String, dynamic>{}});
  }

  @override
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastDeletePath = path;
    return _response(null);
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

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('QualificationRepository.updateQualification', () {
    test('envía el id y el payload exacto', () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      await repository.updateQualification(
        id: 'q1',
        studentId: 's1',
        classroomId: 'c1',
        score: '9.5',
        type: 'Escrito',
        period: '2',
        category: 'Desempeño',
        description: 'Mejoró',
      );

      expect(api.updatedId, 'q1');
      expect(api.updatedData, {
        'student_id': 's1',
        'classroom_id': 'c1',
        'score': '9.5',
        'type': 'Escrito',
        'period': '2',
        'category': 'Desempeño',
        'description': 'Mejoró',
      });
    });

    test('omite category pero envía description aunque esté vacía', () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      await repository.updateQualification(
        id: 'q2',
        studentId: 's1',
        classroomId: 'c1',
        score: '7',
        type: 'Oral',
        period: '1',
        category: '',
        description: '',
      );

      expect(api.updatedData, {
        'student_id': 's1',
        'classroom_id': 'c1',
        'score': '7',
        'type': 'Oral',
        'period': '1',
        'description': '',
      });
    });

    test('propaga la ValidationException del interceptor 422', () async {
      final validation = ValidationException(
        fieldErrors: {'score': 'inválido'},
      );
      final api = _FakeQualificationApi()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/qualifications/q1'),
          error: validation,
        );
      final repository = QualificationRepository(api);

      await expectLater(
        repository.updateQualification(
          id: 'q1',
          studentId: 's1',
          classroomId: 'c1',
          score: '',
          type: 'Escrito',
          period: '1',
        ),
        throwsA(same(validation)),
      );
    });
  });

  group('QualificationRepository.deleteQualification', () {
    test('envía el id a eliminar', () async {
      final api = _FakeQualificationApi();
      final repository = QualificationRepository(api);

      await repository.deleteQualification('q1');

      expect(api.deletedId, 'q1');
    });

    test('propaga la ValidationException del interceptor 422', () async {
      final validation = ValidationException(fieldErrors: {'id': 'inválido'});
      final api = _FakeQualificationApi()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/qualifications/q1'),
          error: validation,
        );
      final repository = QualificationRepository(api);

      await expectLater(
        repository.deleteQualification('q1'),
        throwsA(same(validation)),
      );
    });
  });

  group('QualificationApi', () {
    test('updateQualification hace PATCH a /qualifications/{id}', () async {
      final client = _CapturingApiClient();
      final api = QualificationApi(client);

      await api.updateQualification('q1', {'score': '9'});

      expect(client.lastPatchPath, '/qualifications/q1');
      expect(client.lastPatchData, {'score': '9'});
    });

    test('deleteQualification hace DELETE a /qualifications/{id}', () async {
      final client = _CapturingApiClient();
      final api = QualificationApi(client);

      await api.deleteQualification('q1');

      expect(client.lastDeletePath, '/qualifications/q1');
    });
  });
}
