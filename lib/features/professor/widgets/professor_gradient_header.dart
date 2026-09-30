import 'package:flutter/material.dart';

import '../../../app/theme/professor_colors.dart';

/// Gradient container shared by the professor screens.
class ProfessorGradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ProfessorGradientHeader({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ProfessorColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: padding ??
          EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            16,
            16,
          ),
      child: child,
    );
  }
}
