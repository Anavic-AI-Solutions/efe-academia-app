import 'package:efe_mobile/core/api/page_pagination.dart';
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
import 'package:efe_mobile/features/classrooms/screens/classroom_list_screen.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/classroom_detail_header.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/professor_classroom_list_card.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/localized_app.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.role = 'admin'});

  final String role;

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'User Test',
        email: 'user@test.com',
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
    this.classroom = _classroom,
    this.failArchive = false,
    this.failDelete = false,
  });

  ClassroomModel classroom;
  final bool failArchive;
  final bool failDelete;

  int getClassroomsCalls = 0;
  int getClassroomCalls = 0;
  int setArchivedCalls = 0;
  int deleteCalls = 0;
  bool? lastArchived;

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
    getClassroomsCalls++;
    return PageResult(
      data: [classroom],
      page: page,
      perPage: limit,
      total: 1,
    );
  }

  @override
  Future<ClassroomModel> getClassroom(String id) async {
    getClassroomCalls++;
    return classroom;
  }

  @override
  Future<ClassroomModel> setArchived(String id, bool isArchived) async {
    setArchivedCalls++;
    lastArchived = isArchived;
    if (failArchive) throw Exception('archive boom');
    classroom = classroom.copyWith(isArchived: isArchived);
    return classroom;
  }

  @override
  Future<void> deleteClassroom(String id) async {
    deleteCalls++;
    if (failDelete) throw Exception('delete boom');
  }

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<ClassroomFilters> getFilters() async => const ClassroomFilters();

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
}

const _classroom = ClassroomModel(
  id: 'c1',
  name: 'A2 A',
  description: 'Curso de enfermería',
  status: 'active',
  shift: 'morning',
  day: 'Lunes',
  hour: '08:00',
  room: 'Aula 3',
  year: '2026',
  branch: 'Reconquista',
  level: 'A2',
  studentCount: 24,
);

class _PopStub extends StatelessWidget {
  const _PopStub(this.title, {this.result});

