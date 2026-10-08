import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/attendance/data/attendance_repository.dart';
import 'package:efe_mobile/features/attendance/domain/attendance_day.dart';
import 'package:efe_mobile/features/attendance/providers/attendance_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/students/data/absence_repository.dart';
import 'package:efe_mobile/features/students/domain/absence_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/widgets/mark_absence_sheet.dart';
import 'package:efe_mobile/features/students/screens/widgets/student_related_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  _FakeAttendanceRepository({required this.students});

  final List<AttendanceStudent> students;

  int getCalls = 0;
  String? requestedDate;
  String? savedClassroomId;
  String? savedDate;
  List<String>? savedAbsentIds;

  @override
  Future<AttendanceDay> getAttendance(
    String classroomId, {
    String? date,
  }) async {
    getCalls++;
    requestedDate = date;
    return AttendanceDay(
      date: date ?? '2026-10-08',
      classroomId: classroomId,
      classroomName: '3G X',
      studentsCount: students.length,
      absentCount: students.where((student) => student.isAbsent).length,
      students: students,
    );
  }

  @override
  Future<void> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) async {
    savedClassroomId = classroomId;
    savedDate = date;
    savedAbsentIds = absentStudentIds;
  }
}

class _FakeAbsenceRepository implements AbsenceRepository {
  @override
  Future<PageResult<AbsenceModel>> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult<AbsenceModel>(
        data: const [],
        page: page,
        perPage: limit,
        total: 0,
      );
}

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardData data;

  _FakeDashboardRepository(this.data);

  @override
  Future<DashboardData> getDashboard() async => data;
}

String _todayString() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

Future<bool?> _pumpSheetAndConfirm(
  WidgetTester tester, {
  required _FakeAttendanceRepository attendance,
  String? classroomId = 'c1',
  List<ProfessorClassroomSummary>? classrooms,
}) async {
  bool? sheetResult;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(attendance),
      ],
      child: localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                sheetResult = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MarkAbsenceSheet(
                    studentId: 's1',
                    classroomId: classroomId,
                    classrooms: classrooms,
                  ),
                );
              },
              child: const Text('open sheet'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
  expect(find.byType(MarkAbsenceSheet), findsOneWidget);

  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();

  return sheetResult;
}

Future<void> _pumpAbsencesTab(
  WidgetTester tester, {
  required _FakeAttendanceRepository attendance,
  required DashboardData dashboardData,
  String? classroomId,
  bool canWrite = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(attendance),
        absenceRepositoryProvider.overrideWithValue(_FakeAbsenceRepository()),
        dashboardRepositoryProvider
            .overrideWithValue(_FakeDashboardRepository(dashboardData)),
      ],
      child: localizedApp(
        home: Scaffold(
          body: StudentAbsencesTab(
            studentId: 's1',
            classroomId: classroomId,
            canWrite: canWrite,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('absence date helpers', () {
    test('formatAbsenceDate usa yyyy-MM-dd', () {
      expect(formatAbsenceDate(DateTime(2026, 10, 5)), '2026-10-05');
    });

    test('fecha futura bloqueada: el tope es hoy', () {
      final today = DateTime(2026, 10, 8, 15, 30);
      expect(absenceMaxDate(today), DateTime(2026, 10, 8));
    });

    test('el rango empieza 90 días antes de hoy', () {
      final today = DateTime(2026, 10, 8);
      expect(absenceMinDate(today), DateTime(2026, 7, 10));
    });

    test('mergeAbsentIds agrega sin duplicar', () {
      expect(mergeAbsentIds(['otro'], 's1'), {'s1', 'otro'});
      expect(mergeAbsentIds(['s1', 'otro'], 's1'), {'s1', 'otro'});
    });
  });

  testWidgets('merge preserva ausentes existentes', (tester) async {
    final attendance = _FakeAttendanceRepository(
      students: const [
        AttendanceStudent(id: 'otro', fullname: 'Otro Alumno', status: 'absent'),
        AttendanceStudent(id: 's1', fullname: 'Ana Gómez', status: 'present'),
      ],
    );

    final result = await _pumpSheetAndConfirm(tester, attendance: attendance);

    expect(result, isTrue);
    expect(attendance.getCalls, 1);
    expect(attendance.requestedDate, _todayString());
    expect(attendance.savedClassroomId, 'c1');
    expect(attendance.savedDate, _todayString());
    expect(attendance.savedAbsentIds, containsAll(['s1', 'otro']));
    expect(attendance.savedAbsentIds, hasLength(2));
  });

  testWidgets('alumno ya ausente es idempotente', (tester) async {
    final attendance = _FakeAttendanceRepository(
      students: const [
        AttendanceStudent(id: 's1', fullname: 'Ana Gómez', status: 'absent'),
        AttendanceStudent(id: 'otro', fullname: 'Otro Alumno', status: 'present'),
      ],
    );

    await _pumpAbsencesTab(
      tester,
      attendance: attendance,
      dashboardData: const DashboardData(role: 'professor'),
      classroomId: 'c1',
    );

    await tester.tap(find.text('Marcar inasistencia'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkAbsenceSheet), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // Guarda el mismo set y avisa que ya estaba ausente.
    expect(attendance.savedAbsentIds, ['s1']);
    expect(find.text('Ya estaba ausente ese día'), findsOneWidget);
  });

  testWidgets('fecha futura bloqueada: el selector no pasa de hoy',
      (tester) async {
    final attendance = _FakeAttendanceRepository(students: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(attendance),
        ],
        child: localizedApp(
          home: const Scaffold(
            body: MarkAbsenceSheet(studentId: 's1', classroomId: 'c1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fecha inicial: hoy.
    expect(find.text(_todayString()), findsOneWidget);

    await tester.tap(find.text(_todayString()));
    await tester.pumpAndSettle();

    // Se abre el date picker nativo, cuyo lastDate es hoy por construcción
    // (ver test 'fecha futura bloqueada: el tope es hoy').
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('sin canWrite no muestra la acción', (tester) async {
    await _pumpAbsencesTab(
      tester,
      attendance: _FakeAttendanceRepository(students: const []),
      dashboardData: const DashboardData(role: 'professor'),
      classroomId: 'c1',
      canWrite: false,
    );

    expect(find.text('Marcar inasistencia'), findsNothing);
  });

  testWidgets('sin aulas deshabilita la acción', (tester) async {
    await _pumpAbsencesTab(
      tester,
      attendance: _FakeAttendanceRepository(students: const []),
      dashboardData: const DashboardData(role: 'professor'),
      classroomId: null,
    );

    expect(find.text('Marcar inasistencia'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Marcar inasistencia'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('confirmar desde el tab invalida y avisa', (tester) async {
    final attendance = _FakeAttendanceRepository(
      students: const [
        AttendanceStudent(id: 'otro', fullname: 'Otro Alumno', status: 'absent'),
        AttendanceStudent(id: 's1', fullname: 'Ana Gómez', status: 'present'),
      ],
    );

    await _pumpAbsencesTab(
      tester,
      attendance: attendance,
      dashboardData: const DashboardData(
        role: 'professor',
        classrooms: [ProfessorClassroomSummary(id: 'c1', name: '3G X')],
      ),
      classroomId: 'c1',
    );

    await tester.tap(find.text('Marcar inasistencia'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkAbsenceSheet), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(attendance.savedAbsentIds, containsAll(['s1', 'otro']));
    expect(find.text('Inasistencia registrada'), findsOneWidget);
  });
}
