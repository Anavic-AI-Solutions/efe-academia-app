import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/qualifications/screens/widgets/create_qualification_sheet.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_related_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

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

class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({this.items = const []});

  final List<QualificationModel> items;
  final List<_CreateCall> createCalls = [];
  int studentGradesCalls = 0;
  int classroomSummaryCalls = 0;

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
  ) async {
    classroomSummaryCalls++;
    return ClassroomGradesSummary(
      classroomId: classroomId,
      classroomName: '3G X',
      students: const [
        ClassroomGradeStudent(studentId: 's1', fullname: 'Ana Gómez'),
      ],
    );
  }

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
      throw UnimplementedError();

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) =>
      throw UnimplementedError();
}

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardData data;

  _FakeDashboardRepository(this.data);

  @override
  Future<DashboardData> getDashboard() async => data;
}

Future<void> _pumpGradesTab(
  WidgetTester tester, {
  required _FakeQualificationRepository qualifications,
  required DashboardData dashboardData,
  String? classroomId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qualificationRepositoryProvider.overrideWithValue(qualifications),
        dashboardRepositoryProvider
            .overrideWithValue(_FakeDashboardRepository(dashboardData)),
      ],
      child: localizedApp(
        home: Scaffold(
          body: StudentGradesTab(
            studentId: 's1',
            classroomId: classroomId,
            canWrite: true,
            studentFullname: 'Ana Gómez',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin aulas deshabilita la acción', (tester) async {
    await _pumpGradesTab(
      tester,
      qualifications: _FakeQualificationRepository(),
      dashboardData: const DashboardData(role: 'professor'),
      classroomId: null,
    );

    expect(find.text('Cargar nota'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Cargar nota'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('guardar invalida los providers de notas', (tester) async {
    final repository = _FakeQualificationRepository(
      items: const [
        QualificationModel(
          id: 'q1',
          score: 7,
          scoreLabel: '7',
          type: 'Parcial',
          period: '1',
          classroomId: 'c1',
          classroomName: '3G X',
        ),
      ],
    );
    await _pumpGradesTab(
      tester,
      qualifications: repository,
      dashboardData: const DashboardData(
        role: 'professor',
        classrooms: [
          ProfessorClassroomSummary(id: 'c1', name: '3G X'),
        ],
      ),
      classroomId: 'c1',
    );

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateQualificationSheet), findsOneWidget);
    // Alumno bloqueado: una sola entrada.
    expect(find.text('Ana Gómez'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '8.5');

    // Período exacto '1' exigido por el contrato del task.
    final defaultPeriod = currentAcademicPeriod();
    await tester.tap(find.text('$defaultPeriod°'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1°').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final call = repository.createCalls.single;
    expect(call.studentId, 's1');
    expect(call.classroomId, 'c1');
    expect(call.score, '8.5');
    expect(call.type, 'Parcial');
    expect(call.period, '1');
  });

  testWidgets('guardar con aula del dropdown invalida sus notas',
      (tester) async {
    final repository = _FakeQualificationRepository();
    final container = ProviderContainer(
      overrides: [
        qualificationRepositoryProvider.overrideWithValue(repository),
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
    );
    addTearDown(container.dispose);

    // Escucha el provider del aula para detectar su invalidación.
    container.listen(classroomGradesProvider('c1'), (_, __) {});

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedApp(
          home: const Scaffold(
            body: StudentGradesTab(
              studentId: 's1',
              classroomId: null,
              canWrite: true,
              studentFullname: 'Ana Gómez',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.classroomSummaryCalls, 1);

    await tester.tap(find.text('Cargar nota'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateQualificationSheet), findsOneWidget);
    // El dropdown de aula defaultea a la primera.
    expect(find.text('3G X'), findsOneWidget);
    // Solo el dropdown de alumno está deshabilitado.
    final dropdowns = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .toList();
    expect(dropdowns.where((d) => d.onChanged == null), hasLength(1));

    await tester.enterText(find.byType(TextField).first, '8.5');

    final defaultPeriod = currentAcademicPeriod();
    await tester.tap(find.text('$defaultPeriod°'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1°').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final call = repository.createCalls.single;
    expect(call.studentId, 's1');
    expect(call.classroomId, 'c1');
    expect(call.score, '8.5');
    expect(call.type, 'Parcial');
    expect(call.period, '1');
    // El aula resuelta del dropdown se invalida aunque el llamador no la vea.
    expect(repository.classroomSummaryCalls, 2);
    expect(repository.studentGradesCalls, 2);
  });
}
