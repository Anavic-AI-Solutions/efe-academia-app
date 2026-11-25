import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/parents/data/parent_repository.dart';
import 'package:efe_mobile/features/parents/domain/parent_model.dart';
import 'package:efe_mobile/features/parents/providers/parent_provider.dart';
import 'package:efe_mobile/features/parents/screens/parent_detail_screen.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/domain/student_parent_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.role);

  final String role;

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
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

const _sofia = StudentModel(
  id: 's1',
  fullname: 'Sofía Ramírez',
  year: '1° Año',
  status: 'approved',
);
const _lucas = StudentModel(
  id: 's2',
  fullname: 'Lucas Pérez',
  year: '2° Año',
  status: 'approved',
);
const _marta = StudentModel(
  id: 's3',
  fullname: 'Marta Ruiz',
  year: '3° Año',
  status: 'approved',
);

class _FakeParentRepository implements ParentRepository {
  _FakeParentRepository({List<StudentModel>? students})
      : students = List.of(students ?? const [_sofia, _lucas]);

  final List<StudentModel> catalog = const [_sofia, _lucas, _marta];
  final List<StudentModel> students;

  Object? studentsError;
  Object? linkError;
  Object? unlinkError;
  int parentDetailCalls = 0;

  final List<String> linked = [];
  final List<String> unlinked = [];

