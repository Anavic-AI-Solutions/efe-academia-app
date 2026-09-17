import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'classroom_filter_sheet.dart';

class ClassroomFilterChips extends StatelessWidget {
  final ClassroomFilterSelection selection;
  final ValueChanged<ClassroomFilterSelection> onChanged;
  final VoidCallback onClearAll;

  const ClassroomFilterChips({
    super.key,
    required this.selection,
    required this.onChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (selection.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (selection.branch != null)
            _ActiveFilterChip(
              label: 'Branch: ${selection.branch}',
              onRemove: () => onChanged(selection.copyWith(clearBranch: true)),
            ),
          if (selection.level != null)
            _ActiveFilterChip(
              label: 'Level: ${selection.level}',
              onRemove: () => onChanged(selection.copyWith(clearLevel: true)),
            ),
          if (selection.year != null)
            _ActiveFilterChip(
              label: 'Year: ${selection.year}',
              onRemove: () => onChanged(selection.copyWith(clearYear: true)),
            ),
          if (selection.status != null)
            _ActiveFilterChip(
              label: 'Status: ${classroomStatusLabel(selection.status!)}',
              onRemove: () => onChanged(selection.copyWith(clearStatus: true)),
            ),
          Center(
            child: GestureDetector(
              onTap: onClearAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Clear',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? const Color(0xFF6366F1) : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF6366F1) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 7, 5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(color: accent),
                ),
                const SizedBox(width: 5),
                Icon(PhosphorIconsRegular.x, size: 12, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
