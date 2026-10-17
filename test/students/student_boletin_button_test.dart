import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_grades_grid.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_related_tabs.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../helpers/localized_app.dart';

class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({this.items = const []});

  final List<QualificationModel> items;

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(data: items, page: page, perPage: limit, total: items.length);

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(String classroomId) =>
      throw UnimplementedError();

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      throw UnimplementedError();

  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) =>
      throw UnimplementedError();

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) =>
      throw UnimplementedError();

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) =>
      throw UnimplementedError();
}

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this.data);

  final DashboardData data;

  @override
  Future<DashboardData> getDashboard() async => data;
}

const _qualification = QualificationModel(
  id: 'q1',
  score: 7,
  scoreLabel: '7',
  type: 'Parcial',
  period: '1',
  classroomId: 'c1',
  classroomName: '3G X',
);

GoRouter _router({bool canWrite = false, String? classroomId}) => GoRouter(
      initialLocation: '/students/s1',
      routes: [
        GoRoute(
          path: '/students/:id',
          builder: (_, state) => Scaffold(
            body: StudentGradesTab(
              studentId: state.pathParameters['id']!,
              classroomId: classroomId,
              canWrite: canWrite,
              studentFullname: 'Ana Gómez',
            ),
          ),
          routes: [
            GoRoute(
              path: 'boletin',
              builder: (_, state) => Scaffold(
                body: Text('boletin:${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ],
    );

Future<void> _pumpTab(
  WidgetTester tester, {
  List<QualificationModel> items = const [_qualification],
  bool canWrite = false,
  String? classroomId,
}) async {
  final router = _router(canWrite: canWrite, classroomId: classroomId);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qualificationRepositoryProvider.overrideWithValue(
          _FakeQualificationRepository(items: items),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(
            const DashboardData(
              role: 'professor',
              classrooms: [
                ProfessorClassroomSummary(id: 'c1', name: '3G X'),
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: testLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el botón Ver boletín al pie y navega al boletín',
      (tester) async {
    await _pumpTab(tester);

    final button = find.ancestor(
      of: find.text('Ver boletín'),
      matching: find.bySubtype<OutlinedButton>(),
    );
    expect(button, findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.fileText), findsOneWidget);

    // Al pie: debajo de la última grilla de notas.
    expect(
      tester.getTopLeft(button).dy,
      greaterThan(
        tester.getBottomLeft(find.byType(StudentGradesGrid)).dy,
      ),
    );

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('boletin:s1'), findsOneWidget);
  });

  testWidgets('muestra el botón Ver boletín también sin notas y navega',
      (tester) async {
    await _pumpTab(tester, items: const []);

    expect(find.byType(EmptyState), findsOneWidget);

    final button = find.ancestor(
      of: find.text('Ver boletín'),
      matching: find.bySubtype<OutlinedButton>(),
    );
    expect(button, findsOneWidget);

    // Debajo del contenido del estado vacío.
    expect(
      tester.getTopLeft(button).dy,
      greaterThan(
        tester.getBottomLeft(find.byIcon(Icons.grade_outlined)).dy,
      ),
    );

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('boletin:s1'), findsOneWidget);
  });

  testWidgets('el botón también es visible para el profesor con escritura',
      (tester) async {
    await _pumpTab(tester, canWrite: true, classroomId: 'c1');

    expect(find.text('Cargar nota'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Ver boletín'),
        matching: find.bySubtype<OutlinedButton>(),
      ),
      findsOneWidget,
    );
  });
}
