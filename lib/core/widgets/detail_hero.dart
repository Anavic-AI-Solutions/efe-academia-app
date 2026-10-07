import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'status_badge.dart';

class DetailHeroChip {
  final IconData icon;
  final String label;

  const DetailHeroChip({required this.icon, required this.label});
}

class DetailHero extends StatelessWidget {
  final Widget leading;
  final String title;
  final String status;
  final String? statusLabel;
  final List<DetailHeroChip> chips;
  final String fallbackRoute;
  final Gradient? gradient;
  final Widget? bottom;

  const DetailHero({
    super.key,
    required this.leading,
    required this.title,
    this.status = '',
    this.statusLabel,
    this.chips = const [],
    this.fallbackRoute = '/dashboard',
    this.gradient,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: gradient ??
            (isDark
                ? AppColors.primaryGradientDark
                : AppColors.primaryGradient),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go(fallbackRoute);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                iconSize: 20,
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (status.isNotEmpty || chips.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (status.isNotEmpty)
                                  _StatusPill(
                                    status: status,
                                    label: statusLabel ?? status,
                                  ),
                                for (final chip in chips)
                                  _MetaChip(icon: chip.icon, label: chip.label),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 14),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailHeroIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const DetailHeroIcon({super.key, required this.icon, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: size / 2),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = StatusBadge.colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
