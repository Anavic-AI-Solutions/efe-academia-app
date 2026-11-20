import 'dart:async';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/qualifications/screens/widgets/qualification_form_sheet.dart';
import 'package:efe_mobile/features/students/providers/student_grades_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void seed(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

class _FakeQualificationRepository implements QualificationRepository {
  Map<String, Object?>? created;
  Map<String, Object?>? updated;
  String? updatedId;
  String? deletedId;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  int studentGradesCalls = 0;
  int classroomSummaryCalls = 0;
  int boletinCalls = 0;

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
  }) async {
    studentGradesCalls++;
    return PageResult(
      data: const <QualificationModel>[],
      page: page,
      perPage: limit,
      total: 0,
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
  Future<BoletinData> getBoletin(String studentId, String classroomId) async {
    boletinCalls++;
    return BoletinData(
      studentId: studentId,
      classroomId: classroomId,
    );
  }

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
    if (createError != null) throw createError!;
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
  }) async {
    if (updateError != null) throw updateError!;
    updatedId = id;
    updated = {
      'studentId': studentId,
      'classroomId': classroomId,
      'score': score,
      'type': type,
      'period': period,
      'category': category ?? '',
      'description': description ?? '',
    };
  }

  @override
  Future<void> deleteQualification(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedId = id;
  }
}

const _student = ClassroomGradeStudent(studentId: 's1', fullname: 'Ana Gómez');

QualificationModel _qualification({
  String id = 'q1',
  String scoreLabel = '8',
  String type = 'Parcial',
  String category = '',
  String period = '1',
  String description = '',
}) {
  return QualificationModel(
    id: id,
    studentId: 's1',
    classroomId: 'c1',
    studentName: 'Ana Gómez',
    classroomName: '3G X',
    scoreLabel: scoreLabel,
    type: type,
    category: category,
    period: period,
    description: description,
  );
}

class _Harness {
  _Harness(this.container, this.results);

  final ProviderContainer container;
  final List<QualificationFormResult> results;
}

Future<_Harness> _pumpForm(
  WidgetTester tester, {
  required _FakeQualificationRepository repository,
  required Widget form,
  String role = 'admin',
}) async {
  tester.view.physicalSize = const Size(400 * 3, 1000 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final auth = _TestAuthNotifier()
    ..seed(
      UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: role,
      ),
    );
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => auth),
      qualificationRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  final results = <QualificationFormResult>[];

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-form'),
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<QualificationFormResult>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => form,
                  );
                  if (result != null) results.add(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-form')));
  await tester.pumpAndSettle();

  return _Harness(container, results);
}

DropdownButtonFormField<String> _dropdown(WidgetTester tester, String key) {
  return tester.widget<DropdownButtonFormField<String>>(
    find.byKey(Key(key)),
  );
}

List<String> _itemLabels(WidgetTester tester, String key) {
  final finder = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(DropdownButton<String>),
  );
  final dropdown = tester.widget<DropdownButton<String>>(finder);
  return dropdown.items!.map((item) => (item.child as Text).data!).toList();
}

