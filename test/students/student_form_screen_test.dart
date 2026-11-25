import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/domain/student_parent_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.student});

  StudentModel? student;
  ApiException? createError;
  ApiException? updateError;
  Object? detailError;
  int getStudentCalls = 0;
  final List<Map<String, String>> createCalls = [];
  final List<Map<String, Object>> updateCalls = [];

  @override
  Future<StudentModel> getStudent(String id) async {
    getStudentCalls++;
    final error = detailError;
    if (error != null) throw error;
    return student!;
  }

  @override
  Future<StudentModel> createStudent({
    required String fullname,
    required String email,
    required String year,
    required String branch,
    required String identityNumber,
  }) async {
    createCalls.add({
      'fullname': fullname,
      'email': email,
      'year': year,
      'branch': branch,
      'identity_number': identityNumber,
    });
    final error = createError;
    if (error != null) throw error;
    return StudentModel(
      id: 'new',
      fullname: fullname,
      email: email,
      year: year,
      branch: branch,
      identityNumber: identityNumber,
    );
  }

  @override
  Future<StudentModel> updateStudent(
    String id, {
    required String fullname,
    required String email,
    required String year,
    required String branch,
    required String identityNumber,
  }) async {
    updateCalls.add({
      'id': id,
      'fullname': fullname,
      'email': email,
      'year': year,
      'branch': branch,
      'identity_number': identityNumber,
    });
    final error = updateError;
    if (error != null) throw error;
    return StudentModel(
      id: id,
      fullname: fullname,
      email: email,
      year: year,
      branch: branch,
      identityNumber: identityNumber,
    );
  }

  @override
  Future<void> deactivateStudent(String id) async {}

  @override
  Future<void> reactivateStudent(String id) async {}

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async =>
      const [];

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
  }) async =>
      PageResult.empty(perPage: limit);
}

class _FormHarness extends StatelessWidget {
  const _FormHarness({
    required this.repository,
    this.student,
    this.studentId,
    required this.onResult,
  });

  final _FakeStudentRepository repository;
  final StudentModel? student;
  final String? studentId;
  final ValueChanged<bool?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open-form'),
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => StudentFormScreen(
                  student: student,
                  studentId: studentId,
                ),
              ),
            );
            onResult(result);
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<_FakeStudentRepository> _openForm(
  WidgetTester tester, {
  StudentModel? student,
  String? studentId,
  _FakeStudentRepository? repository,
  void Function(bool?)? onResult,
}) async {
  final repo = repository ?? _FakeStudentRepository(student: student);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(
        home: _FormHarness(
          repository: repo,
          student: student,
          studentId: studentId,
          onResult: onResult ?? (_) {},
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-form')));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('student-form-fullname')),
    'Ana Gómez',
  );
  await tester.enterText(
    find.byKey(const Key('student-form-email')),
    'ana@example.com',
  );
  await tester.enterText(find.byKey(const Key('student-form-year')), '2026');
  await tester.enterText(
    find.byKey(const Key('student-form-branch')),
    'Reconquista',
  );
  await tester.enterText(
    find.byKey(const Key('student-form-identity')),
    '30111222',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('entity-form-save')));
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
);

void main() {
  testWidgets('creates a student and pops with true', (tester) async {
    bool? result;
    final repo = await _openForm(tester, onResult: (value) => result = value);

    expect(find.text('Nuevo alumno'), findsOneWidget);

    await _fillRequiredFields(tester);
    await _save(tester);

    expect(repo.createCalls, hasLength(1));
    expect(repo.createCalls.single, {
      'fullname': 'Ana Gómez',
      'email': 'ana@example.com',
      'year': '2026',
      'branch': 'Reconquista',
      'identity_number': '30111222',
    });
    expect(repo.updateCalls, isEmpty);
    expect(result, isTrue);
  });

  testWidgets('requires every field before creating', (tester) async {
    final repo = await _openForm(tester);

    await _save(tester);

    expect(repo.createCalls, isEmpty);
    expect(find.text('Nombre completo es obligatorio'), findsOneWidget);
    expect(find.text('Correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('Año es obligatorio'), findsOneWidget);
    expect(find.text('Sede es obligatorio'), findsOneWidget);
    expect(find.text('Documento es obligatorio'), findsOneWidget);
    expect(find.byType(StudentFormScreen), findsOneWidget);
  });

  testWidgets('rejects an invalid email', (tester) async {
    final repo = await _openForm(tester);
    await _fillRequiredFields(tester);
    await tester.enterText(
      find.byKey(const Key('student-form-email')),
      'not-an-email',
    );

    await _save(tester);

    expect(repo.createCalls, isEmpty);
    expect(find.text('Correo electrónico inválido'), findsOneWidget);
  });

  testWidgets('edits an existing student with prefilled fields',
      (tester) async {
    bool? result;
    final repo = await _openForm(
      tester,
      student: _student,
      onResult: (value) => result = value,
    );

    expect(find.text('Editar alumno'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Reconquista'), findsOneWidget);
    expect(find.text('30111222'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('student-form-year')),
      '2027',
    );
    await _save(tester);

    expect(repo.createCalls, isEmpty);
    expect(repo.updateCalls, hasLength(1));
    expect(repo.updateCalls.single['id'], 's1');
    expect(repo.updateCalls.single['year'], '2027');
    expect(result, isTrue);
  });

  testWidgets('loads the student when only an id is provided', (tester) async {
    final repo = _FakeStudentRepository(student: _student);
    await _openForm(tester, studentId: 's1', repository: repo);

    expect(repo.getStudentCalls, 1);
    expect(find.text('Editar alumno'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);

    await _save(tester);

    expect(repo.updateCalls.single['id'], 's1');
  });

  testWidgets('disables save when the student detail fails to load',
      (tester) async {
    final repo = _FakeStudentRepository()
      ..detailError = ApiException(message: 'gone', statusCode: 404);
    await _openForm(tester, studentId: 's1', repository: repo);

    expect(find.text('No se pudo cargar el estudiante'), findsOneWidget);

    final save = tester.widget<PillButton>(
      find.byKey(const ValueKey('entity-form-save')),
    );
    expect(save.onPressed, isNull);
    expect(repo.updateCalls, isEmpty);
  });

  testWidgets('maps 422 field errors to the matching fields', (tester) async {
    bool? result;
    final repo = _FakeStudentRepository()
      ..createError = ValidationException(
        fieldErrors: {
          'email': 'El correo ya está registrado',
          'year': 'El año no es válido',
        },
      );
    await _openForm(tester,
        repository: repo, onResult: (value) => result = value);

    await _fillRequiredFields(tester);
    await _save(tester);

    expect(repo.createCalls, hasLength(1));
    expect(find.text('El correo ya está registrado'), findsOneWidget);
    expect(find.text('El año no es válido'), findsOneWidget);
    expect(find.byType(StudentFormScreen), findsOneWidget);
    expect(result, isNull);
  });
}
