import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/stat_card.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
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
import 'package:efe_mobile/features/students/screens/widgets/student_grades_grid.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.role = 'student'});

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
  _FakeStudentRepository({
    this.student,
    this.fails = false,
    this.parents = const [],
  });

  final StudentModel? student;
  final bool fails;
  final List<StudentParentModel> parents;

  @override
  Future<StudentModel> getStudent(String id) async {
    if (fails) throw Exception('boom');
    return student!;
  }

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async =>
      const [];

  @override
  Future<List<StudentParentModel>> getParents(String studentId) async =>
      parents;

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

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({required this.detail});

  final RequestModel detail;

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
  Future<RequestModel> getRequest(RequestKind kind, String id) async => detail;

  @override
  Future<bool> approve(RequestModel request, {String? classroomId}) =>
      Future.error(UnimplementedError());

  @override
  Future<bool> reject(RequestModel request) =>
      Future.error(UnimplementedError());
}

class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({this.items = const []});

  final List<QualificationModel> items;

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
      );

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

class _FakeAbsenceRepository implements AbsenceRepository {
  _FakeAbsenceRepository({this.items = const []});

  final List<AbsenceModel> items;

  @override
  Future<PageResult<AbsenceModel>> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
      );
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository();

  @override
  Future<DashboardData> getDashboard() async => const DashboardData();
}

class _FakeFeeRepository implements FeeRepository {
  _FakeFeeRepository({this.items = const []});

  final List<FeeModel> items;

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
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
  Future<Never> getInvoiceFile(String feeId) =>
      Future.error(UnimplementedError());
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  _FakeStudentRepository? students,
  _FakeQualificationRepository? qualifications,
  _FakeAbsenceRepository? absences,
  _FakeFeeRepository? fees,
  RequestRepository? requests,
  String role = 'student',
  String? classroomId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(_FakeAuthRepository(role: role)),
        studentRepositoryProvider
            .overrideWithValue(students ?? _FakeStudentRepository()),
        qualificationRepositoryProvider.overrideWithValue(
            qualifications ?? _FakeQualificationRepository()),
        absenceRepositoryProvider
            .overrideWithValue(absences ?? _FakeAbsenceRepository()),
        feeRepositoryProvider.overrideWithValue(fees ?? _FakeFeeRepository()),
        requestRepositoryProvider.overrideWithValue(
          requests ?? _FakeRequestRepository(detail: _studentRequest),
        ),
        dashboardRepositoryProvider
            .overrideWithValue(const _FakeDashboardRepository()),
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
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(TabBar),
    matching: find.text(label),
  );
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

const _student = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'active',
  classroomCount: 3,
);

const _studentRequest = RequestModel(
  id: 's1',
  kind: RequestKind.student,
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  identityNumber: '30111222',
  branch: 'Reconquista',
  year: '2026',
  status: 'approved',
);

