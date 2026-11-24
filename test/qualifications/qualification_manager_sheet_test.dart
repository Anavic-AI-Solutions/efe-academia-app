import 'dart:async';

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
import 'package:efe_mobile/features/qualifications/screens/widgets/qualification_manager_sheet.dart';
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
  _FakeQualificationRepository([List<QualificationModel>? grades])
      : grades = [...?grades];

  List<QualificationModel> grades;
  int studentGradesCalls = 0;
  int classroomSummaryCalls = 0;
  int boletinCalls = 0;
  String? deletedId;
  Object? deleteError;

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
    final targetStudent = grades.isEmpty ? null : grades.first.studentId;
    final data = targetStudent == null || targetStudent == studentId
        ? grades
        : const <QualificationModel>[];
    return PageResult(
      data: data,
      page: page,
      perPage: limit,
      total: data.length,
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
      students: const [],
    );
  }

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) async {
    boletinCalls++;
    return BoletinData(studentId: studentId, classroomId: classroomId);
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
  }) =>
      throw UnimplementedError();

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
  Future<void> deleteQualification(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedId = id;
    grades = grades.where((grade) => grade.id != id).toList();
  }
}

QualificationModel _qualification({
  String id = 'q1',
  String classroomId = 'c1',
  String classroomName = '3G X',
  String scoreLabel = '9.5',
  String type = 'Proyecto',
  String category = 'Final',
  String period = '2',
  String description = '',
}) {
  return QualificationModel(
    id: id,
    studentId: 's1',
    classroomId: classroomId,
    studentName: 'Ana Gómez',
    classroomName: classroomName,
    scoreLabel: scoreLabel,
    type: type,
    category: category,
    period: period,
    description: description,
  );
}

class _Harness {
  _Harness(this.container);

  final ProviderContainer container;
}

Future<_Harness> _pumpManager(
  WidgetTester tester, {
  required _FakeQualificationRepository repository,
  required QualificationManagerSheet manager,
  String role = 'admin',
}) async {
  tester.view.physicalSize = const Size(400 * 3, 1200 * 3);
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

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-manager'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => manager,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-manager')));
  await tester.pumpAndSettle();

  return _Harness(container);
}

Future<void> _openMenu(WidgetTester tester, String id) async {
  await tester.tap(
    find.byKey(Key('qualification-manager-menu-$id')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra todas las notas agrupadas por aula', (tester) async {
    final repository = _FakeQualificationRepository([
      _qualification(),
      _qualification(
        id: 'q2',
        classroomId: 'c2',
        classroomName: '4A Y',
        scoreLabel: 'Excelente',
        type: 'Parcial',
        period: '3',
      ),
    ]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    expect(find.text('Notas del alumno'), findsOneWidget);
    expect(find.text('3G X'), findsOneWidget);
    expect(find.text('4A Y'), findsOneWidget);
    // Type outside the preset grid and the web category are both visible.
    expect(find.text('Proyecto'), findsOneWidget);
    expect(find.text('Parcial'), findsOneWidget);
    expect(find.text('Final'), findsNWidgets(2));
    expect(find.text('9.5'), findsOneWidget);
    expect(find.text('Excelente'), findsOneWidget);
    expect(find.text('2°'), findsOneWidget);
    expect(find.text('3°'), findsOneWidget);
  });

  testWidgets('no mezcla aulas distintas con el mismo nombre', (tester) async {
    final repository = _FakeQualificationRepository([
      _qualification(),
      _qualification(
        id: 'q2',
        classroomId: 'c2',
        classroomName: '3G X',
        type: 'Parcial',
      ),
    ]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    // One heading per classroom id even though the names match.
    expect(find.text('3G X'), findsNWidgets(2));
    expect(find.text('Proyecto'), findsOneWidget);
    expect(find.text('Parcial'), findsOneWidget);
  });

  testWidgets('muestra un guion cuando la nota está vacía', (tester) async {
    final repository = _FakeQualificationRepository([
      _qualification(scoreLabel: ''),
    ]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('filtra por aula cuando recibe classroomId', (tester) async {
    final repository = _FakeQualificationRepository([
      _qualification(),
      _qualification(
        id: 'q2',
        classroomId: 'c2',
        classroomName: '4A Y',
        type: 'Parcial',
      ),
    ]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
        classroomId: 'c1',
      ),
    );

    expect(find.text('3G X'), findsOneWidget);
    expect(find.text('Proyecto'), findsOneWidget);
    expect(find.text('4A Y'), findsNothing);
    expect(find.text('Parcial'), findsNothing);
  });

  testWidgets('editar abre el formulario prellenado', (tester) async {
    final repository = _FakeQualificationRepository([
      _qualification(description: 'Muy bien'),
    ]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    await _openMenu(tester, 'q1');
    await tester.tap(find.byKey(const Key('qualification-manager-edit-q1')));
    await tester.pumpAndSettle();

    expect(find.byType(QualificationFormSheet), findsOneWidget);
    expect(find.text('Editar calificación'), findsOneWidget);

    final score = tester.widget<TextField>(
      find.byKey(const Key('qualification-form-score')),
    );
    final description = tester.widget<TextField>(
      find.byKey(const Key('qualification-form-description')),
    );
    expect(score.controller?.text, '9.5');
    expect(description.controller?.text, 'Muy bien');
    expect(
      find.descendant(
        of: find.byType(QualificationFormSheet),
        matching: find.text('Final'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('eliminar confirma, borra y refresca notas, aula y boletín',
      (tester) async {
    final repository = _FakeQualificationRepository([_qualification()]);
    final harness = await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    final subscriptions = [
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

    await _openMenu(tester, 'q1');
    await tester.tap(find.byKey(const Key('qualification-manager-delete-q1')));
    await tester.pumpAndSettle();

    expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);

    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(repository.deletedId, 'q1');
    expect(repository.studentGradesCalls, greaterThan(studentCalls));
    expect(repository.classroomSummaryCalls, greaterThan(classroomCalls));
    expect(repository.boletinCalls, greaterThan(boletinCalls));
    expect(find.text('Calificación eliminada'), findsOneWidget);
    expect(find.text('No hay notas cargadas'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repository = _FakeQualificationRepository([_qualification()]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    await _openMenu(tester, 'q1');
    await tester.tap(find.byKey(const Key('qualification-manager-delete-q1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deletedId, isNull);
    expect(find.text('Proyecto'), findsOneWidget);
  });

  testWidgets('muestra el estado vacío', (tester) async {
    final repository = _FakeQualificationRepository();
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
    );

    expect(
        find.byKey(const Key('qualification-manager-empty')), findsOneWidget);
    expect(find.text('No hay notas cargadas'), findsOneWidget);
    expect(
      find.text('Cargá la primera nota con el botón inferior'),
      findsOneWidget,
    );
  });

  testWidgets('el profesor puede editar pero no eliminar', (tester) async {
    final repository = _FakeQualificationRepository([_qualification()]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
      role: 'professor',
    );

    await _openMenu(tester, 'q1');

    expect(
      find.byKey(const Key('qualification-manager-edit-q1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('qualification-manager-delete-q1')),
      findsNothing,
    );
  });

  testWidgets('el admin ve la acción de eliminar', (tester) async {
    final repository = _FakeQualificationRepository([_qualification()]);
    await _pumpManager(
      tester,
      repository: repository,
      manager: const QualificationManagerSheet(
        studentId: 's1',
        studentFullname: 'Ana Gómez',
      ),
      role: 'admin',
    );

    await _openMenu(tester, 'q1');

    expect(
      find.byKey(const Key('qualification-manager-delete-q1')),
      findsOneWidget,
    );
  });
}
