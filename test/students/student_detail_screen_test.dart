import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.student, this.fails = false});

  final StudentModel? student;
  final bool fails;

  @override
  Future<StudentModel> getStudent(String id) async {
    if (fails) throw Exception('boom');
    return student!;
  }

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
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeStudentRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(repository),
      ],
      child: localizedApp(
        home: const StudentDetailScreen(studentId: 's1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(TabBar), matching: find.text(label)),
  );
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

void main() {
  testWidgets('renders the hero header and the tabs', (tester) async {
    await _pumpDetail(tester, _FakeStudentRepository(student: _student));

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Reconquista'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Inasistencias'), findsOneWidget);
    expect(find.text('Cuotas'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
  });

  testWidgets('shows the info tab with stats and sections', (tester) async {
    await _pumpDetail(tester, _FakeStudentRepository(student: _student));

    await _openTab(tester, 'Información');

    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Institucional'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('30111222'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
    expect(find.text('Reconquista'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('shows the error view when the student fails to load',
      (tester) async {
    await _pumpDetail(tester, _FakeStudentRepository(fails: true));

    expect(find.text('No se pudo cargar el estudiante'), findsOneWidget);
  });
}
