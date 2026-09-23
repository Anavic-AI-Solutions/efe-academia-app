import 'package:efe_mobile/features/students/domain/absence_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbsenceModel', () {
    test('parses absence attributes', () {
      final model = AbsenceModel.fromJson({
        'type': 'absences',
        'id': '1',
        'attributes': {
          'quantity': 2,
          'period': '1',
          'justified': 'si',
          'description': 'Fiebre',
          'status': 'active',
          'date': '12/03/2026',
          'created_at': '12/03/2026',
        },
      });

      expect(model.id, '1');
      expect(model.quantity, 2);
      expect(model.period, '1');
      expect(model.justified, 'si');
      expect(model.description, 'Fiebre');
      expect(model.status, 'active');
      expect(model.date, '12/03/2026');
    });

    test('defaults missing attributes', () {
      final model = AbsenceModel.fromJson({
        'type': 'absences',
        'id': '1',
        'attributes': {'quantity': '3'},
      });

      expect(model.quantity, 3);
      expect(model.period, '');
      expect(model.justified, '');
      expect(model.description, '');
      expect(model.date, '');
    });
  });
}