void main() {
  testWidgets('renders the hero header and the tabs', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Reconquista'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Inasistencias'), findsOneWidget);
    expect(find.text('Cuotas'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
    expect(find.text('Solicitud'), findsNothing);
    expect(find.text('Padres'), findsNothing);
  });

  testWidgets('admin sees request and parents tabs', (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      students: _FakeStudentRepository(student: _student),
    );

    expect(find.text('Solicitud'), findsOneWidget);
    expect(find.text('Padres'), findsOneWidget);
  });

  testWidgets('request tab shows the student request data', (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      students: _FakeStudentRepository(student: _student),
      requests: _FakeRequestRepository(
        detail: const RequestModel(
          id: 's1',
          kind: RequestKind.student,
          fullname: 'Ana Gómez',
          email: 'ana@example.com',
          identityNumber: '30111222',
          branch: 'Reconquista',
          year: '2026',
          status: 'approved',
          media: [
            RequestMedia(
              collectionName: 'front_dni',
              fileName: 'dni.jpg',
              url: 'https://example.com/dni.jpg',
            ),
          ],
        ),
      ),
    );

    await _openTab(tester, 'Solicitud');

    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('30111222'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('DNI frente'), findsOneWidget);
  });

  testWidgets('parents tab shows linked parents and their documents',
      (tester) async {
    await _pumpDetail(
      tester,
      role: 'admin',
      students: _FakeStudentRepository(
        student: _student,
        parents: const [
          StudentParentModel(
            id: 'p1',
            fullname: 'María López',
            email: 'maria@example.com',
            phone: '123456',
            address: 'Calle 1',
            identityNumber: '99887766',
            status: 'approved',
            media: [
              RequestMedia(
                collectionName: 'front_dni',
                fileName: 'dni.jpg',
                url: 'https://example.com/dni.jpg',
              ),
            ],
          ),
        ],
      ),
    );

    await _openTab(tester, 'Padres');

    expect(find.text('María López'), findsOneWidget);
    expect(find.text('maria@example.com'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('Calle 1'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('DNI frente'), findsOneWidget);
  });

  testWidgets('shows the info tab with stats and sections', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    await _openTab(tester, 'Información');

    expect(find.text('DATOS PERSONALES'), findsOneWidget);
    expect(find.text('INSTITUCIONAL'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('30111222'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
    expect(find.text('Reconquista'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('shows the grade grid on the grades tab', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      qualifications: _FakeQualificationRepository(
        items: const [
          QualificationModel(
            id: 'q1',
            score: 8.5,
            scoreLabel: '8.5',
            type: 'Parcial',
            period: '1',
            classroomId: 'c1',
            classroomName: '3G X',
            description: 'Primer parcial',
            date: '12/03/2026',
          ),
        ],
      ),
    );

    expect(find.text('Calificaciones por período'), findsOneWidget);
    expect(find.text('3G X'), findsOneWidget);
    expect(find.text('DESEMPEÑO'), findsOneWidget);
    expect(find.text('ACTITUD'), findsOneWidget);
    expect(find.text('ESCRITO'), findsOneWidget);
    expect(find.text('ORAL'), findsOneWidget);
    expect(find.text('TAREAS'), findsOneWidget);
    expect(find.text('PROMEDIO'), findsOneWidget);
    expect(find.text('1° Trimestre'), findsOneWidget);
    expect(find.text('2° Trimestre'), findsOneWidget);
    expect(find.text('3° Trimestre'), findsOneWidget);
    expect(find.text('8.5'), findsWidgets);
  });

  testWidgets('filters the grid by the classroom of origin', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      classroomId: 'c2',
      qualifications: _FakeQualificationRepository(
        items: const [
          QualificationModel(
            id: 'q1',
            score: 8,
            scoreLabel: '8',
            type: 'Parcial',
            period: '1',
            classroomId: 'c1',
            classroomName: '3G X',
          ),
          QualificationModel(
            id: 'q2',
            score: 9,
            scoreLabel: '9',
            type: 'Parcial',
            period: '1',
            classroomId: 'c2',
            classroomName: 'A2 B',
          ),
        ],
      ),
    );

    expect(find.text('A2 B'), findsOneWidget);
    expect(find.text('3G X'), findsNothing);
    expect(find.text('9'), findsWidgets);
    expect(find.text('8'), findsNothing);
  });

  testWidgets('groups the grid by classroom when there is no classroomId',
      (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      qualifications: _FakeQualificationRepository(
        items: const [
          QualificationModel(
            id: 'q1',
            score: 8,
            scoreLabel: '8',
            type: 'Parcial',
            period: '1',
            classroomId: 'c1',
            classroomName: '3G X',
          ),
          QualificationModel(
            id: 'q2',
            score: 9,
            scoreLabel: '9',
            type: 'Parcial',
            period: '1',
            classroomId: 'c2',
            classroomName: 'A2 B',
          ),
        ],
      ),
    );

    expect(find.text('3G X'), findsOneWidget);
    expect(find.text('A2 B'), findsOneWidget);
    expect(find.text('Calificaciones por período'), findsNWidgets(2));
  });

  testWidgets('grade grid renders without overflow on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      qualifications: _FakeQualificationRepository(
        items: const [
          QualificationModel(
            id: 'q1',
            score: 8.5,
            scoreLabel: '8.5',
            type: 'Parcial',
            period: '1',
            classroomId: 'c1',
            classroomName: '3G X',
          ),
        ],
      ),
    );

    expect(find.text('Calificaciones por período'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lists absences and fees', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      absences: _FakeAbsenceRepository(
        items: const [
          AbsenceModel(
            id: 'a1',
            quantity: 2,
            period: '1',
            justified: 'si',
            description: 'Fiebre',
            date: '12/03/2026',
          ),
        ],
      ),
      fees: _FakeFeeRepository(
        items: const [
          FeeModel(
            id: 'f1',
            numberFee: 1,
            month: '3',
            year: '2026',
            total: 25000,
            status: 'pending',
          ),
        ],
      ),
    );

    await _openTab(tester, 'Inasistencias');
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Fiebre'), findsOneWidget);
    expect(find.text('Justificada'), findsOneWidget);

    await _openTab(tester, 'Cuotas');
    expect(find.text('Cuota #1 · 3 2026'), findsOneWidget);
    expect(find.textContaining('25.000'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('shows empty states for related tabs', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    expect(find.text('No hay notas disponibles'), findsOneWidget);

    await _openTab(tester, 'Inasistencias');
    expect(find.text('No hay inasistencias registradas'), findsOneWidget);

    await _openTab(tester, 'Cuotas');
    expect(find.text('No hay cuotas disponibles'), findsOneWidget);
  });

  testWidgets('shows the error view when the student fails to load',
      (tester) async {
    await _pumpDetail(tester, students: _FakeStudentRepository(fails: true));

    expect(find.text('No se pudo cargar el estudiante'), findsOneWidget);
  });

  testWidgets('professor sees the blue info stats', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      role: 'professor',
    );

    await _openTab(tester, 'Información');

    final stats = tester.widgetList<StatCard>(find.byType(StatCard)).toList();
    expect(
      stats.map((stat) => stat.iconColor),
      [
        AppColors.primary,
        AppColors.primarySoft,
        AppColors.accent,
      ],
    );
  });

  testWidgets('related empty states use the default blue accent',
      (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      role: 'professor',
    );

    final empty = tester.widget<EmptyState>(find.byType(EmptyState));
    expect(empty.accentColor, isNull);
  });

  testWidgets('student detail uses the single blue system', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    final empty = tester.widget<EmptyState>(find.byType(EmptyState));
    expect(empty.accentColor, isNull);

    await _openTab(tester, 'Información');
    final stats = tester.widgetList<StatCard>(find.byType(StatCard)).toList();
    expect(
      stats.map((stat) => stat.iconColor),
      [
        AppColors.primary,
        AppColors.primarySoft,
        AppColors.accent,
      ],
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.labelColor, AppColors.primary);
    expect(tabBar.indicatorColor, AppColors.primary);
  });

  testWidgets('grades grid uses dark ink in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: StudentGradesGrid(qualifications: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Calificaciones por período'));
    expect(title.style?.color, AppColors.darkTextPrimary);
  });

  testWidgets('professor info tab renders without overflow on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      role: 'professor',
    );
    await _openTab(tester, 'Información');

    expect(find.text('DATOS PERSONALES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
