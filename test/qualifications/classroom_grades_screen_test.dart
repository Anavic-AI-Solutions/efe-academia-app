import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/qualifications/screens/classroom_grades_screen.dart';
import 'package:efe_mobile/features/qualifications/screens/widgets/qualification_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeQualificationRepository implements QualificationRepository {
  ClassroomGradesSummary summary;
  Map<String, String>? created;
  bool failOnCreate = false;

  _FakeQualificationRepository(this.summary);

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

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) async =>
      summary;

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) =>
      throw UnimplementedError();

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) =>
      throw UnimplementedError();

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) async {
    if (failOnCreate) {
      throw Exception('create failed');
    }
    created = {
      'studentId': studentId,
      'classroomId': classroomId,
      'score': score,
      'type': type,
      'period': period,
      'description': description ?? '',
    };
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
      throw UnimplementedError();

  @override
  Future<void> deleteQualification(String id) => throw UnimplementedError();
}

const _students = [
  ClassroomGradeStudent(
    studentId: 's1',
    fullname: 'Marega, Paola',
    average: 9.2,
  ),
  ClassroomGradeStudent(studentId: 's2', fullname: 'Díaz, Sol'),
];

const _summary = ClassroomGradesSummary(
  classroomId: 'c1',
  classroomName: '3G X',
  classroomAverage: 7.9,
  studentsCount: 2,
  students: _students,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeQualificationRepository repository,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ProviderContainer(
        overrides: [
          qualificationRepositoryProvider.overrideWithValue(repository),
        ],
      ),
      child: localizedApp(
        home: const ClassroomGradesScreen(classroomId: 'c1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the classroom average and the student grades',
      (tester) async {
    await _pumpScreen(tester, _FakeQualificationRepository(_summary));

    expect(find.text('Calificaciones'), findsOneWidget);
    expect(find.text('3G X'), findsOneWidget);
    expect(find.text('Promedio del aula'), findsOneWidget);
    expect(find.text('7.9'), findsOneWidget);
    expect(find.text('Marega, Paola'), findsOneWidget);
    expect(find.text('9.2'), findsOneWidget);
    expect(find.text('Díaz, Sol'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('creating a grade sends the payload and confirms',
      (tester) async {
    final repository = _FakeQualificationRepository(_summary);
    await _pumpScreen(tester, repository);

    await tester.tap(find.text('+ Cargar calificación'));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationFormSheet), findsOneWidget);

    final sheet = tester.widget<QualificationFormSheet>(
      find.byType(QualificationFormSheet),
    );
    expect(sheet.classroomId, 'c1');
    expect(sheet.classrooms, hasLength(1));
    expect(sheet.classrooms!.single.id, 'c1');
    expect(sheet.classrooms!.single.name, '3G X');
    expect(sheet.students, _students);
    expect(
      find.byKey(const Key('qualification-form-classroom')),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField).first, '8,5');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.created?['studentId'], 's1');
    expect(repository.created?['classroomId'], 'c1');
    expect(repository.created?['score'], '8.5');
    expect(repository.created?['type'], 'Parcial');
    expect(find.text('Calificación guardada'), findsOneWidget);
  });

  testWidgets('an invalid score is rejected before saving', (tester) async {
    final repository = _FakeQualificationRepository(_summary);
    await _pumpScreen(tester, repository);

    await tester.tap(find.text('+ Cargar calificación'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '11');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ingresá una nota válida (0 a 10 o texto)'),
      findsOneWidget,
    );
    expect(repository.created, isNull);
  });
}
