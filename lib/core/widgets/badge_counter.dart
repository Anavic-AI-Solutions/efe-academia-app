import 'package:flutter/material.dart';

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
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
