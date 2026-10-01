import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../qualifications/domain/qualification_model.dart';
import '../../domain/student_grade_grid.dart';

/// Read-only grid of a student's qualifications, mirroring the web grade
/// table: periods as rows, criteria as columns, horizontal scroll.
class StudentGradesGrid extends StatelessWidget {
  final List<QualificationModel> qualifications;
  final String? classroomName;
  final bool isProfessor;

  const StudentGradesGrid({
    super.key,
    required this.qualifications,
    this.classroomName,
    this.isProfessor = false,
  });

  static const double _periodWidth = 86;
  static const double _cellWidth = 62;
  static const double _averageWidth = 78;
  static const double _headerHeight = 30;
  static const double _rowHeight = 42;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = buildGradeGrid(qualifications);

    final headerColor = isProfessor
        ? AppColors.sectionLabel
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);
    final valueColor = isProfessor
        ? AppColors.lightInk
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final mutedColor = AppColors.muted;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gradesGridTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (classroomName != null && classroomName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    classroomName!,
                    style: AppTypography.bodySmall.copyWith(color: mutedColor),
                  ),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: [
                    _HeaderCell(
                      label: l10n.gradesGridPeriod,
                      width: _periodWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridPerformance,
                      width: _cellWidth * 2,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridAttitude,
                      width: _cellWidth * 4,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridExam,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridAverage,
                      width: _averageWidth,
                      color: headerColor,
                      borderColor: borderColor,
                      last: true,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _HeaderCell(
                      label: '',
                      width: _periodWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridWritten,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridOral,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridHomework,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridDiscipline,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridParticipation,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: l10n.gradesGridAttendance,
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: '',
                      width: _cellWidth,
                      color: headerColor,
                      borderColor: borderColor,
                    ),
                    _HeaderCell(
                      label: '',
                      width: _averageWidth,
                      color: headerColor,
                      borderColor: borderColor,
                      last: true,
                    ),
                  ],
                ),
                for (final row in rows)
                  Row(
                    children: [
                      _BodyCell(
                        label: l10n.gradesGridTerm(int.parse(row.period)),
                        width: _periodWidth,
                        color: valueColor,
                        mutedColor: mutedColor,
                        borderColor: borderColor,
                        bold: true,
                      ),
                      for (final cell in row.cells)
                        _BodyCell(
                          label: (cell?.scoreLabel.isNotEmpty ?? false)
                              ? cell!.scoreLabel
                              : '—',
                          width: _cellWidth,
                          color: valueColor,
                          mutedColor: mutedColor,
                          borderColor: borderColor,
                        ),
                      _BodyCell(
                        label: row.average?.toStringAsFixed(2) ?? '—',
                        width: _averageWidth,
                        color: row.average == null
                            ? mutedColor
                            : (row.average! >= 6
                                ? AppColors.success
                                : AppColors.error),
                        mutedColor: mutedColor,
                        borderColor: borderColor,
                        bold: true,
                        last: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final Color color;
  final Color borderColor;
  final bool last;

  const _HeaderCell({
    required this.label,
    required this.width,
    required this.color,
    required this.borderColor,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: StudentGradesGrid._headerHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: last
              ? BorderSide.none
              : BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String label;
  final double width;
  final Color color;
  final Color mutedColor;
  final Color borderColor;
  final bool bold;
  final bool last;

  const _BodyCell({
    required this.label,
    required this.width,
    required this.color,
    required this.mutedColor,
    required this.borderColor,
    this.bold = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = label == '—';

    return Container(
      width: width,
      height: StudentGradesGrid._rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: last
              ? BorderSide.none
              : BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: isEmpty ? mutedColor : color,
        ),
      ),
    );
  }
}
