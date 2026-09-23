import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfessorModel', () {
    test('parses professor attributes', () {
      final model = ProfessorModel.fromJson({
        'type': 'professor_data',
        'id': 'p1',
        'attributes': {
          'fullname': 'Ana Pérez',
          'email': 'ana@example.com',
          'phone': '3411234567',
          'address': 'Calle 1',
          'identity_number': '30111222',
          'bio': 'Profesora de matemática',
          'specialty': 'Matemática',
        },
      });

      expect(model.id, 'p1');
      expect(model.fullname, 'Ana Pérez');
      expect(model.email, 'ana@example.com');
      expect(model.phone, '3411234567');
      expect(model.address, 'Calle 1');
      expect(model.identityNumber, '30111222');
      expect(model.bio, 'Profesora de matemática');
      expect(model.specialty, 'Matemática');
    });

    test('defaults missing attributes to empty strings', () {
      final model = ProfessorModel.fromJson({
        'type': 'professor_data',
        'id': 'p1',
        'attributes': {'fullname': 'Ana Pérez'},
      });

      expect(model.email, '');
      expect(model.specialty, '');
    });
  });
}
