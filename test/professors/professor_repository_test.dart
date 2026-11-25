import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/professors/data/professor_api.dart';
import 'package:efe_mobile/features/professors/data/professor_repository.dart';
import 'package:efe_mobile/features/professors/providers/professor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data, {int statusCode = 200}) => Response(
      requestOptions: RequestOptions(path: '/professors'),
      statusCode: statusCode,
      data: data,
    );

Map<String, dynamic> _professorBody({
  String id = 'p1',
  String fullname = 'Ana Pérez',
  String email = 'ana@example.com',
  List<Map<String, dynamic>> classrooms = const [],
  bool nested = true,
}) {
  final resource = {
    'type': 'professor_data',
    'id': id,
    'attributes': {
      'fullname': fullname,
      'email': email,
      'phone': '3411234567',
      'address': 'Calle 1',
      'identity_number': '30111222',
      'bio': 'Profesora de matemática',
      'specialty': 'Matemática',
    },
    'relationships': {
      'classrooms': {'data': classrooms},
    },
  };
  return nested ? {'data': resource} : resource;
}

DioException _validationError() => DioException(
      requestOptions: RequestOptions(path: '/professors'),
      response: Response(
        requestOptions: RequestOptions(path: '/professors'),
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

class _FakeProfessorApi implements ProfessorApi {
  _FakeProfessorApi({this.responseData, this.error});

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
  Future<Response> getProfessors({
    String? search,
    String? cursor,
    int limit = 20,
  }) =>
      _resolve(
        _Call('GET', '/professors', {
          'search': search,
          'cursor': cursor,
          'limit': limit,
        }),
      );

  @override
  Future<Response> getProfessor(String id) =>
      _resolve(_Call('GET', '/professors/$id', null));

  @override
  Future<Response> createProfessor(Map<String, dynamic> data) =>
      _resolve(_Call('POST', '/professors', data));

  @override
  Future<Response> updateProfessor(String id, Map<String, dynamic> data) =>
      _resolve(_Call('PATCH', '/professors/$id', data));

  @override
  Future<Response> deleteProfessor(String id) =>
      _resolve(_Call('DELETE', '/professors/$id', null));
}

class _FakeProfessorRepository implements ProfessorRepository {
  CursorPagination<ProfessorModel> listResult =
      CursorPagination<ProfessorModel>(data: const [], hasMore: false);
  ProfessorModel? detailResult;
  Object? error;
  final List<Map<String, String?>> listCalls = [];

  @override
  Future<CursorPagination<ProfessorModel>> getProfessors({
    String? search,
    String? cursor,
  }) async {
    listCalls.add({'search': search, 'cursor': cursor});
    final failure = error;
    if (failure != null) throw failure;
    return listResult;
  }

  @override
  Future<ProfessorModel> getProfessor(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return detailResult ?? ProfessorModel(id: id);
  }

  @override
  Future<ProfessorModel> createProfessor({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) =>
      throw UnimplementedError();

  @override
  Future<ProfessorModel> updateProfessor(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProfessor(String id) => throw UnimplementedError();
}

void main() {
  group('ProfessorApi', () {
    test('forwards search, cursor and per_page to /professors', () async {
      final client = _RecordingApiClient(responseData: _professorBody());
      final api = ProfessorApi(client);

      await api.getProfessors(search: 'Ana', cursor: 'c2', limit: 12);

      expect(client.calls, hasLength(1));
      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/professors');
      expect(client.calls.single.data, {
        'search': 'Ana',
        'cursor': 'c2',
        'per_page': 12,
      });
    });

    test('omits an empty search and a null cursor from the query', () async {
      final client = _RecordingApiClient(responseData: _professorBody());
      final api = ProfessorApi(client);

      await api.getProfessors(search: '', cursor: null);

      expect(client.calls.single.data, {'per_page': 20});
    });

    test('gets a single professor from /professors/{id}', () async {
      final client = _RecordingApiClient(responseData: _professorBody());
      final api = ProfessorApi(client);

      await api.getProfessor('p1');

      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/professors/p1');
    });

    test('posts to /professors', () async {
      final client = _RecordingApiClient(responseData: _professorBody());
      final api = ProfessorApi(client);

      await api.createProfessor({'fullname': 'Ana Pérez'});

      expect(client.calls.single.method, 'POST');
      expect(client.calls.single.path, '/professors');
      expect(client.calls.single.data, {'fullname': 'Ana Pérez'});
    });

    test('patches /professors/{id}', () async {
      final client = _RecordingApiClient(responseData: _professorBody());
      final api = ProfessorApi(client);

      await api.updateProfessor('p1', {'specialty': 'Matemática'});

      expect(client.calls.single.method, 'PATCH');
      expect(client.calls.single.path, '/professors/p1');
      expect(client.calls.single.data, {'specialty': 'Matemática'});
    });

    test('deletes /professors/{id}', () async {
      final client = _RecordingApiClient(responseData: {'data': null});
      final api = ProfessorApi(client);

      await api.deleteProfessor('p1');

      expect(client.calls.single.method, 'DELETE');
      expect(client.calls.single.path, '/professors/p1');
    });
  });

  group('ProfessorRepository list', () {
    test('parses professors and the cursor meta', () async {
      final api = _FakeProfessorApi(
        responseData: {
          'data': [
            _professorBody(
              id: 'p1',
              fullname: 'Ana Pérez',
              classrooms: [
                {'type': 'classrooms', 'id': 'c1'},
                {'type': 'classrooms', 'id': 'c2'},
              ],
              nested: false,
            ),
            _professorBody(
              id: 'p2',
              fullname: 'Bruno Díaz',
              classrooms: [
                {'type': 'classrooms', 'id': 'c3'},
              ],
              nested: false,
            ),
          ],
          'meta': {'cursor': 'c2', 'has_more': true, 'total': 7},
        },
      );
      final repository = ProfessorRepository(api);

      final result = await repository.getProfessors();

      expect(result.data, hasLength(2));
      expect(result.data.first.id, 'p1');
      expect(result.data.first.fullname, 'Ana Pérez');
      expect(result.data.first.specialty, 'Matemática');
      expect(result.data.first.classroomCount, 2);
      expect(result.data.last.classroomCount, 1);
      expect(result.nextCursor, 'c2');
      expect(result.hasMore, isTrue);
      expect(result.total, 7);
    });

    test('defaults classroomCount to zero without relationships', () async {
      final repository = ProfessorRepository(
        _FakeProfessorApi(
          responseData: {
            'data': [
              _professorBody(nested: false)..remove('relationships'),
            ],
            'meta': {'has_more': false},
          },
        ),
      );

      final result = await repository.getProfessors();

      expect(result.data.single.classroomCount, 0);
      expect(result.nextCursor, isNull);
      expect(result.hasMore, isFalse);
      expect(result.total, isNull);
    });

    test('forwards search and cursor to the api', () async {
      final api = _FakeProfessorApi(
        responseData: {
          'data': [],
          'meta': {'has_more': false}
        },
      );
      final repository = ProfessorRepository(api);

      await repository.getProfessors(search: 'Ana', cursor: 'c2');

      expect(api.calls.single.data, {
        'search': 'Ana',
        'cursor': 'c2',
        'limit': 20,
      });
    });

    test('propagates a API failure as an ApiException', () async {
      final repository = ProfessorRepository(
        _FakeProfessorApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/professors'),
            response: Response(
              requestOptions: RequestOptions(path: '/professors'),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      await expectLater(
        repository.getProfessors(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('ProfessorRepository detail', () {
    test('parses the detail resource and its classroom count', () async {
      final api = _FakeProfessorApi(
        responseData: _professorBody(
          fullname: 'Ana Pérez',
          classrooms: [
            {'type': 'classrooms', 'id': 'c1'},
          ],
        ),
      );
      final repository = ProfessorRepository(api);

      final professor = await repository.getProfessor('p1');

      expect(api.calls.single.method, 'GET');
      expect(api.calls.single.path, '/professors/p1');
      expect(professor.id, 'p1');
      expect(professor.fullname, 'Ana Pérez');
      expect(professor.email, 'ana@example.com');
      expect(professor.phone, '3411234567');
      expect(professor.address, 'Calle 1');
      expect(professor.identityNumber, '30111222');
      expect(professor.bio, 'Profesora de matemática');
      expect(professor.specialty, 'Matemática');
      expect(professor.classroomCount, 1);
    });
  });

  group('ProfessorRepository mutations', () {
    test('creates a professor with the flat payload and parses the model',
        () async {
      final api = _FakeProfessorApi(
        responseData: _professorBody(fullname: 'Ana Nueva'),
      );
      final repository = ProfessorRepository(api);

      final professor = await repository.createProfessor(
        fullname: 'Ana Nueva',
        email: 'ana@example.com',
        phone: '3411234567',
        address: 'Calle 1',
        identityNumber: '30111222',
        bio: 'Bio',
        specialty: 'Matemática',
      );

      expect(api.calls.single.method, 'POST');
      expect(api.calls.single.path, '/professors');
      expect(api.calls.single.data, {
        'fullname': 'Ana Nueva',
        'email': 'ana@example.com',
        'phone': '3411234567',
        'address': 'Calle 1',
        'identity_number': '30111222',
        'bio': 'Bio',
        'specialty': 'Matemática',
      });
      expect(professor.id, 'p1');
      expect(professor.fullname, 'Ana Nueva');
    });

    test('omits the optional fields that are null or empty when creating',
        () async {
      final api = _FakeProfessorApi(responseData: _professorBody());
      final repository = ProfessorRepository(api);

      await repository.createProfessor(
        fullname: 'Ana Nueva',
        email: 'ana@example.com',
        phone: '',
        address: '   ',
        identityNumber: '30111222',
        bio: null,
        specialty: '',
      );

      expect(api.calls.single.data, {
        'fullname': 'Ana Nueva',
        'email': 'ana@example.com',
        'identity_number': '30111222',
      });
    });

    test('updates a professor with the flat payload and parses the model',
        () async {
      final api = _FakeProfessorApi(
        responseData: _professorBody(fullname: 'Ana Editada'),
      );
      final repository = ProfessorRepository(api);

      final professor = await repository.updateProfessor(
        'p1',
        fullname: 'Ana Editada',
        email: 'ana@example.com',
        phone: '3411234567',
        address: 'Calle 2',
        identityNumber: '30111222',
        bio: 'Nueva bio',
        specialty: 'Física',
      );

      expect(api.calls.single.method, 'PATCH');
      expect(api.calls.single.path, '/professors/p1');
      expect(api.calls.single.data, {
        'fullname': 'Ana Editada',
        'email': 'ana@example.com',
        'phone': '3411234567',
        'address': 'Calle 2',
        'identity_number': '30111222',
        'bio': 'Nueva bio',
        'specialty': 'Física',
      });
      expect(professor.fullname, 'Ana Editada');
    });

    test('sends every optional field when updating so empties clear it',
        () async {
      final api = _FakeProfessorApi(responseData: _professorBody());
      final repository = ProfessorRepository(api);

      await repository.updateProfessor(
        'p1',
        fullname: 'Ana Editada',
        email: 'ana@example.com',
        identityNumber: '30111222',
        phone: '',
        bio: '   ',
      );

      expect(api.calls.single.data, {
        'fullname': 'Ana Editada',
        'email': 'ana@example.com',
        'phone': '',
        'address': '',
        'identity_number': '30111222',
        'bio': '',
        'specialty': '',
      });
    });

    test('deletes a professor', () async {
      final api = _FakeProfessorApi(responseData: {'data': null});
      final repository = ProfessorRepository(api);

      await repository.deleteProfessor('p1');

      expect(api.calls.single.method, 'DELETE');
      expect(api.calls.single.path, '/professors/p1');
    });

    test('propagates the 422 ValidationException when creating', () async {
      final repository = ProfessorRepository(
        _FakeProfessorApi(error: _validationError()),
      );

      await expectLater(
        repository.createProfessor(
          fullname: 'Ana Nueva',
          email: 'ana@example.com',
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
      final repository = ProfessorRepository(
        _FakeProfessorApi(error: _validationError()),
      );

      await expectLater(
        repository.updateProfessor(
          'p1',
          fullname: 'Ana Editada',
          email: 'ana@example.com',
          identityNumber: '30111222',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Professor providers', () {
    test('professorListProvider loads the first page and searches', () async {
      final repository = _FakeProfessorRepository()
        ..listResult = CursorPagination<ProfessorModel>(
          data: [
            const ProfessorModel(
              id: 'p1',
              fullname: 'Ana Pérez',
              classroomCount: 2,
            ),
          ],
          nextCursor: 'c2',
          hasMore: true,
          total: 9,
        );
      final container = ProviderContainer(
        overrides: [professorRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(professorListProvider);
      await pumpEventQueue();

      expect(repository.listCalls.single, {'search': '', 'cursor': null});
      expect(container.read(professorListProvider).data.single.id, 'p1');
      expect(container.read(professorListProvider).hasMore, isTrue);

      await container.read(professorListProvider.notifier).setSearch('Ana');

      expect(repository.listCalls.last, {'search': 'Ana', 'cursor': null});
      expect(container.read(professorListProvider).search, 'Ana');
    });

    test('professorDetailProvider fetches the professor by id', () async {
      final repository = _FakeProfessorRepository()
        ..detailResult = const ProfessorModel(
          id: 'p1',
          fullname: 'Ana Pérez',
        );
      final container = ProviderContainer(
        overrides: [professorRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final professor =
          await container.read(professorDetailProvider('p1').future);

      expect(professor.id, 'p1');
      expect(professor.fullname, 'Ana Pérez');
    });
  });
}
