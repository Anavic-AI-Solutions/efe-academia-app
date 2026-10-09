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
import 'package:efe_mobile/features/classrooms/screens/classroom_list_screen.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/professor_classroom_list_card.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/features/relations/providers/selected_child_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeParentAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u-parent',
        name: 'María López',
        email: 'maria@test.com',
        role: 'parent',
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

const _ana = RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11);
const _bruno = RelationModel(id: 'r2', fullname: 'Bruno Pérez', role: 'student', userId: 12);

class _FakeRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination(
        data: const [_ana, _bruno],
        nextCursor: null,
        hasMore: false,
        total: 2,
      );
}

class _FakeClassroomRepository implements ClassroomRepository {
  final List<String?> scopeCalls = [];

  PageResult<ClassroomModel> _page(List<ClassroomModel> data) => PageResult(
        data: data,
        page: 1,
        perPage: 20,
        total: data.length,
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
    String? studentId,
  }) async {
    scopeCalls.add(studentId);
    if (studentId == null) return _page(const []);
    return _page([
      ClassroomModel(id: 'c-$studentId', name: 'Aula de $studentId'),
    ]);
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      throw UnimplementedError();

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

class _ThrowingClassroomRepository implements ClassroomRepository {
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
    throw Exception('network error');
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      throw UnimplementedError();

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(String id,
          {int page = 1, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

Future<void> _pumpClassrooms(
  WidgetTester tester, {
  String? selected,
  _FakeClassroomRepository? repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      relationsRepositoryProvider.overrideWithValue(_FakeRelationsRepository()),
      classroomRepositoryProvider
          .overrideWithValue(repository ?? _FakeClassroomRepository()),
      if (selected != null)
        parentSelectedStudentProvider.overrideWith((ref) => selected),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClassroomListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('parent without selected child sees empty, not all classrooms',
      (tester) async {
    await _pumpClassrooms(tester);

    expect(find.byType(ProfessorClassroomListCard), findsNothing);
    expect(find.text('No se encontraron clases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent with selected child sees only that child classroom',
      (tester) async {
    final repo = _FakeClassroomRepository();
    await _pumpClassrooms(tester, selected: '11', repository: repo);

    expect(find.byType(ProfessorClassroomListCard), findsOneWidget);
    expect(find.text('Aula de 11'), findsOneWidget);
    expect(repo.scopeCalls.last, '11');
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching child reloads scoped classrooms', (tester) async {
    final repo = _FakeClassroomRepository();
    await _pumpClassrooms(tester, selected: '11', repository: repo);
    expect(repo.scopeCalls.last, '11');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Pérez').last);
    await tester.pumpAndSettle();

    expect(repo.scopeCalls.last, '12');
    expect(find.text('Aula de 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline classrooms show error with retry', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
        relationsRepositoryProvider
            .overrideWithValue(_FakeRelationsRepository()),
        classroomRepositoryProvider
            .overrideWithValue(_ThrowingClassroomRepository()),
        parentSelectedStudentProvider.overrideWith((ref) => '11'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClassroomListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
