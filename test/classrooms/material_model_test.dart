import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaterialModel', () {
    test('parses material attributes', () {
      final model = MaterialModel.fromJson({
        'type': 'materials',
        'id': 'm1',
        'attributes': {
          'name': 'Apunte 1',
          'description': 'Unidad 1 en PDF',
          'type': 'pdf',
          'public_url': 'https://example.com/apunte.pdf',
          'category': 'teoria',
          'visibility': 'public',
          'available_until': '2026-12-31',
          'download_count': 4,
          'created_at': '2026-01-01T00:00:00Z',
        },
      });

      expect(model.id, 'm1');
      expect(model.name, 'Apunte 1');
      expect(model.description, 'Unidad 1 en PDF');
      expect(model.type, 'pdf');
      expect(model.publicUrl, 'https://example.com/apunte.pdf');
      expect(model.category, 'teoria');
      expect(model.visibility, 'public');
      expect(model.availableUntil, '2026-12-31');
      expect(model.downloadCount, 4);
      expect(model.createdAt, '2026-01-01T00:00:00Z');
    });

    test('defaults missing attributes', () {
      final model = MaterialModel.fromJson({
        'type': 'materials',
        'id': 'm1',
        'attributes': {'name': 'Apunte 1', 'download_count': '3'},
      });

      expect(model.type, '');
      expect(model.publicUrl, '');
      expect(model.downloadCount, 3);
      expect(model.studentIds, isEmpty);
    });

    test('parses student ids from the detail relationships', () {
      final model = MaterialModel.fromJson({
        'data': {
          'id': 'm1',
          'attributes': {'name': 'Guía'},
          'relationships': {
            'students': {
              'data': [
                {'type': 'students', 'id': 's1'},
                {'type': 'students', 'id': 's2'},
              ],
            },
          },
        },
      });

      expect(model.studentIds, ['s1', 's2']);
    });

    test('parses student ids from the classroom listing', () {
      final model = MaterialModel.fromJson({
        'id': 'm1',
        'name': 'Guía',
        'students': [
          {'id': 's1'},
        ],
      });

      expect(model.studentIds, ['s1']);
    });
  });
}
