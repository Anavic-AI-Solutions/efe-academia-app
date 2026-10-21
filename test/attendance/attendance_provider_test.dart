import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/attendance/data/attendance_repository.dart';
import 'package:efe_mobile/features/attendance/domain/attendance_day.dart';
import 'package:efe_mobile/features/attendance/providers/attendance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  final AttendanceDay day;
  bool failOnLoad = false;
  bool failOnSave = false;
  String? savedDate;
  List<String>? savedAbsentIds;

  _FakeAttendanceRepository(this.day);

  @override
  Future<AttendanceDay> getAttendance(String classroomId,
      {String? date}) async {
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
    if (failOnSave) {
      throw ApiException(message: 'save failed');
    }
    savedDate = date;
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

Future<ProviderContainer> _setup(
  _FakeAttendanceRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      attendanceRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  // Keep the autoDispose provider alive while the test runs.
  final subscription = container.listen(
    attendanceProvider('c1'),
    (previous, next) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);

  await pumpEventQueue();

  return container;
}

void main() {
  group('AttendanceNotifier', () {
    test('loads the attendance day without pending changes', () async {
      final container = await _setup(_FakeAttendanceRepository(_day));

      final state = container.read(attendanceProvider('c1'));
      expect(state.day?.students, hasLength(2));
      expect(state.day?.absentCount, 1);
      expect(state.hasChanges, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('toggle marks a student absent and flags changes', () async {
      final container = await _setup(_FakeAttendanceRepository(_day));
      final notifier = container.read(attendanceProvider('c1').notifier);

      notifier.toggle('s1');

      var state = container.read(attendanceProvider('c1'));
      expect(state.day?.students.first.isAbsent, isTrue);
      expect(state.day?.absentCount, 2);
      expect(state.hasChanges, isTrue);

      notifier.toggle('s1');

      state = container.read(attendanceProvider('c1'));
      expect(state.day?.students.first.isAbsent, isFalse);
      expect(state.day?.absentCount, 1);
      expect(state.hasChanges, isFalse);
    });

    test('save sends the absent ids and clears the pending changes', () async {
      final repository = _FakeAttendanceRepository(_day);
      final container = await _setup(repository);
      final notifier = container.read(attendanceProvider('c1').notifier);

      notifier.toggle('s1');
      final saved = await notifier.save();

      expect(saved, isTrue);
      expect(repository.savedDate, '2026-09-24');
      expect(repository.savedAbsentIds, containsAll(['s1', 's2']));

      final state = container.read(attendanceProvider('c1'));
      expect(state.hasChanges, isFalse);
      expect(state.saved, isTrue);
      expect(state.saveError, isNull);
    });

    test('save failure keeps the changes and exposes the error', () async {
      final repository = _FakeAttendanceRepository(_day)..failOnSave = true;
      final container = await _setup(repository);
      final notifier = container.read(attendanceProvider('c1').notifier);

      notifier.toggle('s1');
      final saved = await notifier.save();

      expect(saved, isFalse);

      final state = container.read(attendanceProvider('c1'));
      expect(state.hasChanges, isTrue);
      expect(state.saved, isFalse);
      expect(state.saveError, isNotNull);
    });

    test('load failure exposes the error', () async {
      final container =
          await _setup(_FakeAttendanceRepository(_day)..failOnLoad = true);

      expect(container.read(attendanceProvider('c1')).error, isNotNull);
    });
  });
}
