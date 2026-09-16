import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class BadgeCounter extends StatelessWidget {
  final int count;
  final Widget child;

  const BadgeCounter({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.lightSurface, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UnreadDot extends StatelessWidget {
  final bool show;

  const UnreadDot({super.key, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
