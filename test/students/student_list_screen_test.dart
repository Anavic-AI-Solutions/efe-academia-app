import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.total = 1});

  final int total;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add({
      'search': search,
      'status': status,
      'year': year,
      'branch': branch,
      'page': page,
    });
    if (total == 0) return PageResult.empty(perPage: limit);
    final offset = (page - 1) * limit;
    final count = (total - offset).clamp(0, limit);
    return PageResult(
      data: List.generate(
        count,
        (i) => StudentModel(
          id: 's${offset + i + 1}',
          fullname: 'Estudiante ${offset + i + 1}',
          year: i.isEven ? '2025' : '2026',
          branch: i.isEven ? 'Vera' : 'Reconquista',
        ),
      ),
      page: page,
      perPage: limit,
      total: total,
    );
  }

  @override
  Future<StudentModel> getStudent(String id) =>
      Future.error(UnimplementedError());
}

Future<_FakeStudentRepository> _pumpScreen(
  WidgetTester tester, {
  int total = 1,
}) async {
  final repository = _FakeStudentRepository(total: total);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(repository),
      ],
      child: localizedApp(home: const StudentListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('renders the first page of students', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Estudiante 1'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Activos'), findsOneWidget);
    expect(find.text('Inactivos'), findsOneWidget);
  });

  testWidgets('shows numbered pagination and requests the tapped page',
      (tester) async {
    final repository = await _pumpScreen(tester, total: 57);

    expect(find.text('Mostrando 1–20 de 57'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['page'], 2);
    expect(find.text('Estudiante 21'), findsOneWidget);
    expect(find.text('Mostrando 21–40 de 57'), findsOneWidget);
  });

  testWidgets('goes back to page 1 when the status filter changes',
      (tester) async {
    final repository = await _pumpScreen(tester, total: 57);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(repository.calls.last['page'], 2);

    await tester.tap(find.text('Inactivos'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['page'], 1);
    expect(repository.calls.last['status'], 'inactive');
  });

  testWidgets('hides pagination when everything fits in one page',
      (tester) async {
    await _pumpScreen(tester, total: 3);

    expect(find.textContaining('Mostrando'), findsNothing);
  });

  testWidgets('renders without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester, total: 57);

    expect(find.text('Estudiante 1'), findsOneWidget);
    expect(find.text('Mostrando 1–20 de 57'), findsOneWidget);
  });
}
