import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Groups used to organise the menu sections.
enum MenuGroup { academic, communication, accountSupport }

/// The exact twelve sections exposed by the mobile menu.
///
/// This enum is intentionally closed: adding a new value here means adding a
/// new section to the product, which must be reflected in the role matrix and
/// in the localized labels.
enum MenuSection {
  calendar,
  courses,
  requests,
  communication,
  notifications,
  profile,
  fees,
  history,
  library,
  documents,
  faq,
  birthdays,
  statistics,
}

class MenuEntry {
  final MenuSection section;
  final MenuGroup group;
  final IconData icon;
  final String route;

  const MenuEntry({
    required this.section,
    required this.group,
    required this.icon,
    required this.route,
  });

  /// All sections in display order: academic, communication, account.
  static const List<MenuEntry> all = [
    MenuEntry(
      section: MenuSection.calendar,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.calendarBlank,
      route: '/calendar',
    ),
    MenuEntry(
      section: MenuSection.courses,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.chalkboardTeacher,
      route: '/classrooms',
    ),
    MenuEntry(
      section: MenuSection.requests,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.clipboardText,
      route: '/requests',
    ),
    MenuEntry(
      section: MenuSection.history,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.clockCounterClockwise,
      route: '/history',
    ),
    MenuEntry(
      section: MenuSection.library,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.bookOpen,
      route: '/library',
    ),
    MenuEntry(
      section: MenuSection.documents,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.fileText,
      route: '/documents',
    ),
    MenuEntry(
      section: MenuSection.statistics,
      group: MenuGroup.academic,
      icon: PhosphorIconsRegular.chartBar,
      route: '/statistics',
    ),
    MenuEntry(
      section: MenuSection.communication,
      group: MenuGroup.communication,
      icon: PhosphorIconsRegular.chatCircle,
      route: '/chat',
    ),
    MenuEntry(
      section: MenuSection.notifications,
      group: MenuGroup.communication,
      icon: PhosphorIconsRegular.bell,
      route: '/notifications',
    ),
    MenuEntry(
      section: MenuSection.profile,
      group: MenuGroup.accountSupport,
      icon: PhosphorIconsRegular.userCircle,
      route: '/profile',
    ),
    MenuEntry(
      section: MenuSection.fees,
      group: MenuGroup.accountSupport,
      icon: PhosphorIconsRegular.wallet,
      route: '/fees',
    ),
    MenuEntry(
      section: MenuSection.birthdays,
      group: MenuGroup.accountSupport,
      icon: PhosphorIconsRegular.cake,
      route: '/birthdays',
    ),
    MenuEntry(
      section: MenuSection.faq,
      group: MenuGroup.accountSupport,
      icon: PhosphorIconsRegular.question,
      route: '/faqs',
    ),
  ];

  /// Menu sections visible for [role].
  ///
  /// Unknown roles only get the sections available to everyone: they must not
  /// see notifications, fees or birthdays.
  static List<MenuEntry> forRole(String role) {
    final normalized = _normalizeRole(role);
    return all.where((entry) => entry.isVisibleFor(normalized)).toList();
  }

  bool isVisibleFor(String role) {
    final normalized = _normalizeRole(role);
    switch (section) {
      case MenuSection.notifications:
      case MenuSection.fees:
        return normalized == 'student' || normalized == 'parent';
      case MenuSection.birthdays:
        return normalized == 'admin' ||
            normalized == 'branch' ||
            normalized == 'professor' ||
            normalized == 'parent';
      case MenuSection.requests:
        return normalized == 'admin' || normalized == 'branch';
      default:
        return true;
    }
  }

  /// The route can depend on the role (parents pay from the payments tab and
  /// browse their children's courses from a stacked section).
  String routeFor(String role) {
    final normalized = _normalizeRole(role);
    if (section == MenuSection.fees && normalized == 'parent') {
      return '/payments';
    }
    if (section == MenuSection.courses && normalized == 'parent') {
      return '/parent-courses';
    }
    return route;
  }

  /// Routes that live inside the main shell and therefore switch tabs instead
  /// of stacking a new page on top of the menu.
  bool isShellTabFor(String role) {
    final normalized = _normalizeRole(role);
    switch (section) {
      case MenuSection.courses:
        // Parents have no "Cursos" tab: branch 1 is their "Pagos" tab, so
        // pushing a stacked route avoids highlighting Pagos while browsing
        // courses.
        return normalized != 'parent';
      case MenuSection.communication:
      case MenuSection.profile:
        return true;
      case MenuSection.fees:
        return normalized == 'parent';
      default:
        return false;
    }
  }

  static String _normalizeRole(String role) {
    final value = role.trim().toLowerCase();
    // The mobile API exposes the branch role as "branch"; accept the web name
    // as a fallback so both spellings behave the same.
    return value == 'sede' ? 'branch' : value;
  }
}

/// Convenience function matching the interface documented in the plan.
List<MenuEntry> menuEntriesForRole(String role) => MenuEntry.forRole(role);