  @override
  Future<CursorPagination<ParentModel>> getParents({
    String? search,
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ParentModel> getParent(String id) async {
    parentDetailCalls++;
    return ParentModel(
      id: id,
      fullname: 'Lucía Fernández',
      email: 'lucia@example.com',
      phone: '3415551234',
      status: 'approved',
      studentCount: students.length,
    );
  }

  @override
  Future<ParentModel> createParent({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String status = 'pending',
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ParentModel> updateParent(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    required String status,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteParent(String id) => Future.error(UnimplementedError());

  @override
  Future<List<StudentModel>> getParentStudents(String parentId) async {
    final error = studentsError;
    if (error != null) throw error;
    return List.of(students);
  }

  @override
  Future<void> linkStudent(String parentId, String studentId) async {
    linked.add(studentId);
    final error = linkError;
    if (error != null) throw error;
    final student = catalog.firstWhere((student) => student.id == studentId);
    if (!students.any((current) => current.id == studentId)) {
      students.add(student);
    }
  }

  @override
  Future<void> unlinkStudent(String parentId, String studentId) async {
    unlinked.add(studentId);
    final error = unlinkError;
    if (error != null) throw error;
    students.removeWhere((student) => student.id == studentId);
  }
}

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({
    this.catalog = const [_sofia, _lucas, _marta],
  });

  final List<StudentModel> catalog;

  Object? listError;
  final List<Map<String, Object?>> listCalls = [];

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    listCalls.add({
      'search': search,
      'page': page,
      'limit': limit,
    });
    final error = listError;
    if (error != null) throw error;
    final query = (search ?? '').toLowerCase();
    final filtered = query.isEmpty
        ? List.of(catalog)
        : catalog
            .where(
              (student) => student.fullname.toLowerCase().contains(query),
            )
            .toList();
    return PageResult<StudentModel>(
      data: filtered,
      page: page,
      perPage: limit,
      total: filtered.length,
    );
  }

  @override
  Future<StudentModel> getStudent(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<StudentModel> createStudent({
    required String fullname,
    required String email,
    required String year,
    required String branch,
    required String identityNumber,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<StudentModel> updateStudent(
    String id, {
    required String fullname,
    required String email,
    required String year,
    required String branch,
    required String identityNumber,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deactivateStudent(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<void> reactivateStudent(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<StudentParentModel>> getParents(String studentId) =>
      Future.error(UnimplementedError());
}

Future<_FakeParentRepository> _pumpDetail(
  WidgetTester tester, {
  String role = 'admin',
  _FakeParentRepository? repository,
  _FakeStudentRepository? studentRepository,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? _FakeParentRepository();
  final students = studentRepository ?? _FakeStudentRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        parentRepositoryProvider.overrideWithValue(repo),
        studentRepositoryProvider.overrideWithValue(students),
      ],
      child: localizedApp(home: const ParentDetailScreen(parentId: 'pa1')),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder _linkButton() => find.byKey(const Key('parent-link-student'));

Future<void> _openLinkSheet(WidgetTester tester) async {
  await tester.tap(_linkButton());
  await tester.pumpAndSettle();
}

Finder _searchField() => find.descendant(
      of: find.byKey(const Key('link-student-search')),
      matching: find.byType(TextField),
    );

Finder _inSheet(Finder matching) => find.descendant(
      of: find.byKey(const Key('link-student-sheet')),
      matching: matching,
    );

void main() {
  group('parent linked students', () {
    testWidgets('renders the linked students with name and year',
        (tester) async {
      await _pumpDetail(tester);

      expect(find.text('ALUMNOS VINCULADOS'), findsOneWidget);
      expect(find.text('Sofía Ramírez'), findsOneWidget);
      expect(find.text('1° Año'), findsOneWidget);
      expect(find.text('Lucas Pérez'), findsOneWidget);
      expect(find.text('2° Año'), findsOneWidget);
      expect(find.text('2 alumnos'), findsOneWidget);
    });

    testWidgets('renders the empty state when there are no linked students',
        (tester) async {
      await _pumpDetail(
        tester,
        repository: _FakeParentRepository(students: const []),
      );

      expect(find.text('Sin alumnos vinculados'), findsOneWidget);
      expect(find.text('Sofía Ramírez'), findsNothing);
    });

    testWidgets('renders the load error with a retry', (tester) async {
      final repo = _FakeParentRepository()..studentsError = Exception('boom');
      await _pumpDetail(tester, repository: repo);

      expect(
        find.text('No se pudieron cargar los estudiantes'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);

      repo.studentsError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Sofía Ramírez'), findsOneWidget);
    });

    for (final role in ['admin', 'branch']) {
      testWidgets('$role can link and unlink students', (tester) async {
        await _pumpDetail(tester, role: role);

        expect(_linkButton(), findsOneWidget);
        expect(find.byKey(const Key('parent-unlink-s1')), findsOneWidget);
      });
    }

    for (final role in ['professor', 'student']) {
      testWidgets('$role sees the linked students read-only', (tester) async {
        await _pumpDetail(tester, role: role);

        expect(find.text('Sofía Ramírez'), findsOneWidget);
        expect(
          _linkButton(),
          findsNothing,
          reason: 'role $role must not link students',
        );
        expect(
          find.byKey(const Key('parent-unlink-s1')),
          findsNothing,
          reason: 'role $role must not unlink students',
        );
      });
    }

    testWidgets('unlink asks for confirmation and does nothing on cancel',
        (tester) async {
      final repo = await _pumpDetail(tester);

      await tester.tap(find.byKey(const Key('parent-unlink-s1')));
      await tester.pumpAndSettle();

      expect(find.text('Desvincular alumno'), findsOneWidget);
      expect(
        find.text('El alumno dejará de estar vinculado, pero no se elimina.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.unlinked, isEmpty);
      expect(find.text('Sofía Ramírez'), findsOneWidget);
      expect(find.text('2 alumnos'), findsOneWidget);
    });

    testWidgets('unlink confirms, refreshes the list and the detail count',
        (tester) async {
      final repo = await _pumpDetail(tester);

      await tester.tap(find.byKey(const Key('parent-unlink-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desvincular'));
      await tester.pumpAndSettle();

      expect(repo.unlinked, ['s1']);
      expect(find.text('Sofía Ramírez'), findsNothing);
      expect(find.text('Lucas Pérez'), findsOneWidget);
      expect(find.text('1 alumno'), findsOneWidget);
      expect(find.text('Alumno desvinculado'), findsOneWidget);
      expect(repo.parentDetailCalls, greaterThan(1));
    });

    testWidgets('unlink failure keeps the student and shows an error',
        (tester) async {
      final repo = _FakeParentRepository()..unlinkError = Exception('boom');
      await _pumpDetail(tester, repository: repo);

      await tester.tap(find.byKey(const Key('parent-unlink-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desvincular'));
      await tester.pumpAndSettle();

      expect(repo.unlinked, ['s1']);
      expect(find.text('Sofía Ramírez'), findsOneWidget);
      expect(find.text('2 alumnos'), findsOneWidget);
      expect(
        find.text('No se pudo desvincular el alumno'),
        findsOneWidget,
      );
    });
  });

  group('link student sheet', () {
    testWidgets('opens with the student search and lists results',
        (tester) async {
      final students = _FakeStudentRepository();
      await _pumpDetail(tester, studentRepository: students);

      await _openLinkSheet(tester);

      expect(find.byKey(const Key('link-student-sheet')), findsOneWidget);
      expect(find.text('Buscar alumnos...'), findsOneWidget);
      expect(students.listCalls, hasLength(1));
      expect(students.listCalls.single['page'], 1);
      expect(students.listCalls.single['limit'], 20);
      expect(find.byKey(const Key('link-student-s3')), findsOneWidget);
    });

    testWidgets('debounces the search before querying students',
        (tester) async {
      final students = _FakeStudentRepository();
      await _pumpDetail(tester, studentRepository: students);
      await _openLinkSheet(tester);

      await tester.enterText(_searchField(), 'Lu');
      await tester.pump(const Duration(milliseconds: 150));

      expect(students.listCalls, hasLength(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(students.listCalls, hasLength(2));
      expect(students.listCalls.last['search'], 'Lu');
      expect(students.listCalls.last['page'], 1);
      expect(students.listCalls.last['limit'], 20);
      expect(_inSheet(find.text('Lucas Pérez')), findsOneWidget);
      expect(_inSheet(find.text('Sofía Ramírez')), findsNothing);
    });

    testWidgets('renders the empty search results', (tester) async {
      await _pumpDetail(
        tester,
        studentRepository: _FakeStudentRepository(catalog: const []),
      );

      await _openLinkSheet(tester);

      expect(find.text('No se encontraron estudiantes'), findsOneWidget);
    });

    testWidgets('renders the search error and retries', (tester) async {
      final students = _FakeStudentRepository()..listError = Exception('boom');
      await _pumpDetail(tester, studentRepository: students);

      await _openLinkSheet(tester);

      expect(
        find.text('No se pudieron cargar los estudiantes'),
        findsOneWidget,
      );

      students.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(_inSheet(find.text('Sofía Ramírez')), findsOneWidget);
    });

    testWidgets('tapping a student links it, closes and refreshes',
        (tester) async {
      final repo = await _pumpDetail(tester);

      await _openLinkSheet(tester);
      await tester.tap(find.byKey(const Key('link-student-s3')));
      await tester.pumpAndSettle();

      expect(repo.linked, ['s3']);
      expect(find.byKey(const Key('link-student-sheet')), findsNothing);
      expect(find.text('Marta Ruiz'), findsOneWidget);
      expect(find.text('3 alumnos'), findsOneWidget);
      expect(find.text('Alumno vinculado'), findsOneWidget);
      expect(repo.parentDetailCalls, greaterThan(1));
    });

    testWidgets('link failure shows an inline error in the open sheet',
        (tester) async {
      final repo = _FakeParentRepository()..linkError = Exception('boom');
      await _pumpDetail(tester, repository: repo);

      await _openLinkSheet(tester);
      await tester.tap(find.byKey(const Key('link-student-s3')));
      await tester.pumpAndSettle();

      expect(repo.linked, ['s3']);
      expect(find.byKey(const Key('link-student-sheet')), findsOneWidget);
      expect(find.byKey(const Key('link-student-error')), findsOneWidget);
      expect(
        _inSheet(find.text('No se pudo vincular el alumno')),
        findsOneWidget,
      );
      // The modal sheet covers the Scaffold's snackbar host, so the failure
      // must be reported inside the sheet instead of via a snackbar.
      expect(find.byType(SnackBar), findsNothing);
      expect(repo.students.any((student) => student.id == 's3'), isFalse);

      // Retrying clears the inline error and links the student.
      repo.linkError = null;
      await tester.tap(find.byKey(const Key('link-student-s3')));
      await tester.pumpAndSettle();

      expect(repo.linked, ['s3', 's3']);
      expect(find.byKey(const Key('link-student-sheet')), findsNothing);
      expect(find.text('Marta Ruiz'), findsOneWidget);
    });

    testWidgets('searching again clears the link error', (tester) async {
      final repo = _FakeParentRepository()..linkError = Exception('boom');
      await _pumpDetail(tester, repository: repo);

      await _openLinkSheet(tester);
      await tester.tap(find.byKey(const Key('link-student-s3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('link-student-error')), findsOneWidget);

      repo.linkError = null;
      await tester.enterText(_searchField(), 'Lu');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('link-student-error')), findsNothing);
      expect(_inSheet(find.text('Lucas Pérez')), findsOneWidget);
    });
  });
}
