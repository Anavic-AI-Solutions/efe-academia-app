import 'package:efe_mobile/features/menu/domain/menu_entry.dart';
import 'package:flutter_test/flutter_test.dart';

List<MenuSection> _sectionsFor(String role) =>
    MenuEntry.forRole(role).map((entry) => entry.section).toList();

void main() {
  group('MenuEntry role matrix', () {
    test('exposes exactly the twelve product sections', () {
      expect(MenuEntry.all, hasLength(12));
      expect(
        MenuEntry.all.map((entry) => entry.section).toSet(),
        MenuSection.values.toSet(),
      );
    });

    test('every role sees the common sections', () {
      const common = [
        MenuSection.calendar,
        MenuSection.courses,
        MenuSection.communication,
        MenuSection.profile,
        MenuSection.history,
        MenuSection.library,
        MenuSection.documents,
        MenuSection.faq,
        MenuSection.statistics,
      ];

      for (final role in [
        'admin',
        'branch',
        'professor',
        'parent',
        'student',
        'unknown',
        '',
      ]) {
        final sections = _sectionsFor(role);
        for (final section in common) {
          expect(
            sections,
            contains(section),
            reason: '$role should see $section',
          );
        }
      }
    });

    test('notifications and fees only for student and parent', () {
      for (final role in ['student', 'parent']) {
        expect(_sectionsFor(role), contains(MenuSection.notifications));
        expect(_sectionsFor(role), contains(MenuSection.fees));
      }

      for (final role in [
        'admin',
        'branch',
        'sede',
        'professor',
        'unknown',
        '',
      ]) {
        expect(
          _sectionsFor(role),
          isNot(contains(MenuSection.notifications)),
          reason: '$role must not see notifications',
        );
        expect(
          _sectionsFor(role),
          isNot(contains(MenuSection.fees)),
          reason: '$role must not see fees',
        );
      }
    });

    test('birthdays for admin, branch, professor and parent only', () {
      for (final role in ['admin', 'branch', 'sede', 'professor', 'parent']) {
        expect(
          _sectionsFor(role),
          contains(MenuSection.birthdays),
          reason: '$role should see birthdays',
        );
      }

      for (final role in ['student', 'unknown', '']) {
        expect(
          _sectionsFor(role),
          isNot(contains(MenuSection.birthdays)),
          reason: '$role must not see birthdays',
        );
      }
    });

    test('unknown roles keep exactly the nine shared sections', () {
      expect(_sectionsFor('unknown'), hasLength(9));
      expect(_sectionsFor(''), hasLength(9));
    });

    test('sede is treated as branch', () {
      expect(_sectionsFor('sede'), _sectionsFor('branch'));
    });
  });

  group('MenuEntry navigation', () {
    MenuEntry entryFor(MenuSection section) =>
        MenuEntry.all.firstWhere((entry) => entry.section == section);

    test('parent fees go to the payments shell tab', () {
      final fees = entryFor(MenuSection.fees);
      expect(fees.routeFor('parent'), '/payments');
      expect(fees.isShellTabFor('parent'), isTrue);
      expect(fees.routeFor('student'), '/fees');
      expect(fees.isShellTabFor('student'), isFalse);
    });

    test('courses, communication and profile switch shell tabs', () {
      for (final section in [
        MenuSection.courses,
        MenuSection.communication,
        MenuSection.profile,
      ]) {
        final entry = entryFor(section);
        expect(entry.isShellTabFor('student'), isTrue);
        expect(entry.isShellTabFor('admin'), isTrue);
      }
    });

    test('parent courses use a stacked route instead of the Pagos tab', () {
      final courses = entryFor(MenuSection.courses);

      expect(courses.routeFor('parent'), '/parent-courses');
      expect(courses.isShellTabFor('parent'), isFalse);
      expect(courses.routeFor('student'), '/classrooms');
      expect(courses.isShellTabFor('student'), isTrue);
    });

    test('stacked sections are pushed on top of the menu', () {
      for (final section in [
        MenuSection.calendar,
        MenuSection.notifications,
        MenuSection.history,
        MenuSection.library,
        MenuSection.documents,
        MenuSection.faq,
        MenuSection.birthdays,
        MenuSection.statistics,
      ]) {
        final entry = entryFor(section);
        expect(entry.isShellTabFor('admin'), isFalse);
      }
    });
  });
}