TextField _textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key)));
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.widgetWithText(ElevatedButton, 'Guardar');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('crear envía el payload y vuelve con saved', (tester) async {
    final repository = _FakeQualificationRepository();
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: const QualificationFormSheet(
        classroomId: 'c1',
        students: [_student],
        initialStudentId: 's1',
      ),
    );

    expect(find.text('Cargar calificación'), findsOneWidget);
    expect(find.byKey(const Key('qualification-form-delete')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('qualification-form-score')),
      '8,5',
    );
    await _tapSave(tester);

    expect(repository.created?['studentId'], 's1');
    expect(repository.created?['classroomId'], 'c1');
    expect(repository.created?['score'], '8.5');
    expect(repository.created?['type'], 'Parcial');
    expect(repository.created?['period'], currentAcademicPeriod());
    expect(repository.created?['description'], '');
    expect(harness.results, [QualificationFormResult.saved]);
    expect(find.byType(QualificationFormSheet), findsNothing);
  });

  testWidgets('editar prellena los campos y fija alumno y aula',
      (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(
          scoreLabel: '9.5',
          type: 'Oral',
          category: 'Desempeño',
          period: '2',
          description: 'Muy bien',
        ),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    expect(find.text('Editar calificación'), findsOneWidget);
    expect(
        _textField(tester, 'qualification-form-score').controller?.text, '9.5');
    expect(
      _textField(tester, 'qualification-form-description').controller?.text,
      'Muy bien',
    );
    expect(find.text('Desempeño'), findsOneWidget);

    final classroomDropdown = _dropdown(tester, 'qualification-form-classroom');
    final studentDropdown = _dropdown(tester, 'qualification-form-student');
    expect(classroomDropdown.onChanged, isNull);
    expect(studentDropdown.onChanged, isNull);
    expect(classroomDropdown.initialValue, 'c1');
    expect(studentDropdown.initialValue, 's1');
    expect(find.text('3G X'), findsOneWidget);

    final typeDropdown = _dropdown(tester, 'qualification-form-type');
    final periodDropdown = _dropdown(tester, 'qualification-form-period');
    expect(typeDropdown.initialValue, 'Oral');
    expect(periodDropdown.initialValue, '2');
    expect(_itemLabels(tester, 'qualification-form-type'), contains('Oral'));
    expect(_itemLabels(tester, 'qualification-form-period'), contains('2°'));
    expect(find.text('2°'), findsOneWidget);
  });

  testWidgets('editar actualiza con los valores del formulario',
      (tester) async {
    final repository = _FakeQualificationRepository();
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(
          type: 'Oral',
          category: 'Desempeño',
          period: '2',
          description: 'Muy bien',
        ),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await tester.enterText(
      find.byKey(const Key('qualification-form-score')),
      '7,5',
    );

    await tester.tap(find.byKey(const Key('qualification-form-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Final').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qualification-form-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3°').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('qualification-form-description')),
      'Actualizada',
    );

    await _tapSave(tester);

    expect(repository.updatedId, 'q1');
    expect(repository.updated?['studentId'], 's1');
    expect(repository.updated?['classroomId'], 'c1');
    expect(repository.updated?['score'], '7.5');
    expect(repository.updated?['type'], 'Final');
    expect(repository.updated?['period'], '3');
    expect(repository.updated?['category'], 'Desempeño');
    expect(repository.updated?['description'], 'Actualizada');
    expect(harness.results, [QualificationFormResult.saved]);
  });

  testWidgets('acepta una nota textual', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await tester.enterText(
      find.byKey(const Key('qualification-form-score')),
      'Excelente',
    );
    await _tapSave(tester);

    expect(repository.updated?['score'], 'Excelente');
  });

  testWidgets('editar conserva un tipo y un período desconocidos',
      (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(type: 'Proyecto', period: '4'),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    final typeDropdown = _dropdown(tester, 'qualification-form-type');
    final periodDropdown = _dropdown(tester, 'qualification-form-period');
    expect(typeDropdown.initialValue, 'Proyecto');
    expect(periodDropdown.initialValue, '4');
    expect(
        _itemLabels(tester, 'qualification-form-type'), contains('Proyecto'));
    expect(_itemLabels(tester, 'qualification-form-period'), contains('4°'));

    await _tapSave(tester);

    expect(repository.updated?['type'], 'Proyecto');
    expect(repository.updated?['period'], '4');
  });

  testWidgets('editar conserva una nota original desconocida sin cambios',
      (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(scoreLabel: 'Sobresaliente'),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await _tapSave(tester);

    expect(repository.updated?['score'], 'Sobresaliente');
  });

  testWidgets('admin ve eliminar en edición', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
      role: 'admin',
    );

    expect(
      find.byKey(const Key('qualification-form-delete')),
      findsOneWidget,
    );
  });

  testWidgets('profesor no ve eliminar en edición', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
      role: 'professor',
    );

    expect(
      find.byKey(const Key('qualification-form-delete')),
      findsNothing,
    );
  });

  testWidgets('crear nunca muestra eliminar aunque sea admin', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: const QualificationFormSheet(
        classroomId: 'c1',
        students: [_student],
        initialStudentId: 's1',
      ),
      role: 'admin',
    );

    expect(
      find.byKey(const Key('qualification-form-delete')),
      findsNothing,
    );
  });

  testWidgets('confirmar elimina la nota y vuelve con deleted', (tester) async {
    final repository = _FakeQualificationRepository();
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await tester.tap(find.byKey(const Key('qualification-form-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);

    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(repository.deletedId, 'q1');
    expect(harness.results, [QualificationFormResult.deleted]);
    expect(find.byType(QualificationFormSheet), findsNothing);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repository = _FakeQualificationRepository();
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await tester.tap(find.byKey(const Key('qualification-form-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deletedId, isNull);
    expect(harness.results, isEmpty);
    expect(find.byType(QualificationFormSheet), findsOneWidget);
  });

  testWidgets('un 422 pinta el error de la nota', (tester) async {
    final repository = _FakeQualificationRepository()
      ..updateError = ValidationException(
        fieldErrors: const {'score': 'La nota no es válida'},
      );
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    await _tapSave(tester);

    expect(find.text('La nota no es válida'), findsOneWidget);
    expect(harness.results, isEmpty);
    expect(find.byType(QualificationFormSheet), findsOneWidget);
  });

  testWidgets('una nota inválida no se envía', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpForm(
      tester,
      repository: repository,
      form: const QualificationFormSheet(
        classroomId: 'c1',
        students: [_student],
        initialStudentId: 's1',
      ),
    );

    await tester.enterText(
      find.byKey(const Key('qualification-form-score')),
      '11',
    );
    await _tapSave(tester);

    expect(find.text('Ingresá una nota entre 0 y 10'), findsOneWidget);
    expect(repository.created, isNull);

    await tester.enterText(
      find.byKey(const Key('qualification-form-score')),
      'NaN',
    );
    await _tapSave(tester);

    expect(find.text('Ingresá una nota entre 0 y 10'), findsOneWidget);
    expect(repository.created, isNull);
  });

  testWidgets('guardar invalida notas del alumno, aula y boletín',
      (tester) async {
    final repository = _FakeQualificationRepository();
    final harness = await _pumpForm(
      tester,
      repository: repository,
      form: QualificationFormSheet(
        qualification: _qualification(),
        classroomId: 'c1',
        students: const [_student],
        initialStudentId: 's1',
      ),
    );

    final subscriptions = [
      harness.container.listen(studentGradesProvider('s1'), (_, __) {}),
      harness.container.listen(classroomGradesProvider('c1'), (_, __) {}),
      harness.container.listen(
        boletinProvider((studentId: 's1', classroomId: 'c1')),
        (_, __) {},
      ),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });
    await tester.pumpAndSettle();

    final studentCalls = repository.studentGradesCalls;
    final classroomCalls = repository.classroomSummaryCalls;
    final boletinCalls = repository.boletinCalls;
    expect(studentCalls, greaterThan(0));
    expect(classroomCalls, greaterThan(0));
    expect(boletinCalls, greaterThan(0));

    await _tapSave(tester);

    expect(repository.studentGradesCalls, greaterThan(studentCalls));
    expect(repository.classroomSummaryCalls, greaterThan(classroomCalls));
    expect(repository.boletinCalls, greaterThan(boletinCalls));
  });
}
