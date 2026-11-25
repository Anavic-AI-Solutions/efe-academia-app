import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/domain/invoice_file.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/qualifications/screens/widgets/qualification_form_sheet.dart';
import 'package:efe_mobile/features/qualifications/screens/widgets/qualification_manager_sheet.dart';
import 'package:efe_mobile/features/requests/data/request_repository.dart';
import 'package:efe_mobile/features/requests/domain/request_model.dart';
import 'package:efe_mobile/features/requests/providers/request_provider.dart';
import 'package:efe_mobile/features/students/data/absence_repository.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/absence_model.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/domain/student_parent_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void seed(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

class _CreateCall {
  final String studentId;
  final String classroomId;
  final String score;
  final String type;
  final String period;

  const _CreateCall({
    required this.studentId,
    required this.classroomId,
    required this.score,
    required this.type,
    required this.period,
  });
}

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.classrooms = const []});

  final List<ClassroomModel> classrooms;

  @override
  Future<StudentModel> getStudent(String id) async => _student;

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async =>
      classrooms;

  @override
  Future<List<StudentParentModel>> getParents(String studentId) async =>
      const [];

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) =>
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
}

class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({this.items = const []});

  final List<QualificationModel> items;
  final List<_CreateCall> createCalls = [];
  int studentGradesCalls = 0;

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async {
    studentGradesCalls++;
    return PageResult(
      data: items,
      page: page,
      perPage: limit,
      total: items.length,
    );
  }

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) async =>
      ClassroomGradesSummary(
        classroomId: classroomId,
        classroomName: '3G X',
        students: const [
          ClassroomGradeStudent(studentId: 's1', fullname: 'Ana Gómez'),
        ],
      );

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) async {
    createCalls.add(
      _CreateCall(
        studentId: studentId,
        classroomId: classroomId,
        score: score,
        type: type,
        period: period,
      ),
    );
  }

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
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) async =>
      CursorPagination<QualificationModel>.empty();

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) =>
      Future.error(UnimplementedError());

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) =>
      Future.error(UnimplementedError());
}

class _FakeAbsenceRepository implements AbsenceRepository {
  @override
  Future<PageResult<AbsenceModel>> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult<AbsenceModel>(
        data: const [],
        page: page,
        perPage: limit,
        total: 0,
      );
}

class _FakeFeeRepository implements FeeRepository {
  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult<FeeModel>(
        data: const [],
        page: page,
        perPage: limit,
        total: 0,
      );

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<FeeModel> getFee(String id) => Future.error(UnimplementedError());

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<String> getInvoiceUrl(String feeId) =>
      Future.error(UnimplementedError());

  @override
  Future<InvoiceFile> getInvoiceFile(String feeId) =>
      Future.error(UnimplementedError());
}

class _FakeRequestRepository implements RequestRepository {
  @override
  Future<PageResult<RequestModel>> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<RequestModel> getRequest(RequestKind kind, String id) =>
      Future.error(UnimplementedError());

  @override
  Future<bool> approve(RequestModel request, {String? classroomId}) =>
      Future.error(UnimplementedError());

  @override
  Future<bool> reject(RequestModel request) =>
      Future.error(UnimplementedError());
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboard() async => const DashboardData();
}

const _student = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'active',
  classroomCount: 2,
);

QualificationModel _grade({
  String id = 'q1',
  String classroomId = 'c1',
  String classroomName = '3G X',
}) {
  return QualificationModel(
    id: id,
    studentId: 's1',
    score: 8,
    scoreLabel: '8',
    type: 'Parcial',
    period: '1',
    classroomId: classroomId,
    classroomName: classroomName,
  );
}

class _Harness {
  _Harness({
    required this.qualifications,
  });

  final _FakeQualificationRepository qualifications;
}

