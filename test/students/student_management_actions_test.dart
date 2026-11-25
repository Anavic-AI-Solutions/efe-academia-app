import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/domain/student_parent_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_detail_screen.dart';
import 'package:efe_mobile/features/students/screens/student_list_screen.dart';
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

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.student});

  final StudentModel? student;
  final List<String> deactivated = [];
  final List<String> reactivated = [];
  int getStudentCalls = 0;
  int getStudentsCalls = 0;
  Object? deactivateError;
  Object? reactivateError;

  @override
  Future<StudentModel> getStudent(String id) async {
    getStudentCalls++;
    return student!;
  }

  @override
  Future<void> deactivateStudent(String id) async {
    deactivated.add(id);
    final error = deactivateError;
    if (error != null) throw error;
  }

  @override
  Future<void> reactivateStudent(String id) async {
    reactivated.add(id);
    final error = reactivateError;
    if (error != null) throw error;
  }

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    getStudentsCalls++;
    return PageResult.empty(perPage: limit);
  }

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async =>
      const [];

  @override
  Future<List<StudentParentModel>> getParents(String studentId) async =>
      const [];

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
}

class _FakeQualificationRepository implements QualificationRepository {
  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) =>
      Future.error(UnimplementedError());

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateQualification({
    required String id,
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? category,
    String? description,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteQualification(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) =>
      Future.error(UnimplementedError());

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) =>
      Future.error(UnimplementedError());
}

const _activeStudent = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'active',
);

const _inactiveStudent = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'inactive',
);

const _unknownStatusStudent = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'suspended',
);

Future<void> _pumpList(WidgetTester tester, String role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
      ],
      child: localizedApp(home: const StudentListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<_FakeStudentRepository> _pumpDetail(
  WidgetTester tester, {
  required String role,
  required StudentModel student,
}) async {
  final repository = _FakeStudentRepository(student: student);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        studentRepositoryProvider.overrideWithValue(repository),
        qualificationRepositoryProvider
            .overrideWithValue(_FakeQualificationRepository()),
      ],
      child: localizedApp(
        home: StudentDetailScreen(studentId: student.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _openActions(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('student-detail-actions')));
  await tester.pumpAndSettle();
}

/// Initializes the list provider and waits for its load so the tests can
/// assert the exact number of `getStudents` calls triggered by an action.
Future<void> _primeStudentList(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(StudentDetailScreen)),
  );
  await container.read(studentListProvider.notifier).refresh();
  await tester.pumpAndSettle();
}

