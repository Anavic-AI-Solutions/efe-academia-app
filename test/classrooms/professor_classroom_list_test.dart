import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/classroom_list_screen.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/professor_classroom_list_card.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/professor_classrooms_header.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  final String role;

  _FakeAuthRepository(this.role);

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
  _FakeClassroomRepository({this.total = 2});

  final int total;

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
    if (total == 0) return PageResult.empty(perPage: limit);
    return PageResult(
      data: List.generate(
        total,
        (i) => ClassroomModel(
          id: 'room-${i + 1}',
          name: 'Aula ${i + 1}',
          status: 'active',
          shift: 'Mañana',
          day: 'Lunes',
          hour: '08:00',
          room: 'Sala ${i + 1}',
          studentCount: 24 + i,
        ),
      ),
      page: 1,
      perPage: limit,
      total: total,
    );
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
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
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());

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

  @override
  Future<void> deleteClassroom(String id) => Future.error(UnimplementedError());
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  String role = 'professor',
  int total = 2,
}) async {
  final router = GoRouter(
    initialLocation: '/classrooms',
    routes: [
      GoRoute(
        path: '/classrooms',
        builder: (_, __) => const ClassroomListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => Scaffold(
              body: Text('detalle ${state.pathParameters['id']}'),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
      classroomRepositoryProvider
          .overrideWithValue(_FakeClassroomRepository(total: total)),
      classroomFiltersProvider.overrideWith((ref) => const ClassroomFilters()),
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

void main() {
  testWidgets('professor sees the blue header, count and classroom cards',
      (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(ProfessorClassroomsHeader), findsOneWidget);
    expect(find.text('Mis aulas'), findsOneWidget);
    expect(find.text('2 aulas'), findsOneWidget);
    expect(find.byType(ProfessorClassroomListCard), findsNWidgets(2));
    expect(find.text('Aula 1'), findsOneWidget);
    expect(find.text('Mañana · Lunes · 08:00'), findsNWidgets(2));
    expect(find.text('Sala 1'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('tapping a professor card opens the classroom detail',
      (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Aula 2'));
    await tester.pumpAndSettle();

    expect(find.text('detalle room-2'), findsOneWidget);
  });

  testWidgets('professor without classrooms sees the assigned-empty message',
      (tester) async {
    await _pumpScreen(tester, total: 0);

    expect(find.text('Sin aulas asignadas'), findsOneWidget);
    expect(find.text('Todavía no tenés aulas asignadas'), findsOneWidget);
  });

  testWidgets('other roles see the same unified list with generic copy',
      (tester) async {
    await _pumpScreen(tester, role: 'student');

    expect(find.byType(ProfessorClassroomsHeader), findsOneWidget);
    expect(find.text('Clases'), findsOneWidget);
    expect(find.text('Mis aulas'), findsNothing);
    expect(find.byType(ProfessorClassroomListCard), findsNWidgets(2));
  });

  testWidgets('renders without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester);

    expect(find.text('Mis aulas'), findsOneWidget);
    expect(find.text('Sala 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta colorea con el estado crudo y muestra la etiqueta',
      (tester) async {
    await _pumpScreen(tester);

    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge).first);
    expect(badge.status, 'active');
    expect(badge.label, 'Activo');
  });
}
