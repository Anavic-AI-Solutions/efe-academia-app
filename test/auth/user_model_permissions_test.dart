import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user(String role) =>
    UserModel(id: '1', name: 'U', email: 'u@x.com', role: role);

void main() {
  group('admin', () {
    test('has every management permission', () {
      final user = _user('admin');

      expect(user.isAdmin, isTrue);
      expect(user.isBranch, isFalse);
      expect(user.isStaff, isTrue);
      expect(user.isProfessor, isFalse);

      expect(user.canManageStudents, isTrue);
      expect(user.canManageProfessors, isTrue);
      expect(user.canManageParents, isTrue);
      expect(user.canManageClassrooms, isTrue);
      expect(user.canManageMaterials, isTrue);
      expect(user.canManageNews, isTrue);
      expect(user.canManageEvents, isTrue);
      expect(user.canManageDocuments, isTrue);
      expect(user.canManageFaqs, isTrue);
      expect(user.canManageQualifications, isTrue);
      expect(user.canDeleteQualifications, isTrue);
    });
  });

  group('branch', () {
    test('manages everything except professors and FAQs', () {
      final user = _user('branch');

      expect(user.isAdmin, isFalse);
      expect(user.isBranch, isTrue);
      expect(user.isStaff, isTrue);
      expect(user.isProfessor, isFalse);

      expect(user.canManageProfessors, isFalse);
      expect(user.canManageFaqs, isFalse);

      expect(user.canManageStudents, isTrue);
      expect(user.canManageParents, isTrue);
      expect(user.canManageClassrooms, isTrue);
      expect(user.canManageMaterials, isTrue);
      expect(user.canManageNews, isTrue);
      expect(user.canManageEvents, isTrue);
      expect(user.canManageDocuments, isTrue);
      expect(user.canManageQualifications, isTrue);
      expect(user.canDeleteQualifications, isTrue);
    });
  });

  group('professor', () {
    test('manages events and qualifications only', () {
      final user = _user('professor');

      expect(user.isAdmin, isFalse);
      expect(user.isBranch, isFalse);
      expect(user.isStaff, isFalse);
      expect(user.isProfessor, isTrue);

      expect(user.canManageEvents, isTrue);
      expect(user.canManageQualifications, isTrue);
      expect(user.canManageMaterials, isTrue);

      expect(user.canManageNews, isFalse);
      expect(user.canManageStudents, isFalse);
      expect(user.canDeleteQualifications, isFalse);
      expect(user.canManageProfessors, isFalse);
      expect(user.canManageParents, isFalse);
      expect(user.canManageClassrooms, isFalse);
      expect(user.canManageDocuments, isFalse);
      expect(user.canManageFaqs, isFalse);
    });
  });

  for (final role in ['parent', 'student']) {
    group(role, () {
      test('has no management permissions', () {
        final user = _user(role);

        expect(user.isAdmin, isFalse);
        expect(user.isBranch, isFalse);
        expect(user.isStaff, isFalse);
        expect(user.isProfessor, isFalse);

        expect(user.canManageStudents, isFalse);
        expect(user.canManageProfessors, isFalse);
        expect(user.canManageParents, isFalse);
        expect(user.canManageClassrooms, isFalse);
        expect(user.canManageMaterials, isFalse);
        expect(user.canManageNews, isFalse);
        expect(user.canManageEvents, isFalse);
        expect(user.canManageDocuments, isFalse);
        expect(user.canManageFaqs, isFalse);
        expect(user.canManageQualifications, isFalse);
        expect(user.canDeleteQualifications, isFalse);
      });
    });
  }
}
