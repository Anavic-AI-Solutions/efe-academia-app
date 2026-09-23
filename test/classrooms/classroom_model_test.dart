import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassroomModel', () {
    test('parses level from JSON:API attributes', () {
      final model = ClassroomModel.fromJson({
        'type': 'classrooms',
        'id': 'abc-123',
        'attributes': {
          'name': 'A2 A',
          'level': 'A2',
          'branch': 'Reconquista',
          'year': '2026',
          'student_count': 12,
        },
      });

      expect(model.id, 'abc-123');
      expect(model.name, 'A2 A');
      expect(model.level, 'A2');
      expect(model.branch, 'Reconquista');
      expect(model.year, '2026');
      expect(model.studentCount, 12);
    });

    test('defaults level to empty string when missing', () {
      final model = ClassroomModel.fromJson({
        'type': 'classrooms',
        'id': 'abc-123',
        'attributes': {'name': 'No level'},
      });

      expect(model.level, '');
    });

    test('parses extended attributes', () {
      final model = ClassroomModel.fromJson({
        'type': 'classrooms',
        'id': 'abc-123',
        'attributes': {
          'name': 'A2 A',
          'grade': '1',
          'book': 'Libro 1',
          'commission': 'A',
          'course_days': 3,
          'period_1_days': 2,
          'period_2_days': 2,
          'period_3_days': 3,
          'is_active': false,
          'is_archivated': true,
        },
      });

      expect(model.grade, '1');
      expect(model.book, 'Libro 1');
      expect(model.commission, 'A');
      expect(model.courseDays, 3);
      expect(model.period1Days, 2);
      expect(model.period2Days, 2);
      expect(model.period3Days, 3);
      expect(model.isActive, isFalse);
    });

    test('counts students from the relationships when present', () {
      final model = ClassroomModel.fromJson({
        'type': 'classrooms',
        'id': 'abc-123',
        'attributes': {'name': 'A2 A', 'student_count': 1},
        'relationships': {
          'students': {
            'data': [
              {'type': 'students', 'id': 's1'},
              {'type': 'students', 'id': 's2'},
              {'type': 'students', 'id': 's3'},
            ],
          },
        },
      });

      expect(model.studentCount, 3);
    });

    test('defaults to active when is_active is missing', () {
      final model = ClassroomModel.fromJson({
        'type': 'classrooms',
        'id': 'abc-123',
        'attributes': {'name': 'A2 A'},
      });

      expect(model.isActive, isTrue);
    });
  });

  group('ClassroomFilters', () {
    test('parses filter options payload', () {
      final filters = ClassroomFilters.fromJson({
        'data': {
          'branches': ['Reconquista', 'Vera'],
          'levels': ['A2', 'B1'],
          'years': ['2025', '2026'],
          'statuses': ['active', 'archived'],
        },
      });

      expect(filters.branches, ['Reconquista', 'Vera']);
      expect(filters.levels, ['A2', 'B1']);
      expect(filters.years, ['2025', '2026']);
      expect(filters.statuses, ['active', 'archived']);
    });

    test('defaults to empty lists when payload is empty', () {
      final filters = ClassroomFilters.fromJson({});

      expect(filters.branches, isEmpty);
      expect(filters.levels, isEmpty);
      expect(filters.years, isEmpty);
      expect(filters.statuses, isEmpty);
    });
  });
}
