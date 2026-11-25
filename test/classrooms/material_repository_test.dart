import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_api.dart';
import 'package:efe_mobile/features/classrooms/data/material_api.dart';
import 'package:efe_mobile/features/classrooms/data/material_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/material_upload_file.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/materials'),
      statusCode: 200,
      data: data,
    );

class _FakeMaterialApi implements MaterialApi {
  FormData? lastCreateData;
  Map<String, dynamic>? lastUpdateData;
  String? lastReplacePath;
  FormData? lastReplaceData;
  String? deletedId;
  String? requestedId;

  @override
  Future<Response> createMaterial(FormData data) async {
    lastCreateData = data;
    return _response({
      'data': {
        'id': 'm9',
        'attributes': {
          'name': 'Guía',
          'public_url': 'https://example.com/guia.pdf',
        },
      },
    });
  }

  @override
  Future<Response> updateMaterial(String id, Map<String, dynamic> data) async {
    lastUpdateData = data;
    return _response({
      'data': {
        'id': id,
        'attributes': {'name': 'Guía'}
      },
    });
  }

  @override
  Future<Response> replaceFiles(String id, FormData data) async {
    lastReplacePath = '/materials/$id/upload';
    lastReplaceData = data;
    return _response({
      'data': {
        'id': id,
        'attributes': {'name': 'Guía'}
      },
    });
  }

  @override
  Future<Response> deleteMaterial(String id) async {
    deletedId = id;
    return Response(
      requestOptions: RequestOptions(path: '/materials/$id'),
      statusCode: 204,
    );
  }

  @override
  Future<Response> getMaterial(String id) async {
    requestedId = id;
    return _response({
      'data': {
        'id': id,
        'attributes': {'name': 'Guía', 'visibility': 'specific'},
        'relationships': {
          'students': {
            'data': [
              {'type': 'students', 'id': 's1'},
            ],
          },
        },
      },
    });
  }
}

class _ThrowingMaterialApi implements MaterialApi {
  @override
  Future<Response> deleteMaterial(String id) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/materials/$id'),
      response: Response(
        requestOptions: RequestOptions(path: '/materials/$id'),
        statusCode: 500,
        data: {'message': 'boom'},
      ),
    );
  }

  @override
  Future<Response> createMaterial(FormData data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> updateMaterial(String id, Map<String, dynamic> data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> replaceFiles(String id, FormData data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getMaterial(String id) => Future.error(UnimplementedError());
}

class _FakeClassroomApi implements ClassroomApi {
  int calls = 0;

  @override
  Future<Response> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    calls++;
    final count = page == 1 ? 100 : 50;
    return _response({
      'data': List.generate(
        count,
        (i) => {
          'type': 'student_data',
          'id': 's${(page - 1) * 100 + i + 1}',
          'attributes': {'fullname': 'Alumno'},
        },
      ),
      'meta': {'cursor': null, 'has_more': false, 'total': 150},
    });
  }

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

  @override
  Future<Response> createClassroom(Map<String, dynamic> data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> updateClassroom(String id, Map<String, dynamic> data) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> deleteClassroom(String id) =>
      Future.error(UnimplementedError());
}

Map<String, String> _fields(FormData data) =>
    {for (final entry in data.fields) entry.key: entry.value};

void main() {
  group('MaterialRepository', () {
    final byteFile = MaterialUploadFile(
      name: 'a.pdf',
      size: 3,
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    test('createMaterial arma el FormData con campos, listas y archivos',
        () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      final material = await repository.createMaterial(
        classroomId: 'c1',
        name: 'Guía',
        category: 'Exámenes',
        visibility: 'specific',
        studentIds: ['s1', 's2'],
        files: [
          byteFile,
          MaterialUploadFile(name: 'b.pdf', size: 3, bytes: byteFile.bytes),
        ],
      );

      final data = api.lastCreateData!;
      final fields = _fields(data);
      expect(fields['classroom_id'], 'c1');
      expect(fields['name'], 'Guía');
      expect(fields['category'], 'Exámenes');
      expect(fields['visibility'], 'specific');
      expect(
        data.fields.where((e) => e.key == 'student_ids[]').map((e) => e.value),
        ['s1', 's2'],
      );
      expect(data.files, hasLength(2));
      expect(data.files.first.key, 'files[]');
      expect(material.id, 'm9');
      expect(material.publicUrl, 'https://example.com/guia.pdf');
    });

    test('createMaterial usa fromFile cuando el archivo tiene path', () async {
      final tmp = File('${Directory.systemTemp.path}/efe_material_test.txt');
      await tmp.writeAsString('hola');
      addTearDown(() => tmp.delete());

      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      await repository.createMaterial(
        classroomId: 'c1',
        name: 'Apunte',
        files: [MaterialUploadFile(name: 'a.txt', size: 4, path: tmp.path)],
      );

      expect(api.lastCreateData!.files.single.value, isA<MultipartFile>());
    });

    test('updateMaterial manda solo los campos no nulos', () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      await repository.updateMaterial(
        'm1',
        name: 'X',
        visibility: 'specific',
        studentIds: ['s1'],
      );

      expect(api.lastUpdateData, {
        'name': 'X',
        'visibility': 'specific',
        'student_ids': ['s1'],
      });
    });

    test(
        'updateMaterial manda descripción vacía y available_until null al limpiar',
        () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      await repository.updateMaterial(
        'm1',
        description: '',
        clearAvailableUntil: true,
      );

      expect(api.lastUpdateData, {'description': '', 'available_until': null});
    });

    test('replaceFiles va al endpoint de upload con files[]', () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      await repository.replaceFiles('m1', files: [byteFile]);

      expect(api.lastReplacePath, '/materials/m1/upload');
      expect(api.lastReplaceData!.files.single.key, 'files[]');
    });

    test('deleteMaterial llama al endpoint', () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      await repository.deleteMaterial('m1');

      expect(api.deletedId, 'm1');
    });

    test('getMaterial parsea el detalle con alumnos vinculados', () async {
      final api = _FakeMaterialApi();
      final repository = MaterialRepository(api, _FakeClassroomApi());

      final material = await repository.getMaterial('m1');

      expect(api.requestedId, 'm1');
      expect(material.studentIds, ['s1']);
      expect(material.visibility, 'specific');
    });

    test('getClassroomStudents recorre todas las páginas', () async {
      final classroomApi = _FakeClassroomApi();
      final repository = MaterialRepository(_FakeMaterialApi(), classroomApi);

      final students = await repository.getClassroomStudents('c1');

      expect(students, hasLength(150));
      expect(classroomApi.calls, 2);
    });

    test('convierte DioException en ApiException', () async {
      final repository =
          MaterialRepository(_ThrowingMaterialApi(), _FakeClassroomApi());

      expect(
        () => repository.deleteMaterial('m1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
