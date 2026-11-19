import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/documents/data/document_api.dart';
import 'package:efe_mobile/features/documents/data/document_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/documents'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _documentPayload() => {
      'data': {
        'type': 'documents',
        'id': 'd1',
        'attributes': {
          'title': 'Reglamento',
          'description': 'Reglamento interno',
          'file_url': 'https://cdn.example.com/documents/reglamento.pdf',
          'created_at': '2026-11-01T10:00:00',
        },
      },
    };

class _FakeDocumentApi implements DocumentApi {
  FormData? created;
  FormData? updated;
  String? updatedId;
  String? deletedId;
  Object? error;

  @override
  Future<Response> getDocuments({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<Response> getDocument(String id) => throw UnimplementedError();

  @override
  Future<Response> createDocument(FormData data) async {
    if (error != null) throw error!;
    created = data;
    return _response(_documentPayload());
  }

  @override
  Future<Response> updateDocument(String id, FormData data) async {
    if (error != null) throw error!;
    updatedId = id;
    updated = data;
    return _response(_documentPayload());
  }

  @override
  Future<Response> deleteDocument(String id) async {
    if (error != null) throw error!;
    deletedId = id;
    return _response(null);
  }

  @override
  String downloadUrl(String id) => '/documents/$id/download';
}

Map<String, String> _fields(FormData form) =>
    {for (final entry in form.fields) entry.key: entry.value};

void main() {
  group('DocumentRepository.createDocument', () {
    test('envía title, description y el archivo file', () async {
      final api = _FakeDocumentApi();
      final repository = DocumentRepository(api);
      final bytes = Uint8List.fromList([1, 2, 3]);

      final document = await repository.createDocument(
        title: 'Reglamento',
        description: 'Reglamento interno',
        file: UploadFile(name: 'reglamento.pdf', bytes: bytes),
      );

      final fields = _fields(api.created!);
      expect(fields['title'], 'Reglamento');
      expect(fields['description'], 'Reglamento interno');
      expect(fields.containsKey('_method'), isFalse);
      expect(api.created!.files, hasLength(1));
      expect(api.created!.files.first.key, 'file');
      expect(api.created!.files.first.value.filename, 'reglamento.pdf');

      expect(document.id, 'd1');
      expect(document.title, 'Reglamento');
      expect(
        document.fileUrl,
        'https://cdn.example.com/documents/reglamento.pdf',
      );
    });

    test('sin archivo no agrega files', () async {
      final api = _FakeDocumentApi();
      final repository = DocumentRepository(api);

      await repository.createDocument(title: 'Sin archivo');

      expect(_fields(api.created!)['description'], '');
      expect(api.created!.files, isEmpty);
    });
  });

  group('DocumentRepository.updateDocument', () {
    test('pega a /documents/{id} con _method PATCH y archivo', () async {
      final api = _FakeDocumentApi();
      final repository = DocumentRepository(api);
      final bytes = Uint8List.fromList([4, 5]);

      final document = await repository.updateDocument(
        'd1',
        title: 'Editado',
        description: 'Nueva descripción',
        file: UploadFile(name: 'nuevo.docx', bytes: bytes),
      );

      expect(api.updatedId, 'd1');
      final fields = _fields(api.updated!);
      expect(fields['_method'], 'PATCH');
      expect(fields['title'], 'Editado');
      expect(fields['description'], 'Nueva descripción');
      expect(api.updated!.files.single.key, 'file');
      expect(api.updated!.files.single.value.filename, 'nuevo.docx');
      expect(document.id, 'd1');
    });
  });

  group('DocumentRepository.deleteDocument', () {
    test('envía el id a eliminar', () async {
      final api = _FakeDocumentApi();
      final repository = DocumentRepository(api);

      await repository.deleteDocument('d1');

      expect(api.deletedId, 'd1');
    });
  });

  group('DocumentRepository errores', () {
    test('propaga la ValidationException del interceptor', () async {
      final api = _FakeDocumentApi()
        ..error = ValidationException(fieldErrors: {'title': 'required'});
      final repository = DocumentRepository(api);

      expect(
        () => repository.createDocument(title: ''),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.fieldErrors['title'],
            'fieldErrors[title]',
            'required',
          ),
        ),
      );
    });

    test('convierte DioException en ApiException al crear', () async {
      final api = _FakeDocumentApi()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/documents'),
          response: Response(
            requestOptions: RequestOptions(path: '/documents'),
            statusCode: 500,
          ),
          message: 'Error',
        );
      final repository = DocumentRepository(api);

      expect(
        () => repository.createDocument(title: 'Reglamento'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
