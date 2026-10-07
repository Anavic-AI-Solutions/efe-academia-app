import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/classrooms/data/material_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_upload_file.dart';
import 'package:efe_mobile/features/classrooms/providers/material_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/material_form_sheet.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeMaterialRepository implements MaterialRepository {
  bool failCreate = false;
  int createCalls = 0;
  String? lastCreateName;
  String? lastCreateCategory;
  String? lastCreateVisibility;
  List<String>? lastCreateStudentIds;
  List<MaterialUploadFile>? lastCreateFiles;
  String? lastUpdateName;
  String? lastUpdateType;
  String? lastUpdateVisibility;
  List<String>? lastUpdateStudentIds;
  String? lastReplaceId;
  MaterialModel? detail;
  List<StudentModel> students = const [];

  @override
  Future<MaterialModel> createMaterial({
    required String classroomId,
    required String name,
    String? description,
    String? type,
    String? category,
    String? visibility,
    String? availableUntil,
    List<String> studentIds = const [],
    required List<MaterialUploadFile> files,
  }) async {
    createCalls++;
    lastCreateName = name;
    lastCreateCategory = category;
    lastCreateVisibility = visibility;
    lastCreateStudentIds = studentIds;
    lastCreateFiles = files;
    if (failCreate) {
      throw ApiException(message: 'boom', statusCode: 422);
    }
    return const MaterialModel(id: 'm9', name: '');
  }

  @override
  Future<MaterialModel> updateMaterial(
    String id, {
    String? name,
    String? description,
    String? type,
    String? category,
    String? visibility,
    String? availableUntil,
    List<String>? studentIds,
  }) async {
    lastUpdateName = name;
    lastUpdateType = type;
    lastUpdateVisibility = visibility;
    lastUpdateStudentIds = studentIds;
    return detail ?? MaterialModel(id: id, name: name ?? '');
  }

  @override
  Future<MaterialModel> replaceFiles(
    String id, {
    required List<MaterialUploadFile> files,
  }) async {
    lastReplaceId = id;
    return detail ?? MaterialModel(id: id, name: '');
  }

  @override
  Future<void> deleteMaterial(String id) async {}

  @override
  Future<MaterialModel> getMaterial(String id) async =>
      detail ?? MaterialModel(id: id, name: '');

  @override
  Future<List<StudentModel>> getClassroomStudents(String classroomId) async =>
      students;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

MaterialUploadFile _byteFile(String name) => MaterialUploadFile(
      name: name,
      size: 1000,
      bytes: Uint8List.fromList([1, 2, 3]),
    );

