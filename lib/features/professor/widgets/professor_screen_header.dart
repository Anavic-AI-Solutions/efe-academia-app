import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import 'professor_gradient_header.dart';

/// Gradient header shared by the professor screens (attendance, grades).
class ProfessorScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? child;

  const ProfessorScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ProfessorGradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6, top: 2, bottom: 2),
                  child: Icon(
                    PhosphorIconsRegular.caretLeft,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}
