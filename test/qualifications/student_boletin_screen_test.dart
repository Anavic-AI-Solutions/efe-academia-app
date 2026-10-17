import 'dart:async';

import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/grade_badge.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/qualifications/screens/student_boletin_screen.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

/// URL firmada que devuelve el repo falso en el test de descarga.
const _boletinUrl = 'https://efe.test/boletin/s1/c1/file?signature=abc';

/// Repositorio de calificaciones falso: boletines por aula, contador de
/// llamadas por aula (para el refetch de los chips), estados de carga/error
/// del boletín y URL/error del link firmado del PDF.
class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({
    Map<String, BoletinData>? boletines,
    this.boletinUrl = _boletinUrl,
    this.linkError,
  }) : boletines = boletines ?? {};

  final Map<String, BoletinData> boletines;
  final String boletinUrl;
  final ApiException? linkError;

  final callsByClassroom = <String, int>{};
  final linkCalls = <({String studentId, String classroomId})>[];

  Completer<BoletinData>? pendingBoletin;
  bool failBoletin = false;

  int callsFor(String classroomId) => callsByClassroom[classroomId] ?? 0;

  @override
  Future<BoletinData> getBoletin(String studentId, String classroomId) async {
    callsByClassroom[classroomId] = callsFor(classroomId) + 1;
    final pending = pendingBoletin;
    if (pending != null) return pending.future;
    if (failBoletin) {
      throw ApiException(message: 'network error', statusCode: 500);
    }
    return boletines[classroomId]!;
  }

  @override
  Future<String> getBoletinUrl(String studentId, String classroomId) async {
    linkCalls.add((studentId: studentId, classroomId: classroomId));
    final error = linkError;
    if (error != null) throw error;
    return boletinUrl;
  }

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
  ) =>
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
}

/// Repositorio de alumnos falso: solo resuelve las aulas del hijo (el resto
/// de la ficha no se usa en esta pantalla); puede fallar para el ErrorView.
class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({
    this.classrooms = const [],
    this.failClassrooms = false,
  });

  final List<ClassroomModel> classrooms;
  bool failClassrooms;

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async {
    if (failClassrooms) {
      throw ApiException(message: 'network error', statusCode: 500);
    }
    return classrooms;
  }

  @override
  Future<StudentModel> getStudent(String id) => throw UnimplementedError();

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();
}

const _classroom1 = ClassroomModel(id: 'c1', name: '3G X');
const _classroom2 = ClassroomModel(id: 'c2', name: '4G Y');

/// Boletín de prueba con valores por defecto neutros (sin notas ni listas).
BoletinData _boletin({
  String classroomId = 'c1',
  String classroomName = '3G X',
  String fullname = 'Ana Pérez',
  List<String> periods = const ['1', '2', '3'],
  List<BoletinQualification> qualifications = const [],
  Map<String, double?> averages = const {},
  BoletinAbsences absences = const BoletinAbsences(),
  List<BoletinObservation> observations = const [],
}) =>
    BoletinData(
      studentId: 's1',
      studentFullname: fullname,
      classroomId: classroomId,
      classroomName: classroomName,
      periods: periods,
      qualifications: qualifications,
      averages: averages,
      absences: absences,
      observations: observations,
    );

