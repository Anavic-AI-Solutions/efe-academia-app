import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/news/screens/widgets/news_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeNewsRepository implements NewsRepository {
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;
  Object? error;

  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination<NewsModel>.empty();

  @override
  Future<NewsModel> createNews({
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async {
    if (error != null) throw error!;
    createdArgs = {
      'title': title,
      'description': description,
      'content': content,
      'eventDate': eventDate,
      'image': image,
    };
    return NewsModel(
      id: 'n1',
      title: title,
      description: description,
      content: content,
      eventDate: eventDate,
    );
  }

  @override
  Future<NewsModel> updateNews(
    String id, {
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async {
    if (error != null) throw error!;
    updatedId = id;
    updatedArgs = {
      'title': title,
      'description': description,
      'content': content,
      'eventDate': eventDate,
      'image': image,
    };
    return NewsModel(
      id: id,
      title: title,
      description: description,
      content: content,
      eventDate: eventDate,
    );
  }

  @override
  Future<void> deleteNews(String id) async {}
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeNewsRepository repository, {
  NewsModel? news,
  Future<UploadFile?> Function()? pickImage,
  ValueNotifier<bool?>? result,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [newsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => NewsFormSheet(
                    news: news,
                    pickImage: pickImage,
                  ),
                );
                if (result != null) result.value = saved;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Guardar');
  await tester.ensureVisible(save);
  await tester.pump();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submit vacío muestra el error de campo y no llama al repo',
      (tester) async {
    final repository = _FakeNewsRepository();
    await _pumpForm(tester, repository);

    await _tapSave(tester);

    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
    expect(repository.createdArgs, isNull);
    expect(repository.updatedArgs, isNull);
  });

  testWidgets('creación válida llama createNews con los valores exactos',
      (tester) async {
    final repository = _FakeNewsRepository();
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(find.byKey(const Key('news-title-field')), 'Título');
    await tester.enterText(
      find.byKey(const Key('news-description-field')),
      'Bajada',
    );
    await tester.enterText(
      find.byKey(const Key('news-content-field')),
      'Contenido',
    );

    await _tapSave(tester);

    expect(repository.createdArgs, isNotNull);
    expect(repository.createdArgs!['title'], 'Título');
    expect(repository.createdArgs!['description'], 'Bajada');
    expect(repository.createdArgs!['content'], 'Contenido');
    expect(repository.createdArgs!['image'], isNull);
    expect(result.value, isTrue);
  });

  testWidgets('la imagen elegida se envía al repositorio', (tester) async {
    final repository = _FakeNewsRepository();
    final picked = UploadFile(
      name: 'foto.png',
      bytes: Uint8List.fromList([1, 2]),
    );
    await _pumpForm(
      tester,
      repository,
      pickImage: () async => picked,
    );

    await tester.enterText(
        find.byKey(const Key('news-title-field')), 'Con foto');
    await tester.enterText(
      find.byKey(const Key('news-content-field')),
      'Contenido',
    );
    await tester.tap(find.text('Elegir imagen'));
    await tester.pumpAndSettle();

    await _tapSave(tester);

    expect(repository.createdArgs!['image'], same(picked));
  });

  testWidgets('edición prellena y llama updateNews', (tester) async {
    final repository = _FakeNewsRepository();
    final result = ValueNotifier<bool?>(null);
    const news = NewsModel(
      id: 'n1',
      title: 'Original',
      description: 'Bajada original',
      content: 'Contenido original',
    );
    await _pumpForm(tester, repository, news: news, result: result);

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Contenido original'), findsOneWidget);
    expect(find.text('Editar noticia'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('news-title-field')),
      'Editada',
    );
    await _tapSave(tester);

    expect(repository.updatedId, 'n1');
    expect(repository.updatedArgs!['title'], 'Editada');
    expect(repository.updatedArgs!['content'], 'Contenido original');
    expect(result.value, isTrue);
  });

  testWidgets('un 422 pinta el error en el campo', (tester) async {
    final repository = _FakeNewsRepository()
      ..error =
          ValidationException(fieldErrors: {'title': 'El título ya existe'});
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
        find.byKey(const Key('news-title-field')), 'Repetido');
    await tester.enterText(
      find.byKey(const Key('news-content-field')),
      'Contenido',
    );

    await _tapSave(tester);

    expect(find.text('El título ya existe'), findsOneWidget);
    expect(result.value, isNull);
  });
}
