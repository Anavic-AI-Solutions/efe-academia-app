import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/attendance/data/attendance_repository.dart';
import 'package:efe_mobile/features/attendance/domain/attendance_day.dart';
import 'package:efe_mobile/features/attendance/providers/attendance_provider.dart';
import 'package:efe_mobile/features/attendance/screens/attendance_screen.dart';
import 'package:efe_mobile/features/attendance/screens/widgets/attendance_student_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  final AttendanceDay day;
  bool failOnLoad = false;
  List<String>? savedAbsentIds;

  _FakeAttendanceRepository(this.day);

  @override
  Future<AttendanceDay> getAttendance(String classroomId) async {
    if (failOnLoad) {
      throw ApiException(message: 'load failed');
    }

    return day;
  }

  @override
  Future<void> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) async {
    savedAbsentIds = absentStudentIds;
  }
}

const _day = AttendanceDay(
  date: '2026-09-24',
  classroomId: 'c1',
  classroomName: '3G X',
  studentsCount: 2,
  absentCount: 1,
  students: [
    AttendanceStudent(id: 's1', fullname: 'Marega, Paola', status: 'present'),
    AttendanceStudent(
      id: 's2',
      fullname: 'López, Juan',
      status: 'absent',
      absenceId: 12,
    ),
  ],
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester,
  _FakeAttendanceRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      attendanceRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: const AttendanceScreen(classroomId: 'c1'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('renders the roster and the day summary', (tester) async {
    await _pumpScreen(tester, _FakeAttendanceRepository(_day));

    expect(find.text('Asistencia · 3G X'), findsOneWidget);
    expect(find.textContaining('2 alumnos'), findsOneWidget);
    expect(find.text('Marega, Paola'), findsOneWidget);
    expect(find.text('López, Juan'), findsOneWidget);
    expect(find.text('Guardar asistencia'), findsOneWidget);
  });

  testWidgets('tapping the status toggles the student', (tester) async {
    final container =
        await _pumpScreen(tester, _FakeAttendanceRepository(_day));

    final maregaRow = find.ancestor(
      of: find.text('Marega, Paola'),
      matching: find.byType(AttendanceStudentRow),
    );

    await tester.tap(
      find.descendant(of: maregaRow, matching: find.text('A')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(attendanceProvider('c1')).day?.students.first.isAbsent,
      isTrue,
    );
  });

  testWidgets('saving sends the absent ids and confirms with a snackbar',
      (tester) async {
    final repository = _FakeAttendanceRepository(_day);
    await _pumpScreen(tester, repository);

    await tester.tap(find.text('Guardar asistencia'));
    await tester.pumpAndSettle();

    expect(repository.savedAbsentIds, ['s2']);
    expect(find.text('Asistencia guardada'), findsOneWidget);
  });

  testWidgets('shows an error view when loading fails', (tester) async {
    await _pumpScreen(
      tester,
      _FakeAttendanceRepository(_day)..failOnLoad = true,
    );

    expect(find.text('No se pudo cargar la asistencia'), findsOneWidget);
  });
}
