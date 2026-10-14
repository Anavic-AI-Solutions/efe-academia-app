import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/l10n.dart';

/// Alerta de mora del home de padres.
///
/// No decide su visibilidad: la pantalla que la consume la muestra solo
/// cuando [count] es mayor a cero.
class ParentOverdueFeesCard extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onPay;

  const ParentOverdueFeesCard({
    super.key,
    required this.count,
    required this.total,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('parent-mora-card'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDangerSoft : AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.absent.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.parentOverdueFeesCount(count),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? AppColors.darkDangerInk : AppColors.dangerInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.parentMoraTotal} ${AppFormatters.formatCurrency(total)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkDangerInkMuted
                        : AppColors.dangerInkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDangerInk : AppColors.dangerInk,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: onPay,
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    l10n.parentPayAction,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkDangerSoft : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
