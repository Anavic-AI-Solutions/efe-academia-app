import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/detail_hero.dart';
import '../../domain/classroom_model.dart';
import '../../../../l10n/l10n.dart';

class ClassroomDetailHeader extends StatelessWidget {
  final ClassroomModel classroom;
  final bool showActions;
  final VoidCallback? onAttendance;
  final VoidCallback? onGrades;

  const ClassroomDetailHeader({
    super.key,
    required this.classroom,
    this.showActions = false,
    this.onAttendance,
    this.onGrades,
  });

  @override
  Widget build(BuildContext context) {
    return DetailHero(
      leading: const DetailHeroIcon(
        icon: PhosphorIconsRegular.chalkboardTeacher,
      ),
      title: classroom.name,
      status: classroomStatusLabel(classroom.status, context.l10n),
      fallbackRoute: '/classrooms',
      chips: [
        if (classroom.branch.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.mapPin,
            label: classroom.branch,
          ),
        if (classroom.level.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.graduationCap,
            label: classroom.level,
          ),
        if (classroom.year.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.calendarBlank,
            label: classroom.year,
          ),
      ],
      bottom: showActions
          ? Row(
              children: [
                Expanded(
                  child: _HeroActionButton(
                    icon: PhosphorIconsRegular.checkSquare,
                    label: context.l10n.professorTakeAttendance,
                    primary: true,
                    onPressed: onAttendance,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroActionButton(
                    icon: PhosphorIconsRegular.notePencil,
                    label: context.l10n.professorLoadGrade,
                    primary: false,
                    onPressed: onGrades,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        primary ? Colors.white : AppColors.overlayStrong;
    final foreground =
        primary ? AppColors.primary : AppColors.onPrimary;

    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withOpacity(0.4),
          disabledForegroundColor: foreground.withOpacity(0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
