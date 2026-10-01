import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/classroom_detail_screen.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
    this.classroom,
    this.fails = false,
    this.students = const [],
    this.professors = const [],
    this.materials = const [],
  });

  final ClassroomModel? classroom;
  final bool fails;
  final List<StudentModel> students;
  final List<ProfessorModel> professors;
  final List<MaterialModel> materials;

  @override
  Future<ClassroomModel> getClassroom(String id) async {
    if (fails) throw Exception('boom');
    return classroom!;
  }

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
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: professors,
        page: page,
        perPage: limit,
        total: professors.length,
      );

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: materials,
        page: page,
        perPage: limit,
        total: materials.length,
      );

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeClassroomRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(_FakeAuthRepository(role: 'student')),
        classroomRepositoryProvider.overrideWithValue(repository),
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

Future<void> _pumpProfessorDetail(
  WidgetTester tester,
  _FakeClassroomRepository repository,
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
      GoRoute(
        path: '/students/:id',
        builder: (_, state) => Scaffold(
          body: Text(
            'alumno ${state.pathParameters['id']} '
            'aula ${state.uri.queryParameters['classroomId']}',
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      classroomRepositoryProvider.overrideWithValue(repository),
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

const _classroom = ClassroomModel(
  id: 'c1',
  name: 'A2 A',
  description: 'Curso de enfermería',
  status: 'active',
  shift: 'Mañana',
  day: 'Lunes',
  hour: '08:00',
  room: 'Aula 3',
  year: '2026',
  branch: 'Reconquista',
  level: 'A2',
  grade: 'Primero',
  book: 'Libro 1',
  commission: 'A',
  courseDays: 3,
  studentCount: 24,
);

void main() {
  testWidgets('renders the hero header, tabs and summary sections',
      (tester) async {
    await _pumpDetail(tester, _FakeClassroomRepository(classroom: _classroom));

    expect(find.text('A2 A'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Reconquista'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Estudiantes'), findsWidgets);
    expect(find.text('Profesores'), findsOneWidget);
    expect(find.text('Materiales'), findsOneWidget);

    expect(find.text('24'), findsOneWidget);
    expect(find.text('Aula 3'), findsWidgets);
    expect(find.text('Mañana'), findsWidgets);
    expect(find.text('Curso de enfermería'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.text('Primero'), findsOneWidget);
    expect(find.text('Libro 1'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows the error view when the classroom fails to load',
      (tester) async {
    await _pumpDetail(tester, _FakeClassroomRepository(fails: true));

    expect(find.text('No se pudo cargar la clase'), findsOneWidget);
  });

  testWidgets('lists students on the students tab', (tester) async {
    await _pumpDetail(
      tester,
      _FakeClassroomRepository(
        classroom: _classroom,
        students: const [
          StudentModel(
            id: 's1',
            fullname: 'Ana Gómez',
            email: 'ana@example.com',
            status: 'active',
          ),
        ],
      ),
    );

    await _openTab(tester, 'Estudiantes');

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('shows empty states for related tabs', (tester) async {
    await _pumpDetail(tester, _FakeClassroomRepository(classroom: _classroom));

    await _openTab(tester, 'Estudiantes');
    expect(find.text('Sin estudiantes'), findsOneWidget);

    await _openTab(tester, 'Profesores');
    expect(find.text('Sin profesores'), findsOneWidget);

    await _openTab(tester, 'Materiales');
    expect(find.text('Sin materiales'), findsOneWidget);
  });

  testWidgets('lists professors and materials when present', (tester) async {
    await _pumpDetail(
      tester,
      _FakeClassroomRepository(
        classroom: _classroom,
        professors: const [
          ProfessorModel(
            id: 'p1',
            fullname: 'Ana Pérez',
            specialty: 'Matemática',
          ),
        ],
        materials: const [
          MaterialModel(
            id: 'm1',
            name: 'Apunte 1',
            category: 'teoria',
            downloadCount: 4,
          ),
        ],
      ),
    );

    await _openTab(tester, 'Profesores');
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Matemática'), findsOneWidget);

    await _openTab(tester, 'Materiales');
    expect(find.text('Apunte 1'), findsOneWidget);
    expect(find.text('teoria'), findsOneWidget);
    expect(find.text('4 descargas'), findsOneWidget);
  });

  testWidgets('professor sees the attendance and grade actions',
      (tester) async {
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom),
    );

    expect(find.text('Tomar asistencia'), findsOneWidget);
    expect(find.text('Cargar nota'), findsOneWidget);

    await tester.tap(find.text('Tomar asistencia'));
    await tester.pumpAndSettle();
    expect(find.text('pantalla asistencia'), findsOneWidget);
  });

  testWidgets('professor opens the grades screen from the hero',
      (tester) async {
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom),
    );

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla notas'), findsOneWidget);
  });

  testWidgets('detail hero hides the attendance and grade actions for other roles',
      (tester) async {
    await _pumpDetail(tester, _FakeClassroomRepository(classroom: _classroom));

    expect(find.text('Tomar asistencia'), findsNothing);
    expect(find.text('Cargar nota'), findsNothing);
  });

  testWidgets('professor hero renders without overflow on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(classroom: _classroom),
    );

    expect(find.text('Tomar asistencia'), findsOneWidget);
    expect(find.text('Cargar nota'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('related tabs use the default empty accent', (tester) async {
    await _pumpDetail(tester, _FakeClassroomRepository(classroom: _classroom));

    await _openTab(tester, 'Estudiantes');

    final empty = tester.widget<EmptyState>(find.byType(EmptyState));
    expect(empty.accentColor, isNull);
  });

  testWidgets('opening a student carries the classroom of origin',
      (tester) async {
    await _pumpProfessorDetail(
      tester,
      _FakeClassroomRepository(
        classroom: _classroom,
        students: const [
          StudentModel(
            id: 's1',
            fullname: 'Ana Gómez',
            email: 'ana@example.com',
            status: 'active',
          ),
        ],
      ),
    );

    await _openTab(tester, 'Estudiantes');
    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();

    expect(find.text('alumno s1 aula c1'), findsOneWidget);
  });
}
