import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/domain/student_parent_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_classrooms_section.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeStudentRepository implements StudentRepository {
  @override
  Future<List<StudentParentModel>> getParents(String studentId) async =>
      const [];

  _FakeStudentRepository({this.classrooms = const [], this.fails = false});

  final List<ClassroomModel> classrooms;
  final bool fails;

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async {
    if (fails) throw Exception('boom');
    return classrooms;
  }

  @override
  Future<StudentModel> getStudent(String id) =>
      Future.error(UnimplementedError());

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

GoRouter _router() => GoRouter(
      initialLocation: '/students/s1',
      routes: [
        GoRoute(
          path: '/students/:id',
          builder: (_, state) => Scaffold(
            body: SingleChildScrollView(
              child: StudentClassroomsSection(
                studentId: state.pathParameters['id']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/classrooms/:id',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('classroom:${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );

Future<void> _pumpSection(
  WidgetTester tester, {
  List<ClassroomModel> classrooms = const [],
  bool fails = false,
}) async {
  final router = _router();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(
          _FakeStudentRepository(classrooms: classrooms, fails: fails),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Nota: `SectionHeader` renderiza el título en mayúsculas, así que
  // `navClasses` ('Aulas' en ES) se ve como 'AULAS'.
  testWidgets('lists classrooms and navigates to detail', (tester) async {
    await _pumpSection(
      tester,
      classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
    );

    expect(find.text('AULAS'), findsOneWidget);
    expect(find.text('3G X'), findsOneWidget);

    await tester.tap(find.text('3G X'));
    await tester.pumpAndSettle();

    expect(find.text('classroom:c1'), findsOneWidget);
  });

  testWidgets('hides the section when the student has no classrooms',
      (tester) async {
    await _pumpSection(tester);

    expect(find.text('AULAS'), findsNothing);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('shows the error view and retry does not crash', (tester) async {
    await _pumpSection(tester, fails: true);

    expect(find.text('AULAS'), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('No se pudieron cargar las clases'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
