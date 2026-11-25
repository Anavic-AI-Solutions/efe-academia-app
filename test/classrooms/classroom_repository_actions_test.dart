import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_api.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data, {int statusCode = 200}) => Response(
      requestOptions: RequestOptions(path: '/classrooms'),
      statusCode: statusCode,
      data: data,
    );

Map<String, dynamic> _classroomBody({
  String id = 'c1',
  String name = 'A2 A',
  String description = 'Curso A2',
  String status = 'active',
  String shift = 'Mañana',
  String day = 'Lunes',
  String hour = '08:00',
  String room = 'Sala 1',
  String year = '2026',
  String branch = 'Reconquista',
  String level = 'A2',
  String grade = '1',
  String book = 'Libro 1',
  String commission = 'A',
  int courseDays = 3,
  int period1Days = 2,
  int period2Days = 2,
  int period3Days = 3,
  bool isArchived = false,
}) =>
    {
      'data': {
        'type': 'classrooms',
        'id': id,
        'attributes': {
          'name': name,
          'description': description,
          'status': status,
          'shift': shift,
          'day': day,
          'hour': hour,
          'room': room,
          'year': year,
          'branch': branch,
          'level': level,
          'grade': grade,
          'book': book,
          'commission': commission,
          'course_days': courseDays,
          'period_1_days': period1Days,
          'period_2_days': period2Days,
          'period_3_days': period3Days,
          'is_archivated': isArchived,
        },
      },
    };

DioException _validationError() => DioException(
      requestOptions: RequestOptions(path: '/classrooms'),
      response: Response(
        requestOptions: RequestOptions(path: '/classrooms'),
        statusCode: 422,
        data: {
          'message': 'The name has already been taken.',
          'errors': {
            'name': ['The name has already been taken.'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
      error: ValidationException(
        fieldErrors: {'name': 'The name has already been taken.'},
        detail: 'The name has already been taken.',
      ),
    );

class _Call {
  _Call(this.method, this.path, this.data);

  final String method;
  final String path;
  final Object? data;
}

class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({this.responseData});

  final Object? responseData;
  final List<_Call> calls = [];

  @override
  Dio dio = Dio();

  Response<dynamic> _resolve() => _response(responseData);

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(_Call('GET', path, queryParameters));
    return _resolve();
  }

  @override
  Future<Response<List<int>>> getBytes(
    String path, {
    Map<String, String>? headers,
  }) async =>
      Response<List<int>>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: const <int>[],
      );

  @override
  Future<Response> post(String path, {dynamic data}) async {
    calls.add(_Call('POST', path, data));
    return _resolve();
  }

  @override
  Future<Response> patch(String path, {dynamic data}) async {
    calls.add(_Call('PATCH', path, data));
    return _resolve();
  }

  @override
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(_Call('DELETE', path, queryParameters));
    return _resolve();
  }

  @override
  Future<Response> upload(
    String path,
    FormData data, {
    Options? options,
  }) async {
    calls.add(_Call('UPLOAD', path, data));
    return _resolve();
  }
}

class _FakeClassroomApi implements ClassroomApi {
  _FakeClassroomApi({this.responseData, this.error});

  final Object? responseData;
  final Object? error;
  final List<_Call> calls = [];

  Future<Response> _resolve(_Call call) async {
    calls.add(call);
    final failure = error;
    if (failure != null) throw failure;
    return _response(responseData);
  }

  @override
  Future<Response> createClassroom(Map<String, dynamic> data) =>
      _resolve(_Call('POST', '/classrooms', data));

  @override
  Future<Response> updateClassroom(String id, Map<String, dynamic> data) =>
      _resolve(_Call('PATCH', '/classrooms/$id', data));

  @override
  Future<Response> deleteClassroom(String id) =>
      _resolve(_Call('DELETE', '/classrooms/$id', null));

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
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getClassroomFilters() => Future.error(UnimplementedError());

  @override
  Future<Response> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());
}

const _fullPayload = <String, dynamic>{
  'name': 'A2 A',
  'description': 'Curso A2',
  'status': 'active',
  'shift': 'Mañana',
  'day': 'Lunes',
  'hour': '08:00',
  'room': 'Sala 1',
  'year': '2026',
  'branch': 'Reconquista',
  'level': 'A2',
  'grade': '1',
  'book': 'Libro 1',
  'commission': 'A',
  'course_days': '3',
  'period_1_days': '2',
  'period_2_days': '2',
  'period_3_days': '3',
  'is_archivated': false,
};

