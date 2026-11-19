import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/documents/data/document_api.dart';
import 'package:efe_mobile/features/documents/data/document_repository.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDocumentApi implements DocumentApi {
  _FakeDocumentApi(this.payload, {this.throwError});

  final Map<String, dynamic> payload;
  final DioException? throwError;

  @override
  Future<Response> getDocuments({String? cursor, int limit = 20}) async {
    if (throwError != null) throw throwError!;
    return Response(
      requestOptions: RequestOptions(path: '/documents'),
      statusCode: 200,
      data: payload,
    );
  }

  @override
  Future<Response> getDocument(String id) async {
    if (throwError != null) throw throwError!;
    return Response(
      requestOptions: RequestOptions(path: '/documents/$id'),
      statusCode: 200,
      data: payload,
    );
  }

  @override
  Future<Response> createDocument(FormData data) => throw UnimplementedError();

  @override
  Future<Response> updateDocument(String id, FormData data) =>
      throw UnimplementedError();

  @override
  Future<Response> deleteDocument(String id) => throw UnimplementedError();

  @override
  String downloadUrl(String id) => '/documents/$id/download';
}

void main() {
  group('DocumentModel.fromJson', () {
    test('parsea media array y file_url fallback', () {
      final model = DocumentModel.fromJson({
        'id': 'd1',
        'attributes': {
          'title': 'Reglamento',
          'file_url': 'https://f/r.pdf',
          'created_at': '2026-09-01T10:00:00',
          'media': [
            {'url': 'https://m/a.pdf'},
          ],
        },
      });

      expect(model.id, 'd1');
      expect(model.title, 'Reglamento');
      expect(model.fileUrl, 'https://f/r.pdf');
      expect(model.mediaUrls, ['https://m/a.pdf']);
      expect(model.createdAt, DateTime(2026, 9, 1, 10));
    });

    test('sin media ni file_url queda vacío', () {
      final model = DocumentModel.fromJson({
        'id': 'd2',
        'attributes': {'title': 'Sin archivo'},
      });

      expect(model.mediaUrls, isEmpty);
      expect(model.fileUrl, '');
    });

    test('payload no-string no lanza TypeError', () {
      final model = DocumentModel.fromJson({
        'id': 7,
        'attributes': {
          'title': 123,
          'description': 456,
          'file_url': 789,
          'created_at': 12345,
        },
      });

      expect(model.id, '7');
      expect(model.title, '123');
      expect(model.description, '456');
      expect(model.fileUrl, '789');
      expect(model.createdAt, isNull);
    });
  });

  group('DocumentRepository', () {
    test('getDocuments mapea la pagina con cursor', () async {
      final repository = DocumentRepository(
        _FakeDocumentApi({
          'data': [
            {
              'id': 'd1',
              'attributes': {
                'title': 'Reglamento',
                'file_url': 'https://f/r.pdf',
                'created_at': '2026-09-01T10:00:00',
                'media': [
                  {'url': 'https://m/a.pdf'},
                ],
              },
            },
          ],
          'meta': {'cursor': 'next', 'has_more': true, 'total': 1},
        }),
      );

      final page = await repository.getDocuments();

      expect(page.data, hasLength(1));
      expect(page.data.single.title, 'Reglamento');
      expect(page.nextCursor, 'next');
      expect(page.hasMore, isTrue);
      expect(page.total, 1);
    });

    test('getDocument devuelve el modelo', () async {
      final repository = DocumentRepository(
        _FakeDocumentApi({
          'data': {
            'id': 'd1',
            'attributes': {
              'title': 'Reglamento',
              'file_url': 'https://f/r.pdf',
            },
          },
        }),
      );

      final model = await repository.getDocument('d1');

      expect(model.id, 'd1');
      expect(model.title, 'Reglamento');
    });

    test('convierte DioException en ApiException', () async {
      final repository = DocumentRepository(
        _FakeDocumentApi(
          {},
          throwError: DioException(
            requestOptions: RequestOptions(path: '/documents'),
            response: Response(
              requestOptions: RequestOptions(path: '/documents'),
              statusCode: 500,
            ),
            message: 'Error',
          ),
        ),
      );

      expect(
        () => repository.getDocuments(),
        throwsA(isA<ApiException>()),
      );
    });

    test('meta no-string no lanza y normaliza tipos', () async {
      final repository = DocumentRepository(
        _FakeDocumentApi({
          'data': [],
          'meta': {'cursor': 42, 'has_more': 'yes', 'total': '3'},
        }),
      );

      final page = await repository.getDocuments();

      expect(page.nextCursor, '42');
      expect(page.hasMore, isFalse);
      expect(page.total, 3);
    });
  });
}
