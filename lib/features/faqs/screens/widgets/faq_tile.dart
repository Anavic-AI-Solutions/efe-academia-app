import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/faq_model.dart';

class FaqTile extends StatefulWidget {
  final FaqModel faq;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FaqTile({
    super.key,
    required this.faq,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = AppColors.accentFor(isDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: AppTypography.titleSmall.copyWith(color: primary),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.onEdit != null || widget.onDelete != null)
                  PopupMenuButton<String>(
                    key: Key('faq-menu-${widget.faq.id}'),
                    padding: EdgeInsets.zero,
                    tooltip: '',
                    icon: Icon(
                      PhosphorIconsRegular.dotsThreeVertical,
                      size: 20,
                      color: AppColors.mutedFor(isDark),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit?.call();
                      } else {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(context.l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.commonDelete),
                      ),
                    ],
                  ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    PhosphorIconsRegular.caretDown,
                    size: 18,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.faq.answer,
                style: AppTypography.bodySmall.copyWith(
                  color: secondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
