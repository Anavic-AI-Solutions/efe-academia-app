import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/data/material_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_upload_file.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/providers/material_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/classroom_detail_screen.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/classroom_related_tabs.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/material_form_sheet.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../helpers/localized_app.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.role = 'professor'});

  final String role;

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'Profe Test',
        email: 'profe@test.com',
        role: role,
      );

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
      getCurrentUser();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      getCurrentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

class _FakeClassroomRepository implements ClassroomRepository {
  _FakeClassroomRepository({
    required this.classroom,
    required this.materials,
  });

  final ClassroomModel classroom;
  final List<MaterialModel> materials;
  final List<StudentModel> students = const [];

  @override
  Future<ClassroomModel> getClassroom(String id) async => classroom;

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: List.of(materials),
        page: page,
        perPage: limit,
        total: materials.length,
      );

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: students,
        page: page,
        perPage: limit,
        total: students.length,
      );

  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

class _FakeMaterialRepository implements MaterialRepository {
  _FakeMaterialRepository({
    required this.sharedMaterials,
    this.failDelete = false,
    this.detail,
  });

  final List<MaterialModel> sharedMaterials;
  bool failDelete;
  int deleteCalls = 0;
  int createCalls = 0;
  String? createdName;
  MaterialModel? detail;
  final List<StudentModel> students = const [];

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
    createdName = name;
    final created = MaterialModel(
      id: 'm9',
      name: name,
      type: type ?? '',
      visibility: visibility ?? 'all',
      studentIds: studentIds,
    );
    sharedMaterials.insert(0, created);
    return created;
  }

  @override
  Future<void> deleteMaterial(String id) async {
    deleteCalls++;
    if (failDelete) {
      throw ApiException(message: 'boom', statusCode: 500);
    }
    sharedMaterials.removeWhere((material) => material.id == id);
  }

  @override
  Future<MaterialModel> getMaterial(String id) async =>
      detail ?? sharedMaterials.firstWhere((material) => material.id == id);

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
  }) async =>
      detail ?? sharedMaterials.first;

  @override
  Future<MaterialModel> replaceFiles(
    String id, {
    required List<MaterialUploadFile> files,
  }) async =>
      detail ?? sharedMaterials.first;

  @override
  Future<List<StudentModel>> getClassroomStudents(String classroomId) async =>
      students;
}

const _classroom = ClassroomModel(
  id: 'c1',
  name: 'A2 A',
  status: 'active',
  branch: 'Reconquista',
  level: 'A2',
  year: '2026',
);