Future<_Harness> _pumpDetail(
  WidgetTester tester, {
  required String role,
  List<ClassroomModel> classrooms = const [],
  List<QualificationModel> grades = const [],
  String? classroomId,
}) async {
  final auth = _TestAuthNotifier()
    ..seed(
      UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: role,
      ),
    );
  final qualifications = _FakeQualificationRepository(items: grades);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => auth),
        studentRepositoryProvider.overrideWithValue(
          _FakeStudentRepository(classrooms: classrooms),
        ),
        qualificationRepositoryProvider.overrideWithValue(qualifications),
        absenceRepositoryProvider.overrideWithValue(_FakeAbsenceRepository()),
        feeRepositoryProvider.overrideWithValue(_FakeFeeRepository()),
        requestRepositoryProvider.overrideWithValue(_FakeRequestRepository()),
        dashboardRepositoryProvider
            .overrideWithValue(_FakeDashboardRepository()),
      ],
      child: localizedApp(
        home: StudentDetailScreen(
          studentId: 's1',
          classroomId: classroomId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(qualifications: qualifications);
}

Future<void> _fillAndSave(WidgetTester tester, String score) async {
  await tester.enterText(
    find.byKey(const Key('qualification-form-score')),
    score,
  );
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el admin ve cargar y gestionar notas', (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('Cargar nota'), findsOneWidget);
    expect(find.text('Gestionar notas'), findsOneWidget);
  });

  testWidgets('el profesor ve cargar y gestionar notas', (tester) async {
    await _pumpDetail(
      tester,
      role: 'professor',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('Cargar nota'), findsOneWidget);
    expect(find.text('Gestionar notas'), findsOneWidget);
  });

  testWidgets('la sede ve cargar y gestionar notas', (tester) async {
    await _pumpDetail(
      tester,
      role: 'branch',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('Cargar nota'), findsOneWidget);
    expect(find.text('Gestionar notas'), findsOneWidget);
  });

  testWidgets('el alumno no ve acciones de notas', (tester) async {
    await _pumpDetail(
      tester,
      role: 'student',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('Cargar nota'), findsNothing);
    expect(find.text('Gestionar notas'), findsNothing);
  });

  testWidgets('el padre no ve acciones de notas', (tester) async {
    await _pumpDetail(
      tester,
      role: 'parent',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('Cargar nota'), findsNothing);
    expect(find.text('Gestionar notas'), findsNothing);
  });

  testWidgets('gestionar notas abre la hoja del alumno', (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
      grades: [_grade()],
    );

    await tester.tap(find.text('Gestionar notas'));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationManagerSheet), findsOneWidget);
    expect(find.text('Notas del alumno'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsWidgets);
    expect(find.text('3G X'), findsWidgets);
  });

  testWidgets('al cerrar la hoja de gestión se refrescan las notas',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      role: 'admin',
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
      grades: [_grade()],
    );
    final callsBefore = harness.qualifications.studentGradesCalls;
    expect(callsBefore, greaterThan(0));

    await tester.tap(find.text('Gestionar notas'));
    await tester.pumpAndSettle();
    expect(find.byType(QualificationManagerSheet), findsOneWidget);

    // Cierra la hoja tocando el barrier.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationManagerSheet), findsNothing);
    expect(
      harness.qualifications.studentGradesCalls,
      greaterThan(callsBefore),
    );
  });

  testWidgets('el admin carga una nota en un aula del alumno', (tester) async {
    final harness = await _pumpDetail(
      tester,
      role: 'admin',
      classrooms: const [
        ClassroomModel(id: 'c1', name: '3G X'),
        ClassroomModel(id: 'c2', name: '4A Y'),
      ],
    );

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationFormSheet), findsOneWidget);
    expect(find.text('3G X'), findsOneWidget);

    // Las opciones salen de las aulas del alumno, no del dashboard.
    await tester.tap(find.byKey(const Key('qualification-form-classroom')));
    await tester.pumpAndSettle();
    expect(find.text('4A Y'), findsOneWidget);
    await tester.tap(find.text('4A Y').last);
    await tester.pumpAndSettle();

    await _fillAndSave(tester, '8.5');

    final call = harness.qualifications.createCalls.single;
    expect(call.studentId, 's1');
    expect(call.classroomId, 'c2');
    expect(call.score, '8.5');
    expect(call.type, 'Parcial');
    expect(call.period, currentAcademicPeriod());
  });

  testWidgets('classroomId fija el aula del formulario', (tester) async {
    final harness = await _pumpDetail(
      tester,
      role: 'admin',
      classroomId: 'c2',
      classrooms: const [
        ClassroomModel(id: 'c1', name: '3G X'),
        ClassroomModel(id: 'c2', name: '4A Y'),
      ],
    );

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationFormSheet), findsOneWidget);
    expect(find.byKey(const Key('qualification-form-classroom')), findsNothing);

    await _fillAndSave(tester, '7');

    final call = harness.qualifications.createCalls.single;
    expect(call.studentId, 's1');
    expect(call.classroomId, 'c2');
  });
}
