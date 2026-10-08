import 'package:efe_mobile/app/router.dart';
import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/header_stats_row.dart';
import 'package:efe_mobile/core/widgets/home_header.dart';
import 'package:efe_mobile/features/attendance/data/attendance_repository.dart';
import 'package:efe_mobile/features/attendance/domain/attendance_day.dart';
import 'package:efe_mobile/features/attendance/providers/attendance_provider.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/professor_stats_row.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u1',
        name: 'Ileana Gómez',
        email: 'ileana@test.com',
        role: 'professor',
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

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardData data;

  _FakeDashboardRepository(this.data);

  @override
  Future<DashboardData> getDashboard() async => data;
}

/// Keeps the professor home news section off the real API in tests.
class _FakeNewsRepository implements NewsRepository {
  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination.empty();
}

/// Keeps the classrooms branch (list screen) off the real API in tests.
class _FakeClassroomRepository implements ClassroomRepository {
  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async =>
      PageResult<ClassroomModel>.empty();

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() => throw UnimplementedError();
}

class _FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceDay> getAttendance(String classroomId, {String? date}) async =>
      AttendanceDay(
        date: '2026-09-24',
        classroomId: classroomId,
        classroomName: classroomId == 'c2' ? '1G X · 2026' : '3G X · 2026',
        studentsCount: 1,
        students: const [
          AttendanceStudent(id: 's1', fullname: 'Marega, Paola'),
        ],
      );

  @override
  Future<void> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) async {}
}

class _FakeQualificationRepository implements QualificationRepository {
  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) async =>
      const ClassroomGradesSummary(
        classroomId: 'c2',
        classroomName: '1G X · 2026',
        classroomAverage: 7.5,
        students: [
          ClassroomGradeStudent(
            studentId: 's1',
            fullname: 'Marega, Paola',
            average: 7.5,
          ),
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
  }) async {}

  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();
}

const _professorData = DashboardData(
  role: 'professor',
  totalStudents: 78,
  totalClassrooms: 3,
  absencesToday: 4,
  classrooms: [
    ProfessorClassroomSummary(id: 'c1', name: '3G X · 2026', studentsCount: 24),
    ProfessorClassroomSummary(id: 'c2', name: '1G X · 2026', studentsCount: 30),
  ],
);

Future<ProviderContainer> _pumpHome(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      dashboardRepositoryProvider
          .overrideWithValue(_FakeDashboardRepository(_professorData)),
      attendanceRepositoryProvider
          .overrideWithValue(_FakeAttendanceRepository()),
      qualificationRepositoryProvider
          .overrideWithValue(_FakeQualificationRepository()),
      classroomRepositoryProvider
          .overrideWithValue(_FakeClassroomRepository()),
      // El calendario y los documentos del home no tocan red en estos tests.
      homeCalendarProvider.overrideWith((ref) async => <EventModel>[]),
      homeDocumentsProvider.overrideWith((ref) async => <DocumentModel>[]),
      newsListProvider
          .overrideWith((ref) => NewsListNotifier(_FakeNewsRepository())),
      unreadCountProvider.overrideWith((ref) async => 0),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(routerProvider),
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

Finder _navLabel(String text) => find.descendant(
      of: find.byType(CustomBottomNav),
      matching: find.text(text),
    );

void main() {
  testWidgets('shows professor metrics and the classrooms section',
      (tester) async {
    await _pumpHome(tester);

    expect(find.text('Prof. Ileana Gómez'), findsOneWidget);
    expect(find.text('Aulas'), findsWidgets);
    expect(find.text('Alumnos'), findsOneWidget);
    expect(find.text('Ausentes'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('MIS AULAS'), findsOneWidget);
    expect(find.text('3G X · 2026'), findsOneWidget);
    expect(find.text('1G X · 2026'), findsOneWidget);
    expect(find.text('24 alumnos'), findsOneWidget);
    expect(find.text('Tomar asistencia'), findsOneWidget);
    expect(find.text('Cargar nota'), findsOneWidget);
  });

  testWidgets('the selected classroom drives the attendance CTA',
      (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('1G X · 2026'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tomar asistencia'));
    await tester.pumpAndSettle();

    expect(find.text('Asistencia · 1G X · 2026'), findsOneWidget);

    final activePill = tester.widget<AnimatedContainer>(
      find.ancestor(of: _navLabel('Aulas'), matching: find.byType(AnimatedContainer)),
    );
    expect((activePill.decoration as BoxDecoration).color,
        AppColors.primary);
  });

  testWidgets('Cargar nota opens the classroom grades screen', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.text('Calificaciones'), findsOneWidget);
    expect(find.text('Promedio del aula'), findsOneWidget);
    expect(find.text('7.5'), findsWidgets);
  });

  testWidgets('shows the empty state when there are no classrooms',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(
            const DashboardData(role: 'professor'),
          ),
        ),
        classroomRepositoryProvider
            .overrideWithValue(_FakeClassroomRepository()),
        homeCalendarProvider.overrideWith((ref) async => <EventModel>[]),
        homeDocumentsProvider.overrideWith((ref) async => <DocumentModel>[]),
        newsListProvider
            .overrideWith((ref) => NewsListNotifier(_FakeNewsRepository())),
        unreadCountProvider.overrideWith((ref) async => 0),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            locale: const Locale('es', 'AR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no tenés aulas asignadas'), findsOneWidget);
  });

  testWidgets('the enlarged home header renders without overflow at 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpHome(tester);

    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.text('Prof. Ileana Gómez'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses HomeHeader and HeaderStatsRow (not HomeHeader/ProfessorStatsRow)',
      (tester) async {
    await _pumpHome(tester);

    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.byType(HeaderStatsRow), findsOneWidget);
    expect(find.byType(ProfessorStatsRow), findsNothing);
    // ProfessorStatsRow is not a widget type we can find directly, but we verify the stats are shown via HeaderStatsRow
    expect(find.text('3'), findsOneWidget); // classrooms
    expect(find.text('78'), findsOneWidget); // students
    expect(find.text('4'), findsOneWidget); // absences
  });
}