Future<void> _pumpProfessorDetail(
  WidgetTester tester,
  _FakeClassroomRepository repository,
  _FakeMaterialRepository materialRepository,
) async {
  final router = GoRouter(
    initialLocation: '/classrooms/c1',
    routes: [
      GoRoute(
        path: '/classrooms/:id',
        builder: (_, state) => ClassroomDetailScreen(
          classroomId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/classrooms/:id/attendance',
        builder: (_, __) => const Scaffold(body: Text('pantalla asistencia')),
      ),
      GoRoute(
        path: '/classrooms/:id/grades',
        builder: (_, __) => const Scaffold(body: Text('pantalla notas')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      classroomRepositoryProvider.overrideWithValue(repository),
      materialRepositoryProvider.overrideWithValue(materialRepository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStudentDetail(
  WidgetTester tester,
  _FakeClassroomRepository repository,
  _FakeMaterialRepository materialRepository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(_FakeAuthRepository(role: 'student')),
        classroomRepositoryProvider.overrideWithValue(repository),
        materialRepositoryProvider.overrideWithValue(materialRepository),
      ],
      child: localizedApp(
        home: const ClassroomDetailScreen(classroomId: 'c1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(TabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpMaterialsTab(
  WidgetTester tester, {
  required _FakeClassroomRepository repository,
  required _FakeMaterialRepository materialRepository,
  Future<List<MaterialUploadFile>> Function()? pickFiles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        classroomRepositoryProvider.overrideWithValue(repository),
        materialRepositoryProvider.overrideWithValue(materialRepository),
      ],
      child: localizedApp(
        home: Scaffold(
          body: ClassroomMaterialsTab(
            classroomId: 'c1',
            canManage: true,
            pickFiles: pickFiles,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es', 'AR'));
  });

  testWidgets('el profesor ve el CTA y el menú en la pestaña Materiales',
      (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Apunte 1')];
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials),
    );

    await _openTab(tester, 'Materiales');

    expect(find.text('Cargar material'), findsOneWidget);
    expect(
      find.byIcon(PhosphorIconsRegular.dotsThreeVertical),
      findsOneWidget,
    );
  });

  testWidgets('el alumno no ve el CTA ni el menú', (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Apunte 1')];
    await _pumpStudentDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials),
    );

    await _openTab(tester, 'Materiales');

    expect(find.text('Cargar material'), findsNothing);
    expect(
      find.byIcon(PhosphorIconsRegular.dotsThreeVertical),
      findsNothing,
    );
  });

  testWidgets('el tile muestra el conteo de alumnos específicos',
      (tester) async {
    final materials = [
      const MaterialModel(
        id: 'm1',
        name: 'Apunte 1',
        visibility: 'specific',
        studentIds: ['s1', 's2'],
      ),
    ];
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials),
    );

    await _openTab(tester, 'Materiales');

    expect(find.text('2 alumnos'), findsOneWidget);
  });

  testWidgets('un material legado sin archivos renderiza sin romper',
      (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Solo link')];
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials),
    );

    await _openTab(tester, 'Materiales');

    expect(find.text('Solo link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar Cargar material abre el formulario', (tester) async {
    final materials = <MaterialModel>[];
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials),
    );

    await _openTab(tester, 'Materiales');
    await tester.tap(find.text('Cargar material'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialFormSheet), findsOneWidget);
    expect(find.text('Nuevo material'), findsOneWidget);
  });

  testWidgets('Editar abre el formulario con el material precargado',
      (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Apunte 1')];
    final materialRepo = _FakeMaterialRepository(
      sharedMaterials: materials,
      detail: const MaterialModel(id: 'm1', name: 'Apunte 1'),
    );
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      materialRepo,
    );

    await _openTab(tester, 'Materiales');
    await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialFormSheet), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Apunte 1'), findsOneWidget);
  });

  testWidgets('Eliminar confirma, borra, refresca y muestra el snackbar',
      (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Apunte 1')];
    final materialRepo = _FakeMaterialRepository(sharedMaterials: materials);
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      materialRepo,
    );

    await _openTab(tester, 'Materiales');
    await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar material?'), findsOneWidget);

    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(materialRepo.deleteCalls, 1);
    expect(find.text('Sin materiales'), findsOneWidget);
    expect(find.text('Material eliminado'), findsOneWidget);
  });

  testWidgets('un error al eliminar muestra el snackbar sin romper',
      (tester) async {
    final materials = [const MaterialModel(id: 'm1', name: 'Apunte 1')];
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom, materials: materials),
      _FakeMaterialRepository(sharedMaterials: materials, failDelete: true),
    );

    await _openTab(tester, 'Materiales');
    await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo eliminar el material'), findsOneWidget);
    expect(find.text('Apunte 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crear desde la pestaña publica y refresca la lista',
      (tester) async {
    final materials = <MaterialModel>[];
    final materialRepo = _FakeMaterialRepository(sharedMaterials: materials);
    await _pumpMaterialsTab(
      tester,
      repository: _FakeClassroomRepository(
        classroom: _classroom,
        materials: materials,
      ),
      materialRepository: materialRepo,
      pickFiles: () async => [
        MaterialUploadFile(
          name: 'guia.pdf',
          size: 1000,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ],
    );

    await tester.tap(find.text('Cargar material'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Guía nueva');
    await tester.ensureVisible(find.text(es.materialFormPickFiles));
    await tester.pumpAndSettle();
    await tester.tap(find.text(es.materialFormPickFiles));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, es.materialFormSave),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, es.materialFormSave));
    await tester.pumpAndSettle();

    expect(materialRepo.createCalls, 1);
    expect(materialRepo.createdName, 'Guía nueva');
    expect(find.byType(MaterialFormSheet), findsNothing);
    expect(find.text('Material publicado'), findsOneWidget);
    expect(find.text('Guía nueva'), findsOneWidget);
  });
}