void main() {
  for (final role in ['admin', 'branch', 'sede']) {
    testWidgets('$role sees the create FAB on the student list',
        (tester) async {
      await _pumpList(tester, role);

      expect(find.byKey(const Key('student-list-fab')), findsOneWidget);
      expect(find.byTooltip('Crear'), findsOneWidget);
    });
  }

  for (final role in ['professor', 'student', 'parent']) {
    testWidgets('$role does not see the create FAB on the student list',
        (tester) async {
      await _pumpList(tester, role);

      expect(find.byKey(const Key('student-list-fab')), findsNothing);
      expect(find.byTooltip('Crear'), findsNothing);
    });
  }

  for (final role in ['admin', 'branch', 'sede']) {
    testWidgets('$role sees the detail actions menu', (tester) async {
      await _pumpDetail(
        tester,
        role: role,
        student: _activeStudent,
      );

      expect(
        find.byKey(const Key('student-detail-actions')),
        findsOneWidget,
      );
    });
  }

  for (final role in ['professor', 'student', 'parent']) {
    testWidgets('$role does not see the detail actions menu', (tester) async {
      await _pumpDetail(
        tester,
        role: role,
        student: _activeStudent,
      );

      expect(
        find.byKey(const Key('student-detail-actions')),
        findsNothing,
      );
    });
  }

  testWidgets('staff menu offers edit and deactivate for an active student',
      (tester) async {
    await _pumpDetail(tester, role: 'admin', student: _activeStudent);

    await _openActions(tester);

    expect(find.text('Editar alumno'), findsOneWidget);
    expect(find.text('Desactivar alumno'), findsOneWidget);
    expect(find.text('Reactivar alumno'), findsNothing);
  });

  testWidgets('staff menu offers reactivate for an inactive student',
      (tester) async {
    await _pumpDetail(tester, role: 'admin', student: _inactiveStudent);

    await _openActions(tester);

    expect(find.text('Editar alumno'), findsOneWidget);
    expect(find.text('Reactivar alumno'), findsOneWidget);
    expect(find.text('Desactivar alumno'), findsNothing);
  });

  testWidgets('staff menu offers deactivate for an unknown status',
      (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      student: _unknownStatusStudent,
    );

    await _openActions(tester);

    expect(find.text('Editar alumno'), findsOneWidget);
    expect(find.text('Desactivar alumno'), findsOneWidget);
    expect(find.text('Reactivar alumno'), findsNothing);
  });

  testWidgets(
      'deactivating asks for confirmation, calls the repo and refreshes',
      (tester) async {
    final repository = await _pumpDetail(
      tester,
      role: 'admin',
      student: _activeStudent,
    );
    await _primeStudentList(tester);
    final detailCallsBefore = repository.getStudentCalls;
    final listCallsBefore = repository.getStudentsCalls;

    await _openActions(tester);
    await tester.tap(find.text('Desactivar alumno'));
    await tester.pumpAndSettle();

    expect(
      find.text('El alumno quedará inactivo y podrá reactivarse.'),
      findsOneWidget,
    );
    expect(repository.deactivated, isEmpty);

    await tester.tap(find.text('Desactivar alumno').last);
    await tester.pumpAndSettle();

    expect(repository.deactivated, ['s1']);
    expect(repository.reactivated, isEmpty);
    expect(repository.getStudentsCalls, listCallsBefore + 1);
    expect(repository.getStudentCalls, greaterThan(detailCallsBefore));
    expect(find.text('Alumno desactivado'), findsOneWidget);
  });

  testWidgets('deactivation failures report the status error', (tester) async {
    final repository = await _pumpDetail(
      tester,
      role: 'admin',
      student: _activeStudent,
    );
    repository.deactivateError = ApiException(message: 'boom');

    await _openActions(tester);
    await tester.tap(find.text('Desactivar alumno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar alumno').last);
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo actualizar el estado del alumno'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the confirmation leaves the student untouched',
      (tester) async {
    final repository = await _pumpDetail(
      tester,
      role: 'admin',
      student: _activeStudent,
    );
    await _primeStudentList(tester);
    final listCallsBefore = repository.getStudentsCalls;

    await _openActions(tester);
    await tester.tap(find.text('Desactivar alumno'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deactivated, isEmpty);
    expect(repository.getStudentsCalls, listCallsBefore);
  });

  testWidgets('reactivating calls the repo without confirmation and refreshes',
      (tester) async {
    final repository = await _pumpDetail(
      tester,
      role: 'branch',
      student: _inactiveStudent,
    );
    await _primeStudentList(tester);
    final detailCallsBefore = repository.getStudentCalls;
    final listCallsBefore = repository.getStudentsCalls;

    await _openActions(tester);
    await tester.tap(find.text('Reactivar alumno'));
    await tester.pumpAndSettle();

    expect(repository.reactivated, ['s1']);
    expect(repository.deactivated, isEmpty);
    expect(repository.getStudentsCalls, listCallsBefore + 1);
    expect(repository.getStudentCalls, greaterThan(detailCallsBefore));
    expect(find.text('Alumno reactivado'), findsOneWidget);
  });

  testWidgets('reactivation failures report the status error', (tester) async {
    final repository = await _pumpDetail(
      tester,
      role: 'admin',
      student: _inactiveStudent,
    );
    repository.reactivateError = ApiException(message: 'boom');

    await _openActions(tester);
    await tester.tap(find.text('Reactivar alumno'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo actualizar el estado del alumno'),
      findsOneWidget,
    );
  });
}
