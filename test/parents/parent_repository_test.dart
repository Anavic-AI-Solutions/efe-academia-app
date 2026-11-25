import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/parents/data/parent_api.dart';
import 'package:efe_mobile/features/parents/data/parent_repository.dart';
import 'package:efe_mobile/features/parents/domain/parent_model.dart';
import 'package:efe_mobile/features/parents/providers/parent_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data, {int statusCode = 200}) => Response(
      requestOptions: RequestOptions(path: '/parents'),
      statusCode: statusCode,
      data: data,
    );

Map<String, dynamic> _parentBody({
  String id = 'p1',
  String fullname = 'María López',
  String email = 'maria@example.com',
  String status = 'approved',
  String currentStudentId = 's1',
  List<Map<String, dynamic>> students = const [
    {'type': 'students', 'id': 's1'},
    {'type': 'students', 'id': 's2'},
  ],
  List<Map<String, dynamic>>? media = const [
    {
      'collection_name': 'front_dni',
      'file_name': 'dni.jpg',
      'mime_type': 'image/jpeg',
      'url': 'https://example.com/dni.jpg',
    },
  ],
  bool nested = true,
}) {
  final resource = {
    'type': 'parent_data',
    'id': id,
    'attributes': {
      'fullname': fullname,
      'email': email,
      'phone': '3411234567',
      'address': 'Calle 1',
      'identity_number': '30111222',
      'status': status,
      'current_student_id': currentStudentId,
      if (media != null) 'media': media,
    },
    'relationships': {
      'students': {'data': students},
    },
  };
  return nested ? {'data': resource} : resource;
}

Map<String, dynamic> _studentBody({
  String id = 's1',
  String fullname = 'Ana Gómez',
  List<Map<String, dynamic>> classrooms = const [
    {'type': 'classrooms', 'id': 'c1'},
  ],
}) {
  return {
    'type': 'student_data',
    'id': id,
    'attributes': {
      'fullname': fullname,
      'email': 'ana@example.com',
      'year': '2026',
      'status': 'active',
      'identity_number': '99887766',
      'branch': 'Reconquista',
    },
    'relationships': {
      'classrooms': {'data': classrooms},
    },
  };
}

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  String? cursor,
  bool hasMore = false,
  int? total,
}) {
  return {
    'data': items,
    'meta': {
      'cursor': cursor,
      'has_more': hasMore,
      if (total != null) 'total': total,
    },
  };
}

DioException _validationError() => DioException(
      requestOptions: RequestOptions(path: '/parents'),
      response: Response(
        requestOptions: RequestOptions(path: '/parents'),
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

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(_Call('GET', path, queryParameters));
    return _response(responseData);
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
    return _response(responseData);
  }

  @override
  Future<Response> patch(String path, {dynamic data}) async {
    calls.add(_Call('PATCH', path, data));
    return _response(responseData);
  }

  @override
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(_Call('DELETE', path, queryParameters));
    return _response(responseData);
  }

  @override
  Future<Response> upload(
    String path,
    FormData data, {
    Options? options,
  }) async {
    calls.add(_Call('UPLOAD', path, data));
    return _response(responseData);
  }
}

class _FakeParentApi implements ParentApi {
  _FakeParentApi({this.responseData, this.error, this.studentPages});

  final Object? responseData;
  final Object? error;
  final Map<String?, Map<String, dynamic>>? studentPages;
  final List<_Call> calls = [];
  final List<String?> studentCursors = [];

  Future<Response> _resolve(_Call call, {Object? data}) async {
    calls.add(call);
    final failure = error;
    if (failure != null) throw failure;
    return _response(data ?? responseData);
  }

