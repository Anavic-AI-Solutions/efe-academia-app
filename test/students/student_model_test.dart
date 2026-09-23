import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentModel', () {
    test('parses the student attributes', () {
      final model = StudentModel.fromJson({
        'type': 'student_data',
        'id': 's1',
        'attributes': {
          'fullname': 'Ana Gómez',
          'email': 'ana@example.com',
          'year': '2026',
          'status': 'active',
          'identity_number': '30111222',
          'branch': 'Reconquista',
        },
      });

      expect(model.id, 's1');
      expect(model.fullname, 'Ana Gómez');
      expect(model.email, 'ana@example.com');
      expect(model.year, '2026');
      expect(model.status, 'active');
      expect(model.identityNumber, '30111222');
      expect(model.branch, 'Reconquista');
    });

    test('counts classrooms from the relationships when present', () {
      final model = StudentModel.fromJson({
        'type': 'student_data',
        'id': 's1',
        'attributes': {'fullname': 'Ana Gómez'},
        'relationships': {
          'classrooms': {
            'data': [
              {'type': 'classrooms', 'id': 'c1'},
              {'type': 'classrooms', 'id': 'c2'},
            ],
          },
        },
      });

      expect(model.classroomCount, 2);
    });

    test('defaults the classroom count to zero', () {
      final model = StudentModel.fromJson({
        'type': 'student_data',
        'id': 's1',
        'attributes': {'fullname': 'Ana Gómez'},
      });

      expect(model.classroomCount, 0);
    });
  });
}
