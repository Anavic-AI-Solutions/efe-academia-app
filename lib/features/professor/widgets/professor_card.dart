import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/professor_colors.dart';

/// White rounded card shared by the professor screens.
class ProfessorCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ProfessorCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.padding = const EdgeInsets.all(13),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? ProfessorColors.primarySoft : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? ProfessorColors.primarySoft.withOpacity(0.35)
                : const Color(0x59232D3C).withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -14,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
