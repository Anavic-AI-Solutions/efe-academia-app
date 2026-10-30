import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class BadgeCounter extends StatelessWidget {
  final int count;
  final Widget child;

  /// Cuando es `true` muestra el total como píldora numérica (tope `99+`) en
  /// lugar del punto. La lista de chats conserva el punto.
  final bool showCount;

  const BadgeCounter({
    super.key,
    required this.count,
    required this.child,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: showCount ? -6 : -2,
          top: showCount ? -6 : -2,
          child: showCount
              ? Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: const Border.fromBorderSide(
                      BorderSide(color: AppColors.lightSurface, width: 2),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                )
              : Container(
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
