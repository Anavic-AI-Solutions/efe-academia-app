import 'package:dio/dio.dart';
import 'package:efe_mobile/features/attendance/data/attendance_api.dart';
import 'package:efe_mobile/features/attendance/data/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttendanceApi implements AttendanceApi {
  final Map<String, dynamic> payload;
  String? savedClassroomId;
  String? savedDate;
  List<String>? savedAbsentStudentIds;

  _FakeAttendanceApi(this.payload);

  @override
  Future<Response> getAttendance(String classroomId) async => Response(
        requestOptions: RequestOptions(path: '/classrooms/$classroomId/attendance'),
        data: payload,
      );

  @override
  Future<Response> saveAttendance(
    String classroomId, {
    required String date,
    required List<String> absentStudentIds,
  }) async {
    savedClassroomId = classroomId;
    savedDate = date;
    savedAbsentStudentIds = absentStudentIds;

    return Response(
      requestOptions: RequestOptions(path: '/classrooms/$classroomId/attendance'),
      data: {
        'data': {'date': date, 'present_count': 1, 'absent_count': 1},
      },
    );
  }
}

void main() {
  group('AttendanceRepository', () {
    test('parses the attendance day payload', () async {
      final repository = AttendanceRepository(
        _FakeAttendanceApi({
          'data': {
            'type': 'attendance',
            'id': 'classroom-1-2026-09-24',
            'attributes': {
              'date': '2026-09-24',
              'classroom_id': 'classroom-1',
              'classroom_name': '3G X',
              'students_count': 2,
              'absent_count': 1,
              'students': [
                {
                  'id': 's1',
                  'fullname': 'Marega, Paola',
                  'status': 'present',
                  'absence_id': null,
                },
                {
                  'id': 's2',
                  'fullname': 'López, Juan',
                  'status': 'absent',
                  'absence_id': 12,
                },
              ],
            },
          },
        }),
      );

      final day = await repository.getAttendance('classroom-1');

      expect(day.date, '2026-09-24');
      expect(day.classroomName, '3G X');
      expect(day.students, hasLength(2));
      expect(day.absentCount, 1);
      expect(day.students.first.isAbsent, isFalse);
      expect(day.students.last.isAbsent, isTrue);
      expect(day.students.last.absenceId, 12);
    });

    test('sends the date and absent student ids when saving', () async {
      final api = _FakeAttendanceApi({});
      final repository = AttendanceRepository(api);

      await repository.saveAttendance(
        'classroom-1',
        date: '2026-09-24',
        absentStudentIds: ['s2'],
      );

      expect(api.savedClassroomId, 'classroom-1');
      expect(api.savedDate, '2026-09-24');
      expect(api.savedAbsentStudentIds, ['s2']);
    });
  });
}
