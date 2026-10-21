import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/students/domain/student_grade_grid.dart';
import 'package:flutter_test/flutter_test.dart';

QualificationModel _qualification({
  required String type,
  required String period,
  String category = '',
  String score = '8',
}) {
  return QualificationModel(
    id: '$period-$type-$category',
    type: type,
    period: period,
    category: category,
    scoreLabel: score,
  );
}

void main() {
  group('qualificationScoreValue', () {
    test('parses numeric scores', () {
      expect(qualificationScoreValue('8.5'), 8.5);
      expect(qualificationScoreValue('10'), 10);
    });

    test('parses text scores with the web map', () {
      expect(qualificationScoreValue('Excelente'), 10);
      expect(qualificationScoreValue('muy bueno'), 9);
      expect(qualificationScoreValue('Bueno'), 7);
      expect(qualificationScoreValue('regular'), 6);
      expect(qualificationScoreValue('insuficiente'), 4);
      expect(qualificationScoreValue('mal'), 2);
    });

    test('returns null for empty or unknown scores', () {
      expect(qualificationScoreValue(null), isNull);
      expect(qualificationScoreValue(''), isNull);
      expect(qualificationScoreValue('  '), isNull);
      expect(qualificationScoreValue('sin nota'), isNull);
    });
  });

  group('buildGradeGrid', () {
    test('always builds the three periods in order', () {
      final rows = buildGradeGrid(const []);

      expect(rows.map((row) => row.period), ['1', '2', '3']);
      expect(rows.every((row) => row.cells.length == 7), isTrue);
      expect(rows.every((row) => row.average == null), isTrue);
      expect(
          rows.every((row) => row.cells.every((cell) => cell == null)), isTrue);
    });

    test('maps qualifications by period, type and category', () {
      final rows = buildGradeGrid([
        _qualification(
          type: 'Escrito',
          category: 'Desempeño',
          period: '1',
          score: '9',
        ),
        _qualification(
          type: 'Tareas',
          category: 'Actitud',
          period: '2',
          score: '6',
        ),
        _qualification(type: 'Parcial', period: '3', score: '7.5'),
      ]);

      expect(rows[0].cells[0]?.scoreLabel, '9');
      expect(rows[1].cells[2]?.scoreLabel, '6');
      expect(rows[2].cells[6]?.scoreLabel, '7.5');
    });

    test('falls back to the same type when the category is empty', () {
      final rows = buildGradeGrid([
        _qualification(type: 'Oral', period: '1', score: '8'),
      ]);

      expect(rows[0].cells[1]?.scoreLabel, '8');
    });

    test('prefers the exact category over the empty-category fallback', () {
      final rows = buildGradeGrid([
        _qualification(type: 'Oral', period: '1', score: '4'),
        _qualification(
          type: 'Oral',
          category: 'Desempeño',
          period: '1',
          score: '9',
        ),
      ]);

      expect(rows[0].cells[1]?.scoreLabel, '9');
    });

    test('computes the period average with numeric and text scores', () {
      final rows = buildGradeGrid([
        _qualification(
          type: 'Escrito',
          category: 'Desempeño',
          period: '1',
          score: '10',
        ),
        _qualification(
          type: 'Oral',
          category: 'Desempeño',
          period: '1',
          score: 'excelente',
        ),
        _qualification(
          type: 'Parcial',
          period: '1',
          score: 'no válida',
        ),
      ]);

      expect(rows[0].average, 10);
      expect(rows[1].average, isNull);
    });

    test('averages every valid score of the period, deduplicated by key', () {
      final rows = buildGradeGrid([
        _qualification(
          type: 'Escrito',
          category: 'Desempeño',
          period: '1',
          score: '4',
        ),
        _qualification(
          type: 'Escrito',
          category: 'Desempeño',
          period: '1',
          score: '8',
        ),
        _qualification(
          type: 'Oral',
          category: 'Desempeño',
          period: '1',
          score: '6',
        ),
      ]);

      expect(rows[0].average, 7);
    });
  });
}
