import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (unified blue)
  static const Color primary = Color(0xFF3F6EA8);
  static const Color primarySoft = Color(0xFF5F92C9);
  static const Color accent = Color(0xFF83B0E0);
  static const Color primaryLight = Color(0xFFEBF0F6);

  // Secondary / Accent
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFEF3C7);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);
  static const Color lightSearchFill = Color(0xFFF1F5F9);
  static const Color lightInk = Color(0xFF2F4A6B);
  static const Color lightMuted = Color(0xFF71799A);
  static const Color muted = Color(0xFF71799A);
  static const Color sectionLabel = Color(0xFF8792B5);
  static const Color navInactive = Color(0xFF9AA2BD);

  // On primary (text over gradient)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryMuted = Color(0xFFC4CDEC);
  static const Color overlay = Color(0x1FFFFFFF);
  static const Color overlayStrong = Color(0x2EFFFFFF);

  // Attendance
  static const Color present = Color(0xFF2FA36C);
  static const Color absent = Color(0xFFE05353);

  // Grade scale
  static const Color gradeHigh = Color(0xFF2FA36C);
  static const Color gradeMid = Color(0xFF4A5AA0);
  static const Color gradeWarn = Color(0xFFE0912F);
  static const Color gradeLow = Color(0xFFE05353);
  static const Color gradeEmptyBackground = Color(0xFFEEF0F6);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF273549);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkSearchFill = Color(0xFF334155);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primarySoft, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [primary, primarySoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Role colors
  static const Color roleAdmin = Color(0xFFEF4444);
  static const Color roleBranch = Color(0xFFF97316);
  static const Color roleProfessor = primary;
  static const Color roleStudent = Color(0xFF10B981);
  static const Color roleParent = primarySoft;

  // Brightness helpers
  static Color accentFor(bool isDark) => isDark ? accent : primary;
  static Color inkFor(bool isDark) => isDark ? darkTextPrimary : lightInk;
  static Color mutedFor(bool isDark) => isDark ? darkTextSecondary : lightMuted;
  static Color backgroundFor(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color chipFor(bool isDark) =>
      isDark ? darkSurfaceElevated : primaryLight;

  /// ≥8 high · 6-7.9 mid · 4-5.9 warn · <4 low · null muted.
  static Color gradeColor(double? grade) {
    if (grade == null) return muted;
    if (grade >= 8) return gradeHigh;
    if (grade >= 6) return gradeMid;
    if (grade >= 4) return gradeWarn;
    return gradeLow;
  }

  static String formatGrade(double? grade) {
    if (grade == null) return '—';
    return grade.toStringAsFixed(1);
  }
}
