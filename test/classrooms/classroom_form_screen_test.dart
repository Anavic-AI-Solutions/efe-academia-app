import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/classroom_form_screen.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

const _classroom = ClassroomModel(
  id: 'c1',
  name: 'A2 A',
  description: 'Curso A2',
  status: 'inactive',
  shift: 'morning',
  day: 'Lunes',
  hour: '08:00',
  room: 'Sala 1',
  year: '2026',
  branch: 'Reconquista',
  level: 'A2',
  grade: '1',
  book: 'Libro 1',
  commission: 'A',
  courseDays: 3,
  period1Days: 2,
  period2Days: 2,
  period3Days: 3,
  isActive: false,
  isArchived: true,
);

Map<String, Object> _emptyPayload() => {
      'name': '',
      'description': '',
      'status': 'active',
      'shift': '',
      'day': '',
      'hour': '',
      'room': '',
      'year': '',
      'branch': '',
      'level': '',
      'grade': '',
      'book': '',
      'commission': '',
      'course_days': '',
      'period_1_days': '',
      'period_2_days': '',
      'period_3_days': '',
      'is_archived': false,
    };

class _FakeClassroomRepository implements ClassroomRepository {
  _FakeClassroomRepository({this.classroom});

  ClassroomModel? classroom;
  ApiException? createError;
  ApiException? updateError;
  Object? detailError;
  int getClassroomCalls = 0;
  int getClassroomsCalls = 0;
  final List<Map<String, Object>> createCalls = [];
  final List<Map<String, Object>> updateCalls = [];

  ClassroomModel _detail(String id) =>
      classroom ?? ClassroomModel(id: id, name: 'Aula $id');

