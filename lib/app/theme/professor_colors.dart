import 'package:flutter/material.dart';

/// Design tokens from the professor mobile mockup (2026-09).
class ProfessorColors {
  ProfessorColors._();

  static const Color primary = Color(0xFF3F6EA8);
  static const Color primarySoft = Color(0xFF5F92C9);
  static const Color accent = Color(0xFF83B0E0);
  static const Color ink = Color(0xFF2F4A6B);
  static const Color muted = Color(0xFF71799A);
  static const Color sectionLabel = Color(0xFF8792B5);
  static const Color surface = Color(0xFFF5F6FA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryMuted = Color(0xFFC4CDEC);
  static const Color navInactive = Color(0xFF9AA2BD);
  static const Color overlay = Color(0x1FFFFFFF);
  static const Color overlayStrong = Color(0x2EFFFFFF);

  static const Color present = Color(0xFF2FA36C);
  static const Color absent = Color(0xFFE05353);

  static const Color gradeHigh = Color(0xFF2FA36C);
  static const Color gradeMid = Color(0xFF4A5AA0);
  static const Color gradeWarn = Color(0xFFE0912F);
  static const Color gradeLow = Color(0xFFE05353);
  static const Color gradeEmptyBackground = Color(0xFFEEF0F6);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primarySoft, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
