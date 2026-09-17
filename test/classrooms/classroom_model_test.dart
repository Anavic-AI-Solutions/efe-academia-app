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