  @override
  Future<ClassroomModel> getClassroom(String id) async {
    getClassroomCalls++;
    final error = detailError;
    if (error != null) throw error;
    return _detail(id);
  }

  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
    String? studentId,
  }) async {
    getClassroomsCalls++;
    return PageResult.empty(perPage: limit);
  }

  @override
  Future<ClassroomModel> createClassroom({
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) async {
    createCalls.add({
      'name': name,
      'description': description,
      'status': status,
      'shift': shift,
      'day': day,
      'hour': hour,
      'room': room,
      'year': year,
      'branch': branch,
      'level': level,
      'grade': grade,
      'book': book,
      'commission': commission,
      'course_days': courseDays,
      'period_1_days': period1Days,
      'period_2_days': period2Days,
      'period_3_days': period3Days,
      'is_archived': isArchived,
    });
    final error = createError;
    if (error != null) throw error;
    return ClassroomModel(id: 'new-id', name: name, isArchived: isArchived);
  }

  @override
  Future<ClassroomModel> updateClassroom(
    String id, {
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) async {
    updateCalls.add({
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'shift': shift,
      'day': day,
      'hour': hour,
      'room': room,
      'year': year,
      'branch': branch,
      'level': level,
      'grade': grade,
      'book': book,
      'commission': commission,
      'course_days': courseDays,
      'period_1_days': period1Days,
      'period_2_days': period2Days,
      'period_3_days': period3Days,
      'is_archived': isArchived,
    });
    final error = updateError;
    if (error != null) throw error;
    return ClassroomModel(id: id, name: name, isArchived: isArchived);
  }

  @override
  Future<void> deleteClassroom(String id) async {}
  @override
  Future<ClassroomModel> setArchived(String id, bool isArchived) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult.empty(perPage: limit);

  @override
  Future<ClassroomFilters> getFilters() async => const ClassroomFilters();
}

class _FormHarness extends StatelessWidget {
  const _FormHarness({
    this.classroom,
    this.classroomId,
    required this.onResult,
  });

  final ClassroomModel? classroom;
  final String? classroomId;
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
                builder: (_) => ClassroomFormScreen(
                  classroom: classroom,
                  classroomId: classroomId,
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

Future<_FakeClassroomRepository> _openForm(
  WidgetTester tester, {
  ClassroomModel? classroom,
  String? classroomId,
  _FakeClassroomRepository? repository,
  ProviderContainer? container,
  void Function(bool?)? onResult,
}) async {
  final repo = repository ?? _FakeClassroomRepository(classroom: classroom);
  final scope = container ??
      ProviderContainer(
        overrides: [
          classroomRepositoryProvider.overrideWithValue(repo),
        ],
      );
  if (container == null) addTearDown(scope.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: localizedApp(
        home: _FormHarness(
          classroom: classroom,
          classroomId: classroomId,
          onResult: onResult ?? (_) {},
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-form')));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    160,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('entity-form-fields')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _expectFieldText(
  WidgetTester tester,
  Key key,
  String expected,
) async {
  await _scrollTo(tester, key);
  final field = tester.widget<TextFormField>(find.byKey(key));
  expect(field.controller?.text, expected);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('entity-form-save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a classroom, invalidates providers and pops true',
      (tester) async {
    bool? result;
    final repo = _FakeClassroomRepository();
    final container = ProviderContainer(
      overrides: [
        classroomRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _openForm(
      tester,
      repository: repo,
      container: container,
      onResult: (value) => result = value,
    );

    // Both providers start loaded so the invalidation can be observed.
    container.listen(classroomListProvider, (_, __) {});
    container.listen(classroomDetailProvider('new-id'), (_, __) {});
    await tester.pumpAndSettle();
    expect(repo.getClassroomsCalls, 1);
    expect(repo.getClassroomCalls, 1);

    expect(find.text('Nueva clase'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('classroom-form-name')),
      'A2 A',
    );
    await _save(tester);

    expect(repo.createCalls, hasLength(1));
    expect(repo.createCalls.single, {
      ..._emptyPayload(),
      'name': 'A2 A',
    });
    expect(repo.updateCalls, isEmpty);
    expect(repo.getClassroomsCalls, 2);
    expect(repo.getClassroomCalls, 2);
    expect(result, isTrue);
  });

  testWidgets('requires a name before creating', (tester) async {
    final repo = await _openForm(tester);

    await _save(tester);

    expect(repo.createCalls, isEmpty);
    expect(find.text('Nombre es obligatorio'), findsOneWidget);
    expect(find.byType(ClassroomFormScreen), findsOneWidget);
  });

  testWidgets('prefills every field when editing', (tester) async {
    bool? result;
    final repo = await _openForm(
      tester,
      classroom: _classroom,
      onResult: (value) => result = value,
    );

    expect(find.text('Editar clase'), findsOneWidget);

    await _expectFieldText(tester, const Key('classroom-form-name'), 'A2 A');
    await _expectFieldText(
      tester,
      const Key('classroom-form-description'),
      'Curso A2',
    );
    await _scrollTo(tester, const Key('classroom-form-status'));
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('classroom-form-status')),
          )
          .initialValue,
      'inactive',
    );
    await _scrollTo(tester, const Key('classroom-form-shift'));
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('classroom-form-shift')),
          )
          .initialValue,
      'morning',
    );
    await _scrollTo(tester, const Key('classroom-form-archived'));
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('classroom-form-archived')),
          )
          .value,
      isTrue,
    );
    await _expectFieldText(tester, const Key('classroom-form-day'), 'Lunes');
    await _expectFieldText(tester, const Key('classroom-form-hour'), '08:00');
    await _expectFieldText(tester, const Key('classroom-form-room'), 'Sala 1');
    await _expectFieldText(
      tester,
      const Key('classroom-form-branch'),
      'Reconquista',
    );
    await _expectFieldText(tester, const Key('classroom-form-year'), '2026');
    await _expectFieldText(tester, const Key('classroom-form-level'), 'A2');
    await _expectFieldText(tester, const Key('classroom-form-grade'), '1');
    await _expectFieldText(tester, const Key('classroom-form-book'), 'Libro 1');
    await _expectFieldText(
      tester,
      const Key('classroom-form-commission'),
      'A',
    );
    await _expectFieldText(
      tester,
      const Key('classroom-form-course-days'),
      '3',
    );
    await _expectFieldText(
      tester,
      const Key('classroom-form-period-1-days'),
      '2',
    );
    await _expectFieldText(
      tester,
      const Key('classroom-form-period-2-days'),
      '2',
    );
    await _expectFieldText(
      tester,
      const Key('classroom-form-period-3-days'),
      '3',
    );

    await _save(tester);

    expect(repo.updateCalls, hasLength(1));
    expect(repo.createCalls, isEmpty);
    expect(repo.updateCalls.single, {
      'id': 'c1',
      'name': 'A2 A',
      'description': 'Curso A2',
      'status': 'inactive',
      'shift': 'morning',
      'day': 'Lunes',
      'hour': '08:00',
      'room': 'Sala 1',
      'year': '2026',
      'branch': 'Reconquista',
      'level': 'A2',
      'grade': '1',
      'book': 'Libro 1',
      'commission': 'A',
      'course_days': '3',
      'period_1_days': '2',
      'period_2_days': '2',
      'period_3_days': '3',
      'is_archived': true,
    });
    expect(result, isTrue);
  });

  testWidgets('toggles the archive switch on update', (tester) async {
    const classroom = ClassroomModel(id: 'c1', name: 'A2 A');
    final repo = await _openForm(tester, classroom: classroom);

    await _scrollTo(tester, const Key('classroom-form-archived'));
    await tester.tap(find.byKey(const Key('classroom-form-archived')));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(repo.updateCalls, hasLength(1));
    expect(repo.updateCalls.single['is_archived'], isTrue);
  });

  testWidgets('sends empty optionals when they are cleared on update',
      (tester) async {
    final repo = await _openForm(tester, classroom: _classroom);

    await tester.enterText(
      find.byKey(const Key('classroom-form-description')),
      '',
    );
    await _scrollTo(tester, const Key('classroom-form-room'));
    await tester.enterText(find.byKey(const Key('classroom-form-room')), '');
    await _scrollTo(tester, const Key('classroom-form-course-days'));
    await tester.enterText(
      find.byKey(const Key('classroom-form-course-days')),
      '',
    );
    await _save(tester);

    expect(repo.updateCalls, hasLength(1));
    expect(repo.updateCalls.single['name'], 'A2 A');
    expect(repo.updateCalls.single['description'], '');
    expect(repo.updateCalls.single['room'], '');
    expect(repo.updateCalls.single['course_days'], '');
    expect(repo.updateCalls.single['day'], 'Lunes');
  });

  testWidgets('loads the classroom when only an id is provided',
      (tester) async {
    final repo = _FakeClassroomRepository(classroom: _classroom);
    await _openForm(tester, classroomId: 'c1', repository: repo);

    expect(repo.getClassroomCalls, 1);
    expect(find.text('Editar clase'), findsOneWidget);
    expect(find.text('A2 A'), findsOneWidget);

    await _save(tester);

    expect(repo.updateCalls.single['id'], 'c1');
  });

  testWidgets('maps 422 field errors to the matching fields', (tester) async {
    bool? result;
    final repo = _FakeClassroomRepository()
      ..createError = ValidationException(
        fieldErrors: {
          'name': 'El nombre ya está registrado',
          'description': 'La descripción no es válida',
        },
      );
    await _openForm(
      tester,
      repository: repo,
      onResult: (value) => result = value,
    );

    await tester.enterText(
      find.byKey(const Key('classroom-form-name')),
      'A2 A',
    );
    await _save(tester);

    expect(repo.createCalls, hasLength(1));
    expect(find.text('El nombre ya está registrado'), findsOneWidget);
    expect(find.text('La descripción no es válida'), findsOneWidget);
    expect(find.byType(ClassroomFormScreen), findsOneWidget);
    expect(result, isNull);
  });
}
