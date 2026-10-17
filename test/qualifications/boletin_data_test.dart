import 'package:efe_mobile/features/qualifications/domain/boletin_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoletinData.fromJson', () {
    test('parses the full payload from the api', () {
      final boletin = BoletinData.fromJson({
        'data': {
          'student': {'id': 's1', 'fullname': 'Marega, Paola'},
          'classroom': {'id': 'c1', 'name': '3G X'},
          'periods': ['1', '2', '3'],
          'qualifications': [
            {
              'type': 'Escrito',
              'category': 'Desempeño',
              'period': '1',
              'score': '8',
            },
            {
              'type': 'Oral',
              'category': 'Conceptual',
              'period': '2',
              'score': '7.5',
            },
          ],
          'averages': {'1': 8.0, '2': null, '3': 7.75},
          'absences': {
            'total': 5,
            'justified': 2,
            'unjustified': 3,
            'attendance_by_period': {'1': 95.0, '3': 88.5},
            'list': [
              {'date': '2026-03-10', 'quantity': 1, 'justified': true},
              {'date': '2026-03-11', 'quantity': 2, 'justified': false},
            ],
          },
          'observations': [
            {
              'date': '2026-03-12',
              'description': 'Excelente desempeño',
              'period': '1',
            },
          ],
        },
      });

      expect(boletin.studentId, 's1');
      expect(boletin.studentFullname, 'Marega, Paola');
      expect(boletin.classroomId, 'c1');
      expect(boletin.classroomName, '3G X');
      expect(boletin.periods, ['1', '2', '3']);

      expect(boletin.qualifications, hasLength(2));
      expect(boletin.qualifications.first.type, 'Escrito');
      expect(boletin.qualifications.first.category, 'Desempeño');
      expect(boletin.qualifications.first.period, '1');
      expect(boletin.qualifications.first.score, '8');
      expect(boletin.qualifications.last.score, '7.5');

      expect(boletin.averages['1'], 8.0);
      expect(boletin.averages['2'], isNull);
      expect(boletin.averages['3'], 7.75);

      expect(boletin.absences.total, 5);
      expect(boletin.absences.justified, 2);
      expect(boletin.absences.unjustified, 3);
      expect(boletin.absences.attendanceByPeriod['1'], 95.0);
      expect(boletin.absences.attendanceByPeriod['3'], 88.5);

      expect(boletin.absences.list, hasLength(2));
      expect(boletin.absences.list.first.date, '2026-03-10');
      expect(boletin.absences.list.first.quantity, 1);
      expect(boletin.absences.list.first.justified, isTrue);
      expect(boletin.absences.list.last.quantity, 2);
      expect(boletin.absences.list.last.justified, isFalse);

      expect(boletin.observations, hasLength(1));
      expect(boletin.observations.single.date, '2026-03-12');
      expect(boletin.observations.single.description, 'Excelente desempeño');
      expect(boletin.observations.single.period, '1');
    });

    test('tolerates attendance periods with missing keys (R10)', () {
      final boletin = BoletinData.fromJson({
        'data': {
          'absences': {
            'total': 1,
            'attendance_by_period': {'1': 95.0, '3': null},
          },
        },
      });

      expect(boletin.absences.attendanceByPeriod.containsKey('2'), isFalse);
      expect(boletin.absences.attendanceByPeriod['1'], 95.0);
      expect(boletin.absences.attendanceByPeriod['3'], isNull);
    });

    test('defaults every collection when the payload is empty', () {
      final boletin = BoletinData.fromJson({});

      expect(boletin.studentId, '');
      expect(boletin.studentFullname, '');
      expect(boletin.classroomId, '');
      expect(boletin.classroomName, '');
      expect(boletin.periods, isEmpty);
      expect(boletin.qualifications, isEmpty);
      expect(boletin.averages, isEmpty);
      expect(boletin.absences.total, 0);
      expect(boletin.absences.justified, 0);
      expect(boletin.absences.unjustified, 0);
      expect(boletin.absences.attendanceByPeriod, isEmpty);
      expect(boletin.absences.list, isEmpty);
      expect(boletin.observations, isEmpty);
    });

    test('accepts a payload without the data wrapper and a null classroom',
        () {
      final boletin = BoletinData.fromJson({
        'student': {'id': 's1', 'fullname': 'Marega, Paola'},
        'classroom': null,
        'periods': ['1'],
      });

      expect(boletin.studentFullname, 'Marega, Paola');
      expect(boletin.classroomId, '');
      expect(boletin.classroomName, '');
      expect(boletin.periods, ['1']);
    });

    test('parses tolerant justified values (bool, 1 and "1")', () {
      final boletin = BoletinData.fromJson({
        'data': {
          'absences': {
            'list': [
              {'date': '2026-03-10', 'quantity': 1, 'justified': true},
              {'date': '2026-03-11', 'quantity': 1, 'justified': 1},
              {'date': '2026-03-12', 'quantity': 1, 'justified': '1'},
              {'date': '2026-03-13', 'quantity': 1, 'justified': false},
            ],
          },
        },
      });

      expect(
        boletin.absences.list.map((a) => a.justified),
        [true, true, true, false],
      );
    });

    test('parses string numbers for averages and attendance', () {
      final boletin = BoletinData.fromJson({
        'data': {
          'averages': {'1': '8.5'},
          'absences': {
            'attendance_by_period': {'1': '95.0'},
          },
        },
      });

      expect(boletin.averages['1'], 8.5);
      expect(boletin.absences.attendanceByPeriod['1'], 95.0);
    });
  });
}