void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es', 'AR'));
  });

  Future<_FakeMaterialRepository> pumpSheetBody(
    WidgetTester tester, {
    _FakeMaterialRepository? repo,
    MaterialModel? material,
    Future<List<MaterialUploadFile>> Function()? pickFiles,
  }) async {
    final fakeRepo = repo ?? _FakeMaterialRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [materialRepositoryProvider.overrideWithValue(fakeRepo)],
        child: localizedApp(
          home: Scaffold(
            body: MaterialFormSheet(
              classroomId: 'c1',
              material: material,
              pickFiles: pickFiles,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fakeRepo;
  }

  /// Abre el sheet como modal real (showModalBottomSheet) para poder
  /// verificar que se cierra al guardar.
  Future<_FakeMaterialRepository> pumpSheetModal(
    WidgetTester tester, {
    _FakeMaterialRepository? repo,
    MaterialModel? material,
    Future<List<MaterialUploadFile>> Function()? pickFiles,
  }) async {
    final fakeRepo = repo ?? _FakeMaterialRepository();
    final sheet = MaterialFormSheet(
      classroomId: 'c1',
      material: material,
      pickFiles: pickFiles,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [materialRepositoryProvider.overrideWithValue(fakeRepo)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => sheet,
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return fakeRepo;
  }

  testWidgets('guardar sin nombre ni archivos muestra los errores',
      (tester) async {
    await pumpSheetBody(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(find.text(es.materialFormNameRequired), findsOneWidget);
    expect(find.text(es.materialFormFilesRequired), findsOneWidget);
  });

  testWidgets('el picker inyectado agrega los chips de archivos',
      (tester) async {
    await pumpSheetBody(
      tester,
      pickFiles: () async => [_byteFile('guia.pdf'), _byteFile('audio.mp3')],
    );

    await _tapVisible(tester, find.text(es.materialFormPickFiles));

    expect(find.text('guia.pdf'), findsOneWidget);
    expect(find.text('audio.mp3'), findsOneWidget);
  });

  testWidgets('valida la cantidad de archivos', (tester) async {
    await pumpSheetBody(
      tester,
      pickFiles: () async =>
          List.generate(11, (i) => _byteFile('archivo$i.pdf')),
    );

    await _tapVisible(tester, find.text(es.materialFormPickFiles));

    expect(find.text(es.materialFormFilesTooMany), findsOneWidget);
  });

  testWidgets('valida el tamaño de un archivo', (tester) async {
    await pumpSheetBody(
      tester,
      pickFiles: () async => [
        MaterialUploadFile(
          name: 'grande.pdf',
          size: 51 * 1024 * 1024,
          bytes: Uint8List.fromList([1]),
        ),
      ],
    );

    await _tapVisible(tester, find.text(es.materialFormPickFiles));

    expect(find.text(es.materialFormFileTooLarge), findsOneWidget);
  });

  testWidgets('visibilidad específica lista los alumnos del aula',
      (tester) async {
    final repo = _FakeMaterialRepository()
      ..students = const [
        StudentModel(id: 's1', fullname: 'Ana Gómez'),
        StudentModel(id: 's2', fullname: 'Luis Pérez'),
      ];
    await pumpSheetBody(tester, repo: repo);

    await _tapVisible(tester, find.text(es.materialFormVisibilitySpecific));

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Luis Pérez'), findsOneWidget);
  });

  testWidgets('visibilidad específica sin alumnos elegidos bloquea el guardado',
      (tester) async {
    final repo = _FakeMaterialRepository()
      ..students = const [StudentModel(id: 's1', fullname: 'Ana Gómez')];
    await pumpSheetBody(tester, repo: repo);

    await _tapVisible(tester, find.text(es.materialFormVisibilitySpecific));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(find.text(es.materialFormStudentsRequired), findsOneWidget);
  });

  testWidgets('crear llama al repositorio y cierra el sheet', (tester) async {
    final repo = _FakeMaterialRepository()
      ..students = const [StudentModel(id: 's1', fullname: 'Ana Gómez')];
    await pumpSheetModal(
      tester,
      repo: repo,
      pickFiles: () async => [_byteFile('guia.pdf')],
    );

    await tester.enterText(find.byType(TextField).first, 'Guía de estudio');
    await _tapVisible(tester, find.text(es.materialFormPickFiles));
    await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await _tapVisible(tester, find.text('Exámenes').last);
    await _tapVisible(tester, find.text(es.materialFormVisibilitySpecific));
    await _tapVisible(tester, find.byType(CheckboxListTile).first);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(repo.createCalls, 1);
    expect(repo.lastCreateName, 'Guía de estudio');
    expect(repo.lastCreateCategory, 'Exámenes');
    expect(repo.lastCreateVisibility, 'specific');
    expect(repo.lastCreateStudentIds, ['s1']);
    expect(repo.lastCreateFiles, hasLength(1));
    expect(find.byType(MaterialFormSheet), findsNothing);
  });

  testWidgets('editar precarga el material y no reemplaza archivos sin cambios',
      (tester) async {
    final repo = _FakeMaterialRepository()
      ..detail = const MaterialModel(
        id: 'm1',
        name: 'Apunte viejo',
        visibility: 'specific',
        studentIds: ['s1'],
      );
    await pumpSheetModal(
      tester,
      repo: repo,
      material: const MaterialModel(id: 'm1', name: 'Apunte viejo'),
    );

    expect(find.widgetWithText(TextField, 'Apunte viejo'), findsOneWidget);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(repo.lastUpdateName, 'Apunte viejo');
    expect(repo.lastUpdateStudentIds, ['s1']);
    expect(repo.lastReplaceId, isNull);
    expect(find.byType(MaterialFormSheet), findsNothing);
  });

  testWidgets('editar con archivos nuevos reemplaza el set y recalcula el tipo',
      (tester) async {
    final repo = _FakeMaterialRepository()
      ..detail = const MaterialModel(id: 'm1', name: 'Apunte viejo');
    await pumpSheetModal(
      tester,
      repo: repo,
      material: const MaterialModel(id: 'm1', name: 'Apunte viejo'),
      pickFiles: () async => [_byteFile('guia.pdf')],
    );

    await _tapVisible(tester, find.text(es.materialFormPickFiles));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(repo.lastReplaceId, 'm1');
    expect(repo.lastUpdateType, 'pdf');
  });

  testWidgets('un error al crear mantiene el sheet abierto con el mensaje',
      (tester) async {
    final repo = _FakeMaterialRepository()..failCreate = true;
    await pumpSheetBody(
      tester,
      repo: repo,
      pickFiles: () async => [_byteFile('guia.pdf')],
    );

    await tester.enterText(find.byType(TextField).first, 'Guía');
    await _tapVisible(tester, find.text(es.materialFormPickFiles));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );

    expect(find.text(es.materialFormError), findsOneWidget);
    expect(find.byType(MaterialFormSheet), findsOneWidget);
  });
}
