import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/l10n.dart';

/// Builds the visible page slots, using `null` for an ellipsis.
///
/// Examples with five numeric slots:
/// `[1, 2, 3, null, 10]`, `[1, null, 4, 5, 6, null, 10]`, `[1, null, 8, 9, 10]`.
List<int?> pageWindow({required int current, required int totalPages}) {
  if (totalPages <= 5) {
    return List<int?>.generate(totalPages, (index) => index + 1);
  }
  if (current <= 3) {
    return [1, 2, 3, null, totalPages];
  }
  if (current >= totalPages - 2) {
    return [1, null, totalPages - 2, totalPages - 1, totalPages];
  }
  return [1, null, current - 1, current, current + 1, null, totalPages];
}

class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int from;
  final int to;
  final int total;
  final bool enabled;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.from,
    required this.to,
    required this.total,
    required this.onPageChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final accent = AppColors.accentFor(isDark);
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.paginationShowing(from, to, total),
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  IconButton(
                    onPressed: enabled && page > 1
                        ? () => onPageChanged(page - 1)
                        : null,
                    icon: const Icon(PhosphorIconsRegular.caretLeft),
                    iconSize: 18,
                    tooltip: l10n.paginationPrevious,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    disabledColor: isDark
                        ? AppColors.darkTextTertiary.withOpacity(0.4)
                        : AppColors.lightTextTertiary.withOpacity(0.4),
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final slot in pageWindow(
                            current: page,
                            totalPages: totalPages,
                          ))
                            if (slot == null)
                              SizedBox(
                                width: 26,
                                child: Center(
                                  child: Text(
                                    '…',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              _PageNumber(
                                number: slot,
                                active: slot == page,
                                enabled: enabled,
                                accent: accent,
                                isDark: isDark,
                                onTap: () => onPageChanged(slot),
                              ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: enabled && page < totalPages
                        ? () => onPageChanged(page + 1)
                        : null,
                    icon: const Icon(PhosphorIconsRegular.caretRight),
                    iconSize: 18,
                    tooltip: l10n.paginationNext,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    disabledColor: isDark
                        ? AppColors.darkTextTertiary.withOpacity(0.4)
                        : AppColors.lightTextTertiary.withOpacity(0.4),
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int number;
  final bool active;
  final bool enabled;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _PageNumber({
    required this.number,
    required this.active,
    required this.enabled,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      selected: active,
      label: l10n.paginationPage(number),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkResponse(
          onTap: enabled ? onTap : null,
          radius: 20,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.labelMedium.copyWith(
                color: active
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
