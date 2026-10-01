import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Single stat tile datum for [HeaderStatsRow].
class HeaderStat {
  final String value;
  final String label;
  final bool highlighted;

  const HeaderStat({
    required this.value,
    required this.label,
    this.highlighted = false,
  });
}

/// Row of expanded stat tiles over a gradient header.
class HeaderStatsRow extends StatelessWidget {
  final List<HeaderStat> stats;

  const HeaderStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _StatTile(stat: stats[i]),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final HeaderStat stat;

  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: stat.highlighted
            ? AppColors.overlayStrong
            : AppColors.overlay,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimary,
            ),
          ),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}
