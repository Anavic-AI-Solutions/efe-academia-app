import 'package:efe_mobile/app/theme/professor_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfessorColors.gradeColor', () {
    test('maps grades to the mockup color scale', () {
      expect(ProfessorColors.gradeColor(9.2), ProfessorColors.gradeHigh);
      expect(ProfessorColors.gradeColor(8), ProfessorColors.gradeHigh);
      expect(ProfessorColors.gradeColor(7.5), ProfessorColors.gradeMid);
      expect(ProfessorColors.gradeColor(6), ProfessorColors.gradeMid);
      expect(ProfessorColors.gradeColor(5.8), ProfessorColors.gradeWarn);
      expect(ProfessorColors.gradeColor(4), ProfessorColors.gradeWarn);
      expect(ProfessorColors.gradeColor(3.9), ProfessorColors.gradeLow);
      expect(ProfessorColors.gradeColor(null), ProfessorColors.muted);
    });
  });

  group('ProfessorColors.formatGrade', () {
    test('formats grades with one decimal and empty grades with a dash', () {
      expect(ProfessorColors.formatGrade(9.2), '9.2');
      expect(ProfessorColors.formatGrade(10), '10.0');
      expect(ProfessorColors.formatGrade(null), '—');
    });
  });
}
