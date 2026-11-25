import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/requests/data/request_api.dart';
import 'package:efe_mobile/features/requests/data/request_repository.dart';
import 'package:efe_mobile/features/requests/domain/request_model.dart';
import 'package:efe_mobile/features/requests/providers/request_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/requests'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _item(
  String id, {
  String kind = 'student',
  String fullname = 'Solicitud',
  String status = 'pending',
  int childrenCount = 0,
}) =>
    {
      'type': '${kind}_request',
      'id': id,
      'attributes': {
        'kind': kind,
        'fullname': fullname,
        'email': '$id@test.com',
        'identity_number': '12345678',
        'status': status,
        'children_count': childrenCount,
      },
    };

class _FakeRequestApi implements RequestApi {
  final List<Map<String, Object?>> calls = [];
  final List<Object?> payloads = [];

  @override
  Future<Response> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add({
      'method': 'getRequests',
      'search': search,
      'status': status,
      'type': type,
      'page': page,
      'perPage': perPage,
    });
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> getStudentRequest(String id) async {
    calls.add({'method': 'getStudentRequest', 'id': id});
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> getParentRequest(String id) async {
    calls.add({'method': 'getParentRequest', 'id': id});
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> approveStudent(String id, String classroomId) async {
    calls.add({
      'method': 'approveStudent',
      'id': id,
      'classroomId': classroomId,
    });
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> rejectStudent(String id) async {
    calls.add({'method': 'rejectStudent', 'id': id});
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> approveParent(String id) async {
    calls.add({'method': 'approveParent', 'id': id});
    return _response(payloads.removeAt(0));
  }

  @override
  Future<Response> rejectParent(String id) async {
    calls.add({'method': 'rejectParent', 'id': id});
    return _response(payloads.removeAt(0));
  }
}

class _FakeRequestRepository implements RequestRepository {
  final List<Map<String, Object?>> calls = [];
  final List<PageResult<RequestModel>> pages;

  _FakeRequestRepository(this.pages);

  @override
  Future<PageResult<RequestModel>> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add({
      'search': search,
      'status': status,
      'type': type,
      'page': page,
      'perPage': perPage,
    });
    return pages.removeAt(0);
  }

  @override
  Future<RequestModel> getRequest(RequestKind kind, String id) =>
      throw UnimplementedError();

  @override
  Future<bool> approve(RequestModel request, {String? classroomId}) =>
      throw UnimplementedError();

  @override
  Future<bool> reject(RequestModel request) => throw UnimplementedError();
}

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
    String? studentId,
  }) async {
    calls.add({
      'search': search,
      'page': page,
      'limit': limit,
    });
    return PageResult(
      data: const [ClassroomModel(id: 'c1', name: 'Inglés 1')],
      page: page,
      perPage: limit,
      total: 1,
    );
  }

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomModel> getClassroom(String id) => throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() => throw UnimplementedError();

