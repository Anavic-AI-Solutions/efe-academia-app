import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QualificationModel', () {
    test('parses score, type, period and description', () {
      final model = QualificationModel.fromJson({
        'type': 'qualifications',
        'id': 'q1',
        'attributes': {
          'score': '8.5',
          'type': 'Parcial',
          'period': '1',
          'description': 'Primer parcial',
          'created_at': '12/03/2026',
        },
      });

      expect(model.id, 'q1');
      expect(model.score, 8.5);
      expect(model.type, 'Parcial');
      expect(model.period, '1');
      expect(model.description, 'Primer parcial');
      expect(model.date, '12/03/2026');
    });

    test('prefers date over created_at when present', () {
      final model = QualificationModel.fromJson({
        'type': 'qualifications',
        'id': 'q1',
        'attributes': {
          'score': 7,
          'date': '01/04/2026',
          'created_at': '12/03/2026',
        },
      });

      expect(model.date, '01/04/2026');
    });

    test('parses category, raw score label and nested classroom name', () {
      final model = QualificationModel.fromJson({
        'id': 'q2',
        'student_id': 's1',
        'classroom_id': 'c1',
        'score': 'Excelente',
        'type': 'Oral',
        'category': 'Desempeño',
        'period': '1',
        'classroom': {'id': 'c1', 'name': '3G X'},
      });

      expect(model.category, 'Desempeño');
      expect(model.scoreLabel, 'Excelente');
      expect(model.classroomName, '3G X');
      expect(model.score, 0.0);
    });

    test('prefers a plain classroom_name over the nested classroom', () {
      final model = QualificationModel.fromJson({
        'id': 'q3',
        'score': '9',
        'type': 'Escrito',
        'classroom_name': 'A2 B',
        'classroom': {'id': 'c1', 'name': '3G X'},
      });

      expect(model.classroomName, 'A2 B');
    });
  });
}