  @override
  Future<Response> getParents({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _resolve(
        _Call('GET', '/parents', {
          'search': search,
          'cursor': cursor,
          'limit': limit,
        }),
      );

  @override
  Future<Response> getParent(String id) =>
      _resolve(_Call('GET', '/parents/$id', null));

  @override
  Future<Response> createParent(Map<String, dynamic> data) =>
      _resolve(_Call('POST', '/parents', data));

  @override
  Future<Response> updateParent(String id, Map<String, dynamic> data) =>
      _resolve(_Call('PATCH', '/parents/$id', data));

  @override
  Future<Response> deleteParent(String id) =>
      _resolve(_Call('DELETE', '/parents/$id', null));

  @override
  Future<Response> getParentStudents(
    String parentId, {
    String? cursor,
    int limit = 20,
  }) {
    studentCursors.add(cursor);
    return _resolve(
      _Call('GET', '/parents/$parentId/students', {
        'cursor': cursor,
        'limit': limit,
      }),
      data: studentPages?[cursor] ?? _page(const []),
    );
  }

  @override
  Future<Response> linkStudent(String parentId, String studentId) => _resolve(
        _Call('POST', '/parents/$parentId/link-student', {
          'student_id': studentId,
        }),
      );

  @override
  Future<Response> unlinkStudent(String parentId, String studentId) =>
      _resolve(
        _Call(
          'DELETE',
          '/parents/$parentId/unlink-student/$studentId',
          null,
        ),
      );
}

class _FakeParentRepository implements ParentRepository {
  CursorPagination<ParentModel> listResult =
      CursorPagination<ParentModel>(data: const [], hasMore: false);
  ParentModel? detailResult;
  List<StudentModel> studentsResult = const [];
  Object? error;
  final List<Map<String, String?>> listCalls = [];
  final List<String> studentsCalls = [];

  @override
  Future<CursorPagination<ParentModel>> getParents({
    String? search,
    String? cursor,
  }) async {
    listCalls.add({'search': search, 'cursor': cursor});
    final failure = error;
    if (failure != null) throw failure;
    return listResult;
  }

  @override
  Future<ParentModel> getParent(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return detailResult ?? ParentModel(id: id);
  }

  @override
  Future<ParentModel> createParent({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String status = 'pending',
  }) =>
      throw UnimplementedError();

  @override
  Future<ParentModel> updateParent(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    required String status,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteParent(String id) => throw UnimplementedError();

  @override
  Future<List<StudentModel>> getParentStudents(String parentId) async {
    studentsCalls.add(parentId);
    final failure = error;
    if (failure != null) throw failure;
    return studentsResult;
  }

  @override
  Future<void> linkStudent(String parentId, String studentId) =>
      throw UnimplementedError();

  @override
  Future<void> unlinkStudent(String parentId, String studentId) =>
      throw UnimplementedError();
}

void main() {
  group('ParentApi', () {
    test('forwards search, cursor and per_page to /parents', () async {
      final client = _RecordingApiClient(responseData: _parentBody());
      final api = ParentApi(client);

      await api.getParents(search: 'María', cursor: 'c2', limit: 12);

      expect(client.calls, hasLength(1));
      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/parents');
      expect(client.calls.single.data, {
        'search': 'María',
        'cursor': 'c2',
        'per_page': 12,
      });
    });

    test('omits an empty search and a null cursor from the query', () async {
      final client = _RecordingApiClient(responseData: _parentBody());
      final api = ParentApi(client);

      await api.getParents(search: '', cursor: null);

      expect(client.calls.single.data, {'per_page': 20});
    });

    test('gets a single parent from /parents/{id}', () async {
      final client = _RecordingApiClient(responseData: _parentBody());
      final api = ParentApi(client);

      await api.getParent('p1');

      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/parents/p1');
    });

    test('posts to /parents', () async {
      final client = _RecordingApiClient(responseData: _parentBody());
      final api = ParentApi(client);

      await api.createParent({'fullname': 'María López'});

      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/parents');
      expect(client.calls.single.data, {'fullname': 'María López'});
    });

    test('patches /parents/{id}', () async {
      final client = _RecordingApiClient(responseData: _parentBody());
      final api = ParentApi(client);

      await api.updateParent('p1', {'status': 'approved'});

      expect(client.calls.single.method, 'PATCH');
      expect(client.calls.single.path, '/parents/p1');
      expect(client.calls.single.data, {'status': 'approved'});
    });

    test('deletes /parents/{id}', () async {
      final client = _RecordingApiClient(responseData: {'data': null});
      final api = ParentApi(client);

      await api.deleteParent('p1');

      expect(client.calls.single.method, 'DELETE');
      expect(client.calls.single.path, '/parents/p1');
    });

    test('gets linked students with cursor and per_page', () async {
      final client = _RecordingApiClient(
        responseData: _page([_studentBody()]),
      );
      final api = ParentApi(client);

      await api.getParentStudents('p1', cursor: 'c9', limit: 50);

      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/parents/p1/students');
      expect(client.calls.single.data, {'cursor': 'c9', 'per_page': 50});
    });

    test('omits a null cursor when fetching linked students', () async {
      final client = _RecordingApiClient(
        responseData: _page([_studentBody()]),
      );
      final api = ParentApi(client);

      await api.getParentStudents('p1');

      expect(client.calls.single.data, {'per_page': 20});
    });

    test('links a student with the student_id payload', () async {
      final client = _RecordingApiClient(responseData: {'data': null});
      final api = ParentApi(client);

      await api.linkStudent('p1', 's1');

      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/parents/p1/link-student');
      expect(client.calls.single.data, {'student_id': 's1'});
    });

    test('unlinks a student from the nested url', () async {
      final client = _RecordingApiClient(responseData: null);
      final api = ParentApi(client);

      await api.unlinkStudent('p1', 's1');

      expect(client.calls.single.method, 'DELETE');
      expect(client.calls.single.path, '/parents/p1/unlink-student/s1');
    });
  });

  group('ParentRepository list', () {
    test('parses parents, students, media and the cursor meta', () async {
      final api = _FakeParentApi(
        responseData: _page(
          [
            _parentBody(nested: false),
            _parentBody(
              id: 'p2',
              fullname: 'Carlos Ruiz',
              status: 'pending',
              currentStudentId: 's3',
              students: [
                {'type': 'students', 'id': 's3'},
              ],
              media: null,
              nested: false,
            ),
          ],
          cursor: 'c2',
          hasMore: true,
          total: 7,
        ),
      );
      final repository = ParentRepository(api);

      final result = await repository.getParents();

      expect(result.data, hasLength(2));
      final first = result.data.first;
      expect(first.id, 'p1');
      expect(first.fullname, 'María López');
      expect(first.email, 'maria@example.com');
      expect(first.phone, '3411234567');
      expect(first.address, 'Calle 1');
      expect(first.identityNumber, '30111222');
      expect(first.status, 'approved');
      expect(first.currentStudentId, 's1');
      expect(first.studentIds, ['s1', 's2']);
      expect(first.studentCount, 2);
      expect(first.media.single.fileName, 'dni.jpg');
      expect(first.media.single.url, 'https://example.com/dni.jpg');
      expect(first.media.single.mimeType, 'image/jpeg');
      expect(first.media.single.collectionName, 'front_dni');

      final second = result.data.last;
      expect(second.status, 'pending');
      expect(second.currentStudentId, 's3');
      expect(second.studentIds, ['s3']);
      expect(second.studentCount, 1);
      expect(second.media, isEmpty);

      expect(result.nextCursor, 'c2');
      expect(result.hasMore, isTrue);
      expect(result.total, 7);
    });

    test('defaults student ids, count and media when absent', () async {
      final body = _parentBody(nested: false)
        ..remove('relationships')
        ..['attributes'] = {
          'fullname': 'Sin hijos',
          'email': 'sin@example.com',
          'identity_number': '1',
          'status': 'pending',
        };
      final repository = ParentRepository(
        _FakeParentApi(
          responseData: _page([body]),
        ),
      );

      final result = await repository.getParents();

      expect(result.data.single.studentIds, isEmpty);
      expect(result.data.single.studentCount, 0);
      expect(result.data.single.media, isEmpty);
      expect(result.data.single.currentStudentId, '');
      expect(result.nextCursor, isNull);
      expect(result.hasMore, isFalse);
      expect(result.total, isNull);
    });

    test('forwards search and cursor to the api', () async {
      final api = _FakeParentApi(
        responseData: _page(const []),
      );
      final repository = ParentRepository(api);

      await repository.getParents(search: 'María', cursor: 'c2');

      expect(api.calls.single.data, {
        'search': 'María',
        'cursor': 'c2',
        'limit': 20,
      });
    });

    test('propagates an API failure as an ApiException', () async {
      final repository = ParentRepository(
        _FakeParentApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/parents'),
            response: Response(
              requestOptions: RequestOptions(path: '/parents'),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      await expectLater(
        repository.getParents(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('ParentRepository detail', () {
    test('parses the detail resource and counts linked students', () async {
      final api = _FakeParentApi(
        responseData: _parentBody(
          nested: false,
          students: [
            {'type': 'students', 'id': 's1'},
            {'type': 'students', 'id': 's2'},
            {'type': 'students', 'id': 's3'},
          ],
        ),
      );
      final repository = ParentRepository(api);

      final parent = await repository.getParent('p1');

      expect(api.calls.single.method, 'GET');
      expect(api.calls.single.path, '/parents/p1');
      expect(parent.id, 'p1');
      expect(parent.fullname, 'María López');
      expect(parent.email, 'maria@example.com');
      expect(parent.studentIds, ['s1', 's2', 's3']);
      expect(parent.studentCount, 3);
      expect(parent.status, 'approved');
    });

    test('parses a wrapped create response', () {
      final parent = ParentModel.fromJson(_parentBody());

      expect(parent.id, 'p1');
      expect(parent.identityNumber, '30111222');
      expect(parent.currentStudentId, 's1');
      expect(parent.studentCount, 2);
      expect(parent.media, hasLength(1));
    });
  });

  group('ParentRepository mutations', () {
    test('creates a parent with the flat payload and parses the model',
        () async {
      final api = _FakeParentApi(
        responseData: _parentBody(fullname: 'María Nueva'),
      );
      final repository = ParentRepository(api);

      final parent = await repository.createParent(
        fullname: 'María Nueva',
        email: 'maria@example.com',
        phone: '3411234567',
        address: 'Calle 1',
        identityNumber: '30111222',
        status: 'pending',
      );

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/parents');
      expect(api.calls.single.data, {
        'fullname': 'María Nueva',
        'email': 'maria@example.com',
        'phone': '3411234567',
        'address': 'Calle 1',
        'identity_number': '30111222',
        'status': 'pending',
      });
      expect(parent.id, 'p1');
      expect(parent.fullname, 'María Nueva');
    });

    test('creates with pending status and omits empty optional fields',
        () async {
      final api = _FakeParentApi(responseData: _parentBody());
      final repository = ParentRepository(api);

      await repository.createParent(
        fullname: 'María Nueva',
        email: 'maria@example.com',
        phone: '',
        address: '   ',
        identityNumber: '30111222',
      );

      expect(api.calls.single.data, {
        'fullname': 'María Nueva',
        'email': 'maria@example.com',
        'identity_number': '30111222',
        'status': 'pending',
      });
    });

    test('updates a parent with the flat payload and parses the model',
        () async {
      final api = _FakeParentApi(
        responseData: _parentBody(fullname: 'María Editada'),
      );
      final repository = ParentRepository(api);

      final parent = await repository.updateParent(
        'p1',
        fullname: 'María Editada',
        email: 'maria@example.com',
        phone: '3411234567',
        address: 'Calle 2',
        identityNumber: '30111222',
        status: 'approved',
      );

      expect(api.calls.single.method, 'PATCH');
      expect(api.calls.single.path, '/parents/p1');
      expect(api.calls.single.data, {
        'fullname': 'María Editada',
        'email': 'maria@example.com',
        'phone': '3411234567',
        'address': 'Calle 2',
        'identity_number': '30111222',
        'status': 'approved',
      });
      expect(parent.fullname, 'María Editada');
    });

    test('sends every optional field when updating so empties clear it',
        () async {
      final api = _FakeParentApi(responseData: _parentBody());
      final repository = ParentRepository(api);

      await repository.updateParent(
        'p1',
        fullname: 'María Editada',
        email: 'maria@example.com',
        identityNumber: '30111222',
        status: 'rejected',
        phone: '',
        address: '   ',
      );

      expect(api.calls.single.data, {
        'fullname': 'María Editada',
        'email': 'maria@example.com',
        'phone': '',
        'address': '',
        'identity_number': '30111222',
        'status': 'rejected',
      });
    });

    test('deletes a parent', () async {
      final api = _FakeParentApi(responseData: null);
      final repository = ParentRepository(api);

      await repository.deleteParent('p1');

      expect(api.calls.single.method, 'DELETE');
      expect(api.calls.single.path, '/parents/p1');
    });

    test('propagates the 422 ValidationException when creating', () async {
      final repository = ParentRepository(
        _FakeParentApi(error: _validationError()),
      );

      await expectLater(
        repository.createParent(
          fullname: 'María Nueva',
          email: 'maria@example.com',
          identityNumber: '30111222',
        ),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.fieldErrors['email'], 'email error', isNotNull),
        ),
      );
    });

    test('propagates the 422 ValidationException when updating', () async {
      final repository = ParentRepository(
        _FakeParentApi(error: _validationError()),
      );

      await expectLater(
        repository.updateParent(
          'p1',
          fullname: 'María Editada',
          email: 'maria@example.com',
          identityNumber: '30111222',
          status: 'pending',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ParentRepository linked students', () {
    test('follows cursors until the last page', () async {
      final api = _FakeParentApi(
        studentPages: {
          null: _page(
            [_studentBody(id: 's1', fullname: 'Ana')],
            cursor: 'c2',
            hasMore: true,
            total: 2,
          ),
          'c2': _page(
            [_studentBody(id: 's2', fullname: 'Bruno')],
            hasMore: false,
            total: 2,
          ),
        },
      );
      final repository = ParentRepository(api);

      final students = await repository.getParentStudents('p1');

      expect(students.map((s) => s.id), ['s1', 's2']);
      expect(students.first.fullname, 'Ana');
      expect(students.first.classroomCount, 1);
      expect(api.studentCursors, [null, 'c2']);
      expect(api.calls, hasLength(2));
      expect(
        api.calls.every((c) => c.path == '/parents/p1/students'),
        isTrue,
      );
    });

    test('stops after five pages even when the backend keeps paging',
        () async {
      final api = _FakeParentApi(
        studentPages: {
          null: _page(
            [_studentBody(id: 's1')],
            cursor: 'c1',
            hasMore: true,
          ),
          'c1': _page(
            [_studentBody(id: 's2')],
            cursor: 'c2',
            hasMore: true,
          ),
          'c2': _page(
            [_studentBody(id: 's3')],
            cursor: 'c3',
            hasMore: true,
          ),
          'c3': _page(
            [_studentBody(id: 's4')],
            cursor: 'c4',
            hasMore: true,
          ),
          'c4': _page(
            [_studentBody(id: 's5')],
            cursor: 'c5',
            hasMore: true,
          ),
          'c5': _page(
            [_studentBody(id: 's6')],
            hasMore: false,
          ),
        },
      );
      final repository = ParentRepository(api);

      final students = await repository.getParentStudents('p1');

      expect(students.map((s) => s.id), ['s1', 's2', 's3', 's4', 's5']);
      expect(api.studentCursors, [null, 'c1', 'c2', 'c3', 'c4']);
    });

    test('stops when the backend repeats the same cursor', () async {
      final api = _FakeParentApi(
        studentPages: {
          null: _page(
            [_studentBody(id: 's1')],
            cursor: 'c2',
            hasMore: true,
          ),
          'c2': _page(
            [_studentBody(id: 's2')],
            cursor: 'c2',
            hasMore: true,
          ),
        },
      );
      final repository = ParentRepository(api);

      final students = await repository.getParentStudents('p1');

      expect(students.map((s) => s.id), ['s1', 's2']);
      expect(api.studentCursors, [null, 'c2']);
    });

    test('propagates a failure from the students endpoint', () async {
      final repository = ParentRepository(
        _FakeParentApi(error: _validationError()),
      );

      await expectLater(
        repository.getParentStudents('p1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ParentRepository links', () {
    test('links a student to the parent', () async {
      final api = _FakeParentApi(responseData: {'data': null});
      final repository = ParentRepository(api);

      await repository.linkStudent('p1', 's1');

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/parents/p1/link-student');
      expect(api.calls.single.data, {'student_id': 's1'});
    });

    test('unlinks a student from the parent', () async {
      final api = _FakeParentApi(responseData: null);
      final repository = ParentRepository(api);

      await repository.unlinkStudent('p1', 's1');

      expect(api.calls.single.method, 'DELETE');
      expect(api.calls.single.path, '/parents/p1/unlink-student/s1');
    });

    test('propagates a 422 when linking', () async {
      final repository = ParentRepository(
        _FakeParentApi(error: _validationError()),
      );

      await expectLater(
        repository.linkStudent('p1', 's1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Parent providers', () {
    test('parentListProvider loads the first page and searches', () async {
      final repository = _FakeParentRepository()
        ..listResult = CursorPagination<ParentModel>(
          data: [
            const ParentModel(
              id: 'p1',
              fullname: 'María López',
              studentCount: 2,
            ),
          ],
          nextCursor: 'c2',
          hasMore: true,
          total: 9,
        );
      final container = ProviderContainer(
        overrides: [parentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(parentListProvider);
      await pumpEventQueue();

      expect(repository.listCalls.single, {'search': '', 'cursor': null});
      expect(container.read(parentListProvider).data.single.id, 'p1');
      expect(container.read(parentListProvider).hasMore, isTrue);

      await container.read(parentListProvider.notifier).setSearch('María');

      expect(repository.listCalls.last, {'search': 'María', 'cursor': null});
      expect(container.read(parentListProvider).search, 'María');
    });

    test('parentDetailProvider fetches the parent by id', () async {
      final repository = _FakeParentRepository()
        ..detailResult = const ParentModel(
          id: 'p1',
          fullname: 'María López',
        );
      final container = ProviderContainer(
        overrides: [parentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final parent = await container.read(parentDetailProvider('p1').future);

      expect(parent.id, 'p1');
      expect(parent.fullname, 'María López');
    });

    test('parentStudentsProvider fetches the linked students', () async {
      final repository = _FakeParentRepository()
        ..studentsResult = const [
          StudentModel(id: 's1', fullname: 'Ana Gómez'),
        ];
      final container = ProviderContainer(
        overrides: [parentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final students =
          await container.read(parentStudentsProvider('p1').future);

      expect(students.single.id, 's1');
      expect(repository.studentsCalls, ['p1']);
    });
  });
}