  final String title;
  final bool? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            ElevatedButton(
              onPressed: () => context.pop(result),
              child: const Text('volver'),
            ),
          ],
        ),
      ),
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/classrooms',
    routes: [
      GoRoute(
        path: '/classrooms',
        builder: (_, __) => const Scaffold(body: Text('lista de clases')),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const _PopStub('formulario nueva clase'),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => ClassroomDetailScreen(
              classroomId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) => const _PopStub(
                  'formulario editar',
                  result: true,
                ),
              ),
              GoRoute(
                path: 'attendance',
                builder: (_, __) => const Scaffold(
                  body: Text('pantalla asistencia'),
                ),
              ),
              GoRoute(
                path: 'grades',
                builder: (_, __) => const Scaffold(
                  body: Text('pantalla notas'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<ProviderContainer> _pumpDetail(
  WidgetTester tester,
  _FakeClassroomRepository repository, {
  String role = 'admin',
}) async {
  final router = _buildRouter();
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role: role)),
      classroomRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  // Keep the list provider alive so detail actions can refresh/invalidate it
  // even when the list screen itself is only a stub behind the detail.
  final subscription = container.listen(classroomListProvider, (_, __) {});
  addTearDown(subscription.close);

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

  router.push('/classrooms/c1');
  await tester.pumpAndSettle();

  return container;
}

Future<void> _pumpList(
  WidgetTester tester,
  _FakeClassroomRepository repository, {
  String role = 'admin',
}) async {
  final router = GoRouter(
    initialLocation: '/classrooms',
    routes: [
      GoRoute(
        path: '/classrooms',
        builder: (_, __) => const ClassroomListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const _PopStub('formulario nueva clase'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(role: role),
        ),
        classroomRepositoryProvider.overrideWithValue(repository),
        classroomFiltersProvider.overrideWith(
          (ref) => const ClassroomFilters(),
        ),
      ],
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

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('classroom-detail-actions')));
  await tester.pumpAndSettle();
}

void main() {
  group('List FAB', () {
    testWidgets('staff sees the create FAB', (tester) async {
      await _pumpList(tester, _FakeClassroomRepository(), role: 'admin');

      expect(find.byKey(const Key('classroom-list-fab')), findsOneWidget);
      expect(find.byTooltip('Crear'), findsOneWidget);
    });

    testWidgets('branch role sees the create FAB', (tester) async {
      await _pumpList(tester, _FakeClassroomRepository(), role: 'branch');

      expect(find.byKey(const Key('classroom-list-fab')), findsOneWidget);
    });

    testWidgets('professor does not see the create FAB', (tester) async {
      await _pumpList(tester, _FakeClassroomRepository(), role: 'professor');

      expect(find.byKey(const Key('classroom-list-fab')), findsNothing);
    });

    testWidgets('student does not see the create FAB', (tester) async {
      await _pumpList(tester, _FakeClassroomRepository(), role: 'student');

      expect(find.byKey(const Key('classroom-list-fab')), findsNothing);
    });

    testWidgets(
        'tapping the FAB opens the form and refreshes the list on return',
        (tester) async {
      final repository = _FakeClassroomRepository();
      await _pumpList(tester, repository);

      final callsBefore = repository.getClassroomsCalls;

      await tester.tap(find.byKey(const Key('classroom-list-fab')));
      await tester.pumpAndSettle();
      expect(find.text('formulario nueva clase'), findsOneWidget);

      await tester.tap(find.text('volver'));
      await tester.pumpAndSettle();

      expect(find.byType(ClassroomListScreen), findsOneWidget);
      expect(repository.getClassroomsCalls, greaterThan(callsBefore));
    });
  });

  group('Detail staff menu', () {
    testWidgets('admin sees the staff menu', (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository(), role: 'admin');

      expect(
        find.byKey(const Key('classroom-detail-actions')),
        findsOneWidget,
      );
    });

    testWidgets('sede sees the staff menu', (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository(), role: 'sede');

      expect(
        find.byKey(const Key('classroom-detail-actions')),
        findsOneWidget,
      );
    });

    testWidgets('professor keeps attendance and grades but has no staff menu',
        (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository(), role: 'professor');

      expect(find.text('Tomar asistencia'), findsOneWidget);
      expect(find.text('Cargar nota'), findsOneWidget);
      expect(
        find.byKey(const Key('classroom-detail-actions')),
        findsNothing,
      );
    });

    testWidgets('professor attendance action still opens its screen',
        (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository(), role: 'professor');

      await tester.tap(find.text('Tomar asistencia'));
      await tester.pumpAndSettle();

      expect(find.text('pantalla asistencia'), findsOneWidget);
    });

    testWidgets('student does not see the staff menu', (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository(), role: 'student');

      expect(
        find.byKey(const Key('classroom-detail-actions')),
        findsNothing,
      );
    });

    testWidgets('header supports the staff menu and professor actions together',
        (tester) async {
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: ClassroomDetailHeader(
              classroom: _classroom,
              showActions: true,
              onAttendance: () {},
              onGrades: () {},
              menu: const SizedBox(
                key: Key('custom-staff-menu'),
                child: Text('menú'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tomar asistencia'), findsOneWidget);
      expect(find.text('Cargar nota'), findsOneWidget);
      expect(find.byKey(const Key('custom-staff-menu')), findsOneWidget);
    });

    testWidgets('edit opens the form and refreshes detail and list on return',
        (tester) async {
      final repository = _FakeClassroomRepository();
      await _pumpDetail(tester, repository);

      final detailCallsBefore = repository.getClassroomCalls;
      final listCallsBefore = repository.getClassroomsCalls;

      await _openMenu(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('formulario editar'), findsOneWidget);

      await tester.tap(find.text('volver'));
      await tester.pumpAndSettle();

      expect(find.text('A2 A'), findsOneWidget);
      expect(repository.getClassroomCalls, greaterThan(detailCallsBefore));
      expect(repository.getClassroomsCalls, greaterThan(listCallsBefore));
    });

    testWidgets('archive calls setArchived, shows a snackbar and refreshes',
        (tester) async {
      final repository = _FakeClassroomRepository();
      await _pumpDetail(tester, repository);

      final detailCallsBefore = repository.getClassroomCalls;
      final listCallsBefore = repository.getClassroomsCalls;

      await _openMenu(tester);
      expect(find.text('Archivar clase'), findsOneWidget);
      await tester.tap(find.text('Archivar clase'));
      await tester.pumpAndSettle();

      expect(repository.setArchivedCalls, 1);
      expect(repository.lastArchived, isTrue);
      expect(find.text('Clase archivada'), findsOneWidget);
      expect(repository.getClassroomCalls, greaterThan(detailCallsBefore));
      expect(repository.getClassroomsCalls, greaterThan(listCallsBefore));

      await _openMenu(tester);
      expect(find.text('Desarchivar clase'), findsOneWidget);
    });

    testWidgets('unarchive calls setArchived with false', (tester) async {
      final repository = _FakeClassroomRepository(
        classroom: _classroom.copyWith(isArchived: true),
      );
      await _pumpDetail(tester, repository);

      await _openMenu(tester);
      expect(find.text('Desarchivar clase'), findsOneWidget);
      await tester.tap(find.text('Desarchivar clase'));
      await tester.pumpAndSettle();

      expect(repository.setArchivedCalls, 1);
      expect(repository.lastArchived, isFalse);
      expect(find.text('Clase desarchivada'), findsOneWidget);
    });

    testWidgets('archive failure shows the error snackbar and keeps the page',
        (tester) async {
      final repository = _FakeClassroomRepository(failArchive: true);
      await _pumpDetail(tester, repository);

      await _openMenu(tester);
      await tester.tap(find.text('Archivar clase'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo actualizar la clase'), findsOneWidget);
      expect(find.text('A2 A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('delete asks for confirmation and cancel keeps the detail',
        (tester) async {
      final repository = _FakeClassroomRepository();
      await _pumpDetail(tester, repository);

      await _openMenu(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar clase'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.deleteCalls, 0);
      expect(find.text('A2 A'), findsOneWidget);
    });

    testWidgets(
        'delete confirms, refreshes the list, pops and does not reload the detail',
        (tester) async {
      final repository = _FakeClassroomRepository();
      await _pumpDetail(tester, repository);

      final detailCallsBefore = repository.getClassroomCalls;
      final listCallsBefore = repository.getClassroomsCalls;

      await _openMenu(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(repository.deleteCalls, 1);
      expect(repository.getClassroomsCalls, greaterThan(listCallsBefore));
      expect(repository.getClassroomCalls, detailCallsBefore);
      expect(find.text('lista de clases'), findsOneWidget);
      expect(find.text('Clase eliminada'), findsOneWidget);
    });

    testWidgets('delete failure shows the error snackbar and keeps the page',
        (tester) async {
      final repository = _FakeClassroomRepository(failDelete: true);
      await _pumpDetail(tester, repository);

      await _openMenu(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(repository.deleteCalls, 1);
      expect(find.text('No se pudo eliminar'), findsOneWidget);
      expect(find.text('A2 A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Localized raw values', () {
    testWidgets('summary shows localized shift and status labels',
        (tester) async {
      await _pumpDetail(tester, _FakeClassroomRepository());

      expect(find.text('Activa'), findsOneWidget);
      expect(find.text('Mañana'), findsWidgets);
      expect(find.text('morning'), findsNothing);
    });

    testWidgets('list card shows the localized shift', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: ProfessorClassroomListCard(
              classroom: _classroom,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mañana · Lunes · 08:00'), findsOneWidget);
    });
  });
}
