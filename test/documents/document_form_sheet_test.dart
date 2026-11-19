import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/documents/data/document_repository.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/documents/screens/widgets/document_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeDocumentRepository implements DocumentRepository {
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;
  Object? error;

  @override
  Future<CursorPagination<DocumentModel>> getDocuments(
          {String? cursor}) async =>
      CursorPagination<DocumentModel>.empty();

  @override
  Future<DocumentModel> getDocument(String id) async =>
      const DocumentModel(id: 'd1', title: 'Original');

  @override
  String downloadUrl(String id) => 'https://example.com/documents/$id/download';

  @override
  Future<DocumentModel> createDocument({
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    if (error != null) throw error!;
    createdArgs = {
      'title': title,
      'description': description,
      'file': file,
    };
    return DocumentModel(id: 'd1', title: title, description: description);
  }

  @override
  Future<DocumentModel> updateDocument(
    String id, {
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    if (error != null) throw error!;
    updatedId = id;
    updatedArgs = {
      'title': title,
      'description': description,
      'file': file,
    };
    return DocumentModel(id: id, title: title, description: description);
  }

  @override
  Future<void> deleteDocument(String id) async {}
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeDocumentRepository repository, {
  DocumentModel? document,
  Future<UploadFile?> Function()? pickFile,
  ValueNotifier<bool?>? result,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [documentRepositoryProvider.overrideWithValue(repository)],
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
                  builder: (_) => DocumentFormSheet(
                    document: document,
                    pickFile: pickFile,
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
  testWidgets('submit sin título muestra el error y no llama al repo',
      (tester) async {
    final repository = _FakeDocumentRepository();
    await _pumpForm(tester, repository);

    await _tapSave(tester);

    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(repository.createdArgs, isNull);
    expect(repository.updatedArgs, isNull);
  });

  testWidgets('creación válida llama createDocument con los valores exactos',
      (tester) async {
    final repository = _FakeDocumentRepository();
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Reglamento',
    );
    await tester.enterText(
      find.byKey(const Key('document-description-field')),
      'Reglamento interno',
    );

    await _tapSave(tester);

    expect(repository.createdArgs, isNotNull);
    expect(repository.createdArgs!['title'], 'Reglamento');
    expect(repository.createdArgs!['description'], 'Reglamento interno');
    expect(repository.createdArgs!['file'], isNull);
    expect(result.value, isTrue);
  });

  testWidgets('el archivo elegido se envía al repositorio', (tester) async {
    final repository = _FakeDocumentRepository();
    final picked = UploadFile(
      name: 'acta.pdf',
      size: 1024,
      bytes: Uint8List.fromList([1, 2]),
    );
    await _pumpForm(tester, repository, pickFile: () async => picked);

    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Acta',
    );
    await tester.tap(find.text('Elegir archivo'));
    await tester.pumpAndSettle();

    await _tapSave(tester);

    expect(repository.createdArgs!['file'], same(picked));
  });

  testWidgets('edición prellena y llama updateDocument', (tester) async {
    final repository = _FakeDocumentRepository();
    final result = ValueNotifier<bool?>(null);
    const document = DocumentModel(
      id: 'd1',
      title: 'Original',
      description: 'Descripción original',
      fileUrl: 'https://example.com/documents/original.pdf',
    );
    await _pumpForm(
      tester,
      repository,
      document: document,
      result: result,
    );

    expect(find.text('Editar documento'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Descripción original'), findsOneWidget);
    expect(find.text('original.pdf'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Editado',
    );
    await _tapSave(tester);

    expect(repository.updatedId, 'd1');
    expect(repository.updatedArgs!['title'], 'Editado');
    expect(repository.updatedArgs!['description'], 'Descripción original');
    expect(repository.updatedArgs!['file'], isNull);
    expect(result.value, isTrue);
  });

  testWidgets('un 422 pinta el error en el campo', (tester) async {
    final repository = _FakeDocumentRepository()
      ..error = ValidationException(
        fieldErrors: {'title': 'El título ya existe'},
      );
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Repetido',
    );
    await _tapSave(tester);

    expect(find.text('El título ya existe'), findsOneWidget);
    expect(result.value, isNull);
  });

  testWidgets('un 422 sobre file pinta el error del archivo', (tester) async {
    final repository = _FakeDocumentRepository()
      ..error = ValidationException(
        fieldErrors: {'file': 'El archivo supera los 20 MB'},
      );
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Archivo grande',
    );
    await _tapSave(tester);

    expect(find.text('El archivo supera los 20 MB'), findsOneWidget);
  });
}