/// Boletín “completo” de un aula: notas en los períodos 1 y 3, asistencia con
/// períodos 1/3 (el 2 ausente), dos inasistencias y una observación.
BoletinData _fullBoletin({
  String classroomId = 'c1',
  String classroomName = '3G X',
  String score = '8',
  double average = 8.0,
}) =>
    _boletin(
      classroomId: classroomId,
      classroomName: classroomName,
      qualifications: [
        BoletinQualification(
          type: 'Escrito',
          category: 'Desempeño',
          period: '1',
          score: score,
        ),
        const BoletinQualification(
          type: 'Excelente',
          category: 'Actitud',
          period: '1',
          score: 'A',
        ),
        const BoletinQualification(
          type: 'Oral',
          category: 'Desempeño',
          period: '3',
          score: '7.75',
        ),
      ],
      averages: {'1': average, '3': 7.75},
      absences: const BoletinAbsences(
        total: 6,
        justified: 2,
        unjustified: 4,
        attendanceByPeriod: {'1': 95.0, '3': 88.5},
        list: [
          BoletinAbsence(date: '2026-08-12', quantity: 1, justified: true),
          BoletinAbsence(date: '2026-08-20', quantity: 3, justified: false),
        ],
      ),
      observations: const [
        BoletinObservation(
          date: '2026-08-15',
          description: 'Se destaca en lectura',
          period: '1',
        ),
      ],
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeQualificationRepository qualificationRepository,
  required _FakeStudentRepository studentRepository,
  Future<bool> Function(Uri)? openUrl,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  // Superficie alta para que todas las secciones queden montadas a la vez.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    qualificationRepositoryProvider.overrideWithValue(qualificationRepository),
    studentRepositoryProvider.overrideWithValue(studentRepository),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: testLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        home: StudentBoletinScreen(studentId: 's1', openUrl: openUrl),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(testLocale);
  });

  group('1) una sola aula', () {
    testWidgets('secciones completas, promedio coloreado y sin chips',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );

      // Encabezado con el título y el nombre del hijo; sin chips de aula.
      expect(find.text(es.boletinTitle), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('3G X'), findsNothing);

      // Las cuatro secciones (SectionHeader las muestra en mayúsculas).
      expect(find.text(es.studentsTabGrades.toUpperCase()), findsOneWidget);
      expect(find.text(es.dashboardAttendance.toUpperCase()), findsOneWidget);
      expect(find.text(es.studentsTabAbsences.toUpperCase()), findsOneWidget);
      expect(find.text(es.boletinObservations.toUpperCase()), findsOneWidget);

      // Notas por período con datos: el período 2 no arma card.
      expect(find.text(es.boletinPeriod(1)), findsNWidgets(2)); // card + obs
      expect(find.text(es.boletinPeriod(2)), findsNothing);
      expect(find.text(es.boletinPeriod(3)), findsOneWidget);
      expect(find.text('Escrito'), findsOneWidget);
      expect(find.text('Excelente'), findsOneWidget);
      expect(find.text('Oral'), findsOneWidget);

      // Promedio por período con el color de la escala de notas.
      final badges =
          tester.widgetList<GradeBadge>(find.byType(GradeBadge)).toList();
      expect(badges.map((b) => b.grade), [8.0, 7.75]);
      final badgeBox = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GradeBadge).first,
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (badgeBox.decoration! as BoxDecoration).color,
        AppColors.gradeColor(8.0),
      );

      // Nota numérica coloreada; el texto no numérico va tal cual.
      expect(
        tester.widget<Text>(find.text('8')).style?.color,
        AppColors.gradeColor(8.0),
      );
      expect(
        tester.widget<Text>(find.text('A')).style?.color,
        AppColors.inkFor(false),
      );

      // Asistencia: resumen y % por período; el período ausente va con “—”.
      expect(find.text(es.feesDetailTotal), findsOneWidget);
      expect(find.text(AppFormatters.formatNumber(6)), findsOneWidget);
      expect(find.text(AppFormatters.formatNumber(2)), findsOneWidget);
      expect(find.text(AppFormatters.formatNumber(4)), findsOneWidget);
      // Etiquetas del resumen + badges de las inasistencias.
      expect(find.text(es.studentsAbsenceJustified), findsNWidgets(2));
      expect(find.text(es.studentsAbsenceUnjustified), findsNWidgets(2));
      expect(find.text('1° Período: 95,00%'), findsOneWidget);
      expect(find.text('2° Período: —'), findsOneWidget);
      expect(find.text('3° Período: 88,50%'), findsOneWidget);

      // Inasistencias: fecha · cantidad · badge justificada/sin justificar.
      expect(find.text('2026-08-12'), findsOneWidget);
      expect(find.text('2026-08-20'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(es.studentsAbsenceJustified),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(es.studentsAbsenceUnjustified),
        ),
        findsOneWidget,
      );

      // Observaciones: fecha · descripción · período.
      expect(find.text('2026-08-15'), findsOneWidget);
      expect(find.text('Se destaca en lectura'), findsOneWidget);

      // Descarga fija al pie.
      expect(
        find.widgetWithText(PillButton, es.boletinDownloadAction),
        findsOneWidget,
      );
      expect(find.text(es.boletinNoGrades), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('2) dos o más aulas', () {
    testWidgets('chips visibles; cambiar de chip refetchea y cambia los datos',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(score: '8', average: 8.0),
        'c2': _fullBoletin(
          classroomId: 'c2',
          classroomName: '4G Y',
          score: '9',
          average: 9.0,
        ),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository:
            _FakeStudentRepository(classrooms: const [_classroom1, _classroom2]),
      );

      // Chips de ambas aulas y datos de la primera (default).
      expect(find.text('3G X'), findsOneWidget);
      expect(find.text('4G Y'), findsOneWidget);
      expect(repo.callsFor('c1'), 1);
      expect(repo.callsFor('c2'), 0);
      expect(find.text('8'), findsOneWidget);

      await tester.tap(find.text('4G Y'));
      await tester.pumpAndSettle();

      // Refetch por aula: se pide la segunda y los datos cambian sin mezclar.
      expect(repo.callsFor('c2'), 1);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('8'), findsNothing);
    });
  });

  group('3) sin aulas', () {
    testWidgets('muestra el vacío de aulas sin crash', (tester) async {
      await _pumpScreen(
        tester,
        qualificationRepository: _FakeQualificationRepository(),
        studentRepository: _FakeStudentRepository(),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(es.classroomsEmptyTitle), findsOneWidget);
      expect(
        find.widgetWithText(PillButton, es.boletinDownloadAction),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('4) aula sin notas', () {
    testWidgets('boletinNoGrades con el resto de secciones visibles',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _boletin(
          absences: const BoletinAbsences(
            total: 4,
            justified: 1,
            unjustified: 3,
            attendanceByPeriod: {'1': 90.0},
            list: [
              BoletinAbsence(
                date: '2026-09-02',
                quantity: 2,
                justified: false,
              ),
            ],
          ),
        ),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );

      expect(find.text(es.boletinNoGrades), findsOneWidget);
      expect(find.byType(GradeBadge), findsNothing);

      // Asistencia e inasistencias siguen visibles.
      expect(find.text(es.dashboardAttendance.toUpperCase()), findsOneWidget);
      expect(find.text('1° Período: 90,00%'), findsOneWidget);
      expect(find.text('2° Período: —'), findsOneWidget);
      expect(find.text(es.studentsTabAbsences.toUpperCase()), findsOneWidget);
      expect(find.text('2026-09-02'), findsOneWidget);

      expect(
        find.widgetWithText(PillButton, es.boletinDownloadAction),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('5) secciones vacías', () {
    testWidgets('observaciones vacías ⇒ sección oculta', (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin().copyWith(observations: const []),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );

      expect(find.text(es.boletinObservations.toUpperCase()), findsNothing);
      expect(find.text(es.studentsTabAbsences.toUpperCase()), findsOneWidget);
    });

    testWidgets('inasistencias vacías ⇒ sección oculta', (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin().copyWith(
          absences: const BoletinAbsences(
            total: 6,
            justified: 2,
            unjustified: 4,
            attendanceByPeriod: {'1': 95.0},
          ),
        ),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );

      expect(find.text(es.studentsTabAbsences.toUpperCase()), findsNothing);
      expect(find.text(es.boletinObservations.toUpperCase()), findsOneWidget);
      // El resumen de asistencia sigue visible.
      expect(find.text('1° Período: 95,00%'), findsOneWidget);
    });
  });

  group('6) descarga del boletín', () {
    testWidgets('tap → openUrl recibe la URL firmada del repo',
        (tester) async {
      Uri? opened;
      final repo = _FakeQualificationRepository(
        boletines: {'c1': _fullBoletin()},
        boletinUrl: _boletinUrl,
      );
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
        openUrl: (uri) async {
          opened = uri;
          return true;
        },
      );

      await tester.tap(find.widgetWithText(PillButton, es.boletinDownloadAction));
      await tester.pumpAndSettle();

      expect(repo.linkCalls, hasLength(1));
      expect(repo.linkCalls.single.studentId, 's1');
      expect(repo.linkCalls.single.classroomId, 'c1');
      expect(opened, Uri.parse(_boletinUrl));
      expect(find.text(es.boletinDownloadError), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fallo del link (404) ⇒ snackbar boletinDownloadError',
        (tester) async {
      Uri? opened;
      final repo = _FakeQualificationRepository(
        boletines: {'c1': _fullBoletin()},
        linkError: ApiException(message: 'not found', statusCode: 404),
      );
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
        openUrl: (uri) async {
          opened = uri;
          return true;
        },
      );

      await tester.tap(find.widgetWithText(PillButton, es.boletinDownloadAction));
      await tester.pumpAndSettle();

      expect(find.text(es.boletinDownloadError), findsOneWidget);
      expect(opened, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el launcher devuelve false ⇒ snackbar boletinDownloadError',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
        openUrl: (uri) async => false,
      );

      await tester.tap(find.widgetWithText(PillButton, es.boletinDownloadAction));
      await tester.pumpAndSettle();

      expect(find.text(es.boletinDownloadError), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('7) estados', () {
    testWidgets('loading muestra shimmer y luego los datos', (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      })..pendingBoletin = Completer<BoletinData>();
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
        settle: false,
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ListShimmer), findsOneWidget);
      expect(find.byType(GradeBadge), findsNothing);

      repo.pendingBoletin!.complete(repo.boletines['c1']!);
      repo.pendingBoletin = null;
      await tester.pumpAndSettle();

      expect(find.byType(ListShimmer), findsNothing);
      expect(find.text('Escrito'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error del boletín ⇒ ErrorView y retry refetchea',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      })..failBoletin = true;
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(es.gradesLoadError), findsOneWidget);
      expect(repo.callsFor('c1'), 1);

      repo.failBoletin = false;
      await tester.tap(find.text(es.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(repo.callsFor('c1'), 2);
      expect(find.text('Escrito'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error de aulas ⇒ ErrorView y retry', (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      });
      final studentRepo = _FakeStudentRepository(
        classrooms: const [_classroom1],
        failClassrooms: true,
      );
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: studentRepo,
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(es.classroomsLoadError), findsOneWidget);

      studentRepo.failClassrooms = false;
      await tester.tap(find.text(es.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(repo.callsFor('c1'), 1);
      expect(find.text('Escrito'), findsOneWidget);
    });

    testWidgets('pull-to-refresh refetchea el boletín del aula',
        (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository: _FakeStudentRepository(classrooms: const [_classroom1]),
      );
      expect(repo.callsFor('c1'), 1);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();

      expect(repo.callsFor('c1'), 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark renderiza sin excepciones', (tester) async {
      final repo = _FakeQualificationRepository(boletines: {
        'c1': _fullBoletin(),
      });
      await _pumpScreen(
        tester,
        qualificationRepository: repo,
        studentRepository:
            _FakeStudentRepository(classrooms: const [_classroom1, _classroom2]),
        brightness: Brightness.dark,
      );

      expect(find.text(es.boletinTitle), findsOneWidget);
      expect(find.text(es.studentsTabGrades.toUpperCase()), findsOneWidget);
      expect(find.text('Escrito'), findsOneWidget);
      // El chip elegido usa `accentFor` (contraste del contrato en dark).
      expect(
        tester.widget<Text>(find.text('3G X')).style?.color,
        AppColors.accentFor(true),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
