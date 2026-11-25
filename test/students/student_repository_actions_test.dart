import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/students/data/student_api.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data, {int statusCode = 200}) => Response(
      requestOptions: RequestOptions(path: '/students'),
      statusCode: statusCode,
      data: data,
    );

Map<String, dynamic> _studentBody({
  String id = 's1',
  String fullname = 'Ana Gómez',
  String email = 'ana@example.com',
  String year = '2026',
  String branch = 'Reconquista',
  String identityNumber = '12345678',
}) =>
    {
      'data': {
        'type': 'student_data',
        'id': id,
        'attributes': {
          'fullname': fullname,
          'email': email,
          'year': year,
          'branch': branch,
          'identity_number': identityNumber,
          'status': 'active',
        },
      },
    };

DioException _validationError() => DioException(
      requestOptions: RequestOptions(path: '/students'),
      response: Response(
        requestOptions: RequestOptions(path: '/students'),
        statusCode: 422,
        data: {
          'message': 'The email has already been taken.',
          'errors': {
            'email': ['The email has already been taken.'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
      error: ValidationException(
        fieldErrors: {'email': 'The email has already been taken.'},
        detail: 'The email has already been taken.',
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

class _FakeStudentApi implements StudentApi {
  _FakeStudentApi({this.responseData, this.error});

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
  Future<Response> createStudent(Map<String, dynamic> data) =>
      _resolve(_Call('POST', '/students', data));

  @override
  Future<Response> updateStudent(String id, Map<String, dynamic> data) =>
      _resolve(_Call('PATCH', '/students/$id', data));

  @override
  Future<Response> deactivateStudent(String id) =>
      _resolve(_Call('POST', '/students/$id/deactivate', null));

  @override
  Future<Response> reactivateStudent(String id) =>
      _resolve(_Call('POST', '/students/$id/reactivate', null));

  @override
  Future<Response> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getStudent(String id) => Future.error(UnimplementedError());

  @override
  Future<Response> getClassrooms(String studentId) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getParents(String studentId) =>
      Future.error(UnimplementedError());
}

void main() {
  group('StudentApi actions', () {
    test('posts the payload to /students', () async {
      final client = _RecordingApiClient(responseData: _studentBody());
      final api = StudentApi(client);

      await api.createStudent({
        'fullname': 'Ana Gómez',
        'email': 'ana@example.com',
      });

      expect(client.calls, hasLength(1));
      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/students');
      expect(client.calls.single.data, {
        'fullname': 'Ana Gómez',
        'email': 'ana@example.com',
      });
    });

    test('patches the payload to /students/{id}', () async {
      final client = _RecordingApiClient(responseData: _studentBody());
      final api = StudentApi(client);

      await api.updateStudent('s1', {'fullname': 'Ana Actualizada'});

      expect(client.calls.single.method, 'PATCH');
      expect(client.calls.single.path, '/students/s1');
      expect(client.calls.single.data, {'fullname': 'Ana Actualizada'});
    });

    test('posts to /students/{id}/deactivate', () async {
      final client = _RecordingApiClient();
      final api = StudentApi(client);

      await api.deactivateStudent('s1');

      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/students/s1/deactivate');
      expect(client.calls.single.data, isNull);
    });

    test('posts to /students/{id}/reactivate', () async {
      final client = _RecordingApiClient();
      final api = StudentApi(client);

      await api.reactivateStudent('s1');

      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/students/s1/reactivate');
      expect(client.calls.single.data, isNull);
    });
  });

  group('StudentRepository actions', () {
    test('creates a student with the flat payload and parses the model',
        () async {
      final api = _FakeStudentApi(
        responseData: _studentBody(fullname: 'Ana Nueva'),
      );
      final repository = StudentRepository(api);

      final student = await repository.createStudent(
        fullname: 'Ana Nueva',
        email: 'ana@example.com',
        year: '2026',
        branch: 'Reconquista',
        identityNumber: '12345678',
      );

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/students');
      expect(api.calls.single.data, {
        'fullname': 'Ana Nueva',
        'email': 'ana@example.com',
        'year': '2026',
        'branch': 'Reconquista',
        'identity_number': '12345678',
      });
      expect(student.id, 's1');
      expect(student.fullname, 'Ana Nueva');
    });

    test('updates a student with the flat payload and parses the model',
        () async {
      final api = _FakeStudentApi(responseData: _studentBody());
      final repository = StudentRepository(api);

      final student = await repository.updateStudent(
        's1',
        fullname: 'Ana Editada',
        email: 'ana@example.com',
        year: '2026',
        branch: 'Vera',
        identityNumber: '87654321',
      );

      expect(api.calls.single.method, 'PATCH');
      expect(api.calls.single.path, '/students/s1');
      expect(api.calls.single.data, {
        'fullname': 'Ana Editada',
        'email': 'ana@example.com',
        'year': '2026',
        'branch': 'Vera',
        'identity_number': '87654321',
      });
      expect(student.id, 's1');
    });

    test('deactivates a student', () async {
      final api = _FakeStudentApi(responseData: {'data': null});
      final repository = StudentRepository(api);

      await repository.deactivateStudent('s1');

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/students/s1/deactivate');
    });

    test('reactivates a student', () async {
      final api = _FakeStudentApi(responseData: {'data': null});
      final repository = StudentRepository(api);

      await repository.reactivateStudent('s1');

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/students/s1/reactivate');
    });

    test('propagates the 422 ValidationException when creating', () async {
      final repository = StudentRepository(
        _FakeStudentApi(error: _validationError()),
      );

      await expectLater(
        repository.createStudent(
          fullname: 'Ana Nueva',
          email: 'ana@example.com',
          year: '2026',
          branch: 'Reconquista',
          identityNumber: '12345678',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.fieldErrors['email'], 'email error', isNotNull),
        ),
      );
    });

    test('propagates the 422 ValidationException when updating', () async {
      final repository = StudentRepository(
        _FakeStudentApi(error: _validationError()),
      );

      await expectLater(
        repository.updateStudent(
          's1',
          fullname: 'Ana Editada',
          email: 'ana@example.com',
          year: '2026',
          branch: 'Vera',
          identityNumber: '87654321',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('wraps other Dio errors in ApiException', () async {
      final repository = StudentRepository(
        _FakeStudentApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/students'),
            response: Response(
              requestOptions: RequestOptions(path: '/students'),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      await expectLater(
        repository.deactivateStudent('s1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
