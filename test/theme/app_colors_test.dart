import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unified blue tokens match the spec', () {
    expect(AppColors.primary, const Color(0xFF3F6EA8));
    expect(AppColors.primarySoft, const Color(0xFF5F92C9));
    expect(AppColors.accent, const Color(0xFF83B0E0));
    expect(AppColors.lightBackground, const Color(0xFFF5F6FA));
    expect(AppColors.roleProfessor, AppColors.primary);
    expect(AppColors.accentFor(false), AppColors.primary);
    expect(AppColors.accentFor(true), AppColors.accent);
    expect(AppColors.inkFor(false), AppColors.lightInk);
    expect(AppColors.backgroundFor(false), AppColors.lightBackground);
    expect(AppColors.backgroundFor(true), AppColors.darkBackground);
    expect(AppColors.gradeColor(9.2), AppColors.gradeHigh);
    expect(AppColors.gradeColor(5.0), AppColors.gradeWarn);
    expect(AppColors.gradeColor(null), AppColors.muted);
    expect(AppColors.formatGrade(null), '—');
  });
}
