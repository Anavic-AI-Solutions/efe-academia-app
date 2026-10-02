import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class ClassroomFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  final Color? accentColor;

  const ClassroomFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeCount > 0;
    final accent = accentColor ?? AppColors.accentFor(isDark);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? accent
                  : (isDark
                      ? AppColors.darkSearchFill
                      : AppColors.lightSearchFill),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.faders,
              size: 20,
              color: active
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
          if (active)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