  @override
  Future<ClassroomModel> createClassroom({
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomModel> updateClassroom(
    String id, {
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteClassroom(String id) => Future.error(UnimplementedError());
  @override
  Future<ClassroomModel> setArchived(String id, bool isArchived) =>
      Future.error(UnimplementedError());
}

void main() {
  group('RequestRepository', () {
    test('parses a page of student and parent requests', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': [
            _item('s1', fullname: 'Ana'),
            _item('p1', kind: 'parent', fullname: 'María', childrenCount: 2),
          ],
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'per_page': 20,
            'total': 41,
          },
        });
      final repository = RequestRepository(api);

      final result = await repository.getRequests(
        search: 'ana',
        status: 'pending',
        type: 'all',
        page: 2,
      );

      expect(result.data, hasLength(2));
      expect(result.data.first.kind, RequestKind.student);
      expect(result.data.first.fullname, 'Ana');
      expect(result.data.last.kind, RequestKind.parent);
      expect(result.data.last.childrenCount, 2);
      expect(result.total, 41);
      expect(result.totalPages, 3);
      expect(api.calls.single['search'], 'ana');
      expect(api.calls.single['page'], 2);
    });

    test('uses meta.current_page when the backend clamps the page', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 2,
            'per_page': 20,
            'total': 40,
          },
        });
      final repository = RequestRepository(api);

      final result = await repository.getRequests(page: 3);

      expect(result.page, 1);
      expect(result.totalPages, 2);
    });

    test('parses a student detail with media', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': {
            'type': 'student_request',
            'id': 's1',
            'attributes': {
              'kind': 'student',
              'fullname': 'Ana',
              'media': [
                {
                  'collection_name': 'front_dni',
                  'file_name': 'dni.jpg',
                  'mime_type': 'image/jpeg',
                  'url': 'https://example.com/dni.jpg',
                },
              ],
            },
          },
        });
      final repository = RequestRepository(api);

      final request = await repository.getRequest(RequestKind.student, 's1');

      expect(request.kind, RequestKind.student);
      expect(request.media.single.collectionName, 'front_dni');
      expect(request.media.single.url, 'https://example.com/dni.jpg');
      expect(api.calls.single['method'], 'getStudentRequest');
    });

    test('parses a parent detail with children', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': {
            'type': 'parent_request',
            'id': 'p1',
            'attributes': {
              'kind': 'parent',
              'fullname': 'María',
              'phone': '1234',
              'address': 'Calle 1',
              'children_count': 2,
              'children': [
                {
                  'id': 's1',
                  'fullname': 'Ana',
                  'identity_number': '1',
                  'status': 'pending',
                },
                {
                  'id': 's2',
                  'fullname': 'Luis',
                  'identity_number': '2',
                  'status': 'approved',
                },
              ],
            },
          },
        });
      final repository = RequestRepository(api);

      final request = await repository.getRequest(RequestKind.parent, 'p1');

      expect(request.kind, RequestKind.parent);
      expect(request.phone, '1234');
      expect(request.childrenCount, 2);
      expect(request.children.map((child) => child.status),
          ['pending', 'approved']);
    });

    test('approve student sends classroom_id', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': {'status': 'approved', 'changed': true},
        });
      final repository = RequestRepository(api);

      final changed = await repository.approve(
        const RequestModel(id: 's1', kind: RequestKind.student),
        classroomId: 'c1',
      );

      expect(changed, isTrue);
      expect(api.calls.single['method'], 'approveStudent');
      expect(api.calls.single['classroomId'], 'c1');
    });

    test('approve parent sends no body', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': {'status': 'approved', 'changed': false},
        });
      final repository = RequestRepository(api);

      final changed = await repository.approve(
        const RequestModel(id: 'p1', kind: RequestKind.parent),
      );

      expect(changed, isFalse);
      expect(api.calls.single['method'], 'approveParent');
    });

    test('reject dispatches by kind', () async {
      final api = _FakeRequestApi()
        ..payloads.add({
          'data': {'status': 'rejected', 'changed': true},
        })
        ..payloads.add({
          'data': {'status': 'rejected', 'changed': true},
        });
      final repository = RequestRepository(api);

      await repository.reject(
        const RequestModel(id: 's1', kind: RequestKind.student),
      );
      await repository.reject(
        const RequestModel(id: 'p1', kind: RequestKind.parent),
      );

      expect(api.calls[0]['method'], 'rejectStudent');
      expect(api.calls[1]['method'], 'rejectParent');
    });
  });

  group('RequestListNotifier', () {
    test('forwards search, status and type and resets page', () async {
      final repository = _FakeRequestRepository([
        const PageResult(
          data: [RequestModel(id: 'r1')],
          page: 1,
          perPage: 20,
          total: 1,
        ),
        const PageResult(
          data: [RequestModel(id: 'r2')],
          page: 1,
          perPage: 20,
          total: 1,
        ),
        const PageResult(
          data: [RequestModel(id: 'r3')],
          page: 1,
          perPage: 20,
          total: 1,
        ),
        const PageResult(
          data: [RequestModel(id: 'r4')],
          page: 1,
          perPage: 20,
          total: 1,
        ),
      ]);
      final notifier = RequestListNotifier(repository);

      await Future<void>.delayed(Duration.zero);
      expect(repository.calls.last['status'], 'pending');
      expect(repository.calls.last['type'], 'all');

      await notifier.setSearch('ana');
      expect(repository.calls.last['search'], 'ana');
      expect(repository.calls.last['page'], 1);

      await notifier.setStatus('approved');
      expect(repository.calls.last['status'], 'approved');

      await notifier.setType('parent');
      expect(repository.calls.last['type'], 'parent');
    });
  });

  group('requestClassroomOptionsProvider', () {
    test('uses server search with the expected page size', () async {
      final classrooms = _FakeClassroomRepository();
      final container = ProviderContainer(
        overrides: [
          classroomRepositoryProvider.overrideWithValue(classrooms),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(requestClassroomOptionsProvider('inglés').future);

      expect(result.single.name, 'Inglés 1');
      expect(classrooms.calls.single['search'], 'inglés');
      expect(classrooms.calls.single['page'], 1);
      expect(classrooms.calls.single['limit'], 50);
    });
  });
}