void main() {
  group('ClassroomApi actions', () {
    test('posts the payload to /classrooms', () async {
      final client = _RecordingApiClient(responseData: _classroomBody());
      final api = ClassroomApi(client);

      await api.createClassroom(_fullPayload);

      expect(client.calls, hasLength(1));
      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/classrooms');
      expect(client.calls.single.data, _fullPayload);
    });

    test('patches the payload to /classrooms/{id}', () async {
      final client = _RecordingApiClient(responseData: _classroomBody());
      final api = ClassroomApi(client);

      await api.updateClassroom('c1', {'name': 'A2 B'});

      expect(client.calls.single.method, 'PATCH');
      expect(client.calls.single.path, '/classrooms/c1');
      expect(client.calls.single.data, {'name': 'A2 B'});
    });

    test('deletes /classrooms/{id}', () async {
      final client = _RecordingApiClient();
      final api = ClassroomApi(client);

      await api.deleteClassroom('c1');

      expect(client.calls.single.method, 'DELETE');
      expect(client.calls.single.path, '/classrooms/c1');
    });
  });

  group('ClassroomRepository actions', () {
    test('creates a classroom with the full flat payload and parses the model',
        () async {
      final api = _FakeClassroomApi(
        responseData: _classroomBody(name: 'A2 A'),
      );
      final repository = ClassroomRepository(api);

      final classroom = await repository.createClassroom(
        name: 'A2 A',
        description: 'Curso A2',
        status: 'active',
        shift: 'Mañana',
        day: 'Lunes',
        hour: '08:00',
        room: 'Sala 1',
        year: '2026',
        branch: 'Reconquista',
        level: 'A2',
        grade: '1',
        book: 'Libro 1',
        commission: 'A',
        courseDays: '3',
        period1Days: '2',
        period2Days: '2',
        period3Days: '3',
      );

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/classrooms');
      expect(api.calls.single.data, _fullPayload);
      expect(classroom.id, 'c1');
      expect(classroom.name, 'A2 A');
    });

    test('updates a classroom with the full flat payload and parses the model',
        () async {
      final api = _FakeClassroomApi(
        responseData: _classroomBody(name: 'A2 B', isArchived: true),
      );
      final repository = ClassroomRepository(api);

      final classroom = await repository.updateClassroom(
        'c1',
        name: 'A2 B',
        description: 'Curso A2',
        status: 'archived',
        shift: 'Mañana',
        day: 'Lunes',
        hour: '08:00',
        room: 'Sala 1',
        year: '2026',
        branch: 'Reconquista',
        level: 'A2',
        grade: '1',
        book: 'Libro 1',
        commission: 'A',
        courseDays: '3',
        period1Days: '2',
        period2Days: '2',
        period3Days: '3',
        isArchived: true,
      );

      expect(api.calls.single.method, 'PATCH');
      expect(api.calls.single.path, '/classrooms/c1');
      expect(api.calls.single.data, {
        ..._fullPayload,
        'name': 'A2 B',
        'status': 'archived',
        'is_archivated': true,
      });
      expect(classroom.id, 'c1');
      expect(classroom.name, 'A2 B');
      expect(classroom.isArchived, isTrue);
    });

    test('clearing optional fields sends every key as an empty string',
        () async {
      final api = _FakeClassroomApi(responseData: _classroomBody());
      final repository = ClassroomRepository(api);

      await repository.updateClassroom('c1', name: 'A2 A');

      expect(api.calls.single.method, 'PATCH');
      expect(api.calls.single.path, '/classrooms/c1');
      expect(api.calls.single.data, {
        'name': 'A2 A',
        'description': '',
        'status': 'active',
        'shift': '',
        'day': '',
        'hour': '',
        'room': '',
        'year': '',
        'branch': '',
        'level': '',
        'grade': '',
        'book': '',
        'commission': '',
        'course_days': '',
        'period_1_days': '',
        'period_2_days': '',
        'period_3_days': '',
        'is_archivated': false,
      });
    });

    test('deletes a classroom', () async {
      final api = _FakeClassroomApi(responseData: {'data': null});
      final repository = ClassroomRepository(api);

      await repository.deleteClassroom('c1');

      expect(api.calls.single.method, 'DELETE');
      expect(api.calls.single.path, '/classrooms/c1');
    });

    test('propagates the 422 ValidationException when creating', () async {
      final repository = ClassroomRepository(
        _FakeClassroomApi(error: _validationError()),
      );

      await expectLater(
        repository.createClassroom(name: 'A2 A'),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.fieldErrors['name'], 'name error', isNotNull),
        ),
      );
    });

    test('propagates the 422 ValidationException when updating', () async {
      final repository = ClassroomRepository(
        _FakeClassroomApi(error: _validationError()),
      );

      await expectLater(
        repository.updateClassroom('c1', name: 'A2 B'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ClassroomModel archive parsing', () {
    test('parses is_archivated into isArchived and keeps isActive derivation',
        () {
      final model = ClassroomModel.fromJson(_classroomBody(isArchived: true));

      expect(model.isArchived, isTrue);
      expect(model.isActive, isFalse);
    });

    test('defaults isArchived to false when the attribute is missing', () {
      final model = ClassroomModel.fromJson({
        'data': {
          'type': 'classrooms',
          'id': 'c1',
          'attributes': {'name': 'A2 A'},
        },
      });

      expect(model.isArchived, isFalse);
      expect(model.isActive, isTrue);
    });
  });
}
