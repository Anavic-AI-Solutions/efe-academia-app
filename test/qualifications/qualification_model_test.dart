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
  });
}
