import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/news/data/news_api.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/news'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _newsPayload() => {
      'data': {
        'type': 'news',
        'id': 'n1',
        'attributes': {
          'title': 'Título',
          'description': 'Descripción',
          'content': 'Contenido',
          'event_date': '2026-12-01T00:00:00',
          'media': [
            {'id': 1, 'url': 'https://cdn.example.com/news/foto.png'},
            {'id': 2, 'url': 'https://cdn.example.com/news/otra.png'},
          ],
          'created_at': '2026-11-01T10:00:00',
        },
      },
    };

class _FakeNewsApi implements NewsApi {
  FormData? created;
  FormData? updated;
  String? updatedId;
  String? deletedId;
  Object? error;

  Map<String, dynamic> createResponse = _newsPayload();
  Map<String, dynamic> updateResponse = _newsPayload();

  @override
  Future<Response> getNews({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<Response> createNews(FormData data) async {
    if (error != null) throw error!;
    created = data;
    return _response(createResponse);
  }

  @override
  Future<Response> updateNews(String id, FormData data) async {
    if (error != null) throw error!;
    updatedId = id;
    updated = data;
    return _response(updateResponse);
  }

  @override
  Future<Response> deleteNews(String id) async {
    if (error != null) throw error!;
    deletedId = id;
    return _response(null);
  }
}

void main() {
  group('NewsRepository.createNews', () {
    test('envía title, description, content y el archivo media', () async {
      final api = _FakeNewsApi();
      final repository = NewsRepository(api);
      final bytes = Uint8List.fromList([1, 2]);

      final news = await repository.createNews(
        title: 'Nueva noticia',
        description: 'Bajada',
        content: 'Cuerpo completo',
        eventDate: DateTime(2026, 12, 1),
        image: UploadFile(name: 'foto.png', bytes: bytes),
      );

      final form = api.created!;
      final fields = {for (final entry in form.fields) entry.key: entry.value};
      expect(fields['title'], 'Nueva noticia');
      expect(fields['description'], 'Bajada');
      expect(fields['content'], 'Cuerpo completo');
      expect(fields['event_date'], '2026-12-01T00:00:00.000');
      expect(fields.containsKey('_method'), isFalse);
      expect(form.files, hasLength(1));
      expect(form.files.first.key, 'media');
      expect(form.files.first.value.filename, 'foto.png');

      expect(news.id, 'n1');
      expect(news.description, 'Descripción');
      expect(news.mediaUrls, [
        'https://cdn.example.com/news/foto.png',
        'https://cdn.example.com/news/otra.png',
      ]);
    });

    test('sin imagen no agrega archivos', () async {
      final api = _FakeNewsApi();
      final repository = NewsRepository(api);

      await repository.createNews(
        title: 'Sin foto',
        description: '',
        content: 'Cuerpo',
      );

      expect(api.created!.files, isEmpty);
      expect(
        api.created!.fields.any((entry) => entry.key == 'event_date'),
        isFalse,
      );
    });
  });

  group('NewsRepository.updateNews', () {
    test('pega a /news/{id} con _method PATCH', () async {
      final api = _FakeNewsApi();
      final repository = NewsRepository(api);

      final news = await repository.updateNews(
        'n1',
        title: 'Editada',
        description: 'Bajada nueva',
        content: 'Cuerpo nuevo',
      );

      expect(api.updatedId, 'n1');
      final fields = {
        for (final entry in api.updated!.fields) entry.key: entry.value,
      };
      expect(fields['_method'], 'PATCH');
      expect(fields['title'], 'Editada');
      expect(fields['description'], 'Bajada nueva');
      expect(fields['content'], 'Cuerpo nuevo');
      expect(news.id, 'n1');
    });
  });

  group('NewsRepository.deleteNews', () {
    test('envía el id a eliminar', () async {
      final api = _FakeNewsApi();
      final repository = NewsRepository(api);

      await repository.deleteNews('n1');

      expect(api.deletedId, 'n1');
    });
  });

  group('NewsRepository errores', () {
    test('propaga la ValidationException del interceptor', () async {
      final api = _FakeNewsApi()
        ..error = ValidationException(fieldErrors: {'title': 'required'});
      final repository = NewsRepository(api);

      expect(
        () => repository.createNews(
          title: '',
          description: '',
          content: 'Cuerpo',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.fieldErrors['title'],
            'fieldErrors[title]',
            'required',
          ),
        ),
      );
    });
  });

  group('NewsModel.fromJson', () {
    test('cae a image cuando no hay media', () {
      final model = NewsModel.fromJson({
        'data': {
          'id': 'n9',
          'attributes': {
            'title': 'Título',
            'content': 'Cuerpo',
            'image': 'https://cdn.example.com/news/legacy.png',
            'public_url': 'https://cdn.example.com/news/public.png',
          },
        },
      });

      expect(model.mediaUrls, ['https://cdn.example.com/news/legacy.png']);
      expect(model.description, '');
    });

    test('prefiere media sobre image', () {
      final model = NewsModel.fromJson(_newsPayload());

      expect(model.mediaUrls.first, 'https://cdn.example.com/news/foto.png');
    });
  });
}
