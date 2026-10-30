import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/fee_model.dart';
import 'fee_common.dart';

/// Tarjeta de cuota de la pantalla Pagos de padres.
///
/// Muestra mes/año, la línea de estado (reglas de §7.2 del spec), el nombre
/// del hijo y la acción según el estado: pill Pagar (vencida, pendiente o
/// parcial), check de pagada o nada (comprobante en revisión).
class ParentFeeCard extends StatelessWidget {
  final FeeModel fee;
  final String childName;
  final VoidCallback onTap;
  final VoidCallback? onPay;

  const ParentFeeCard({
    super.key,
    required this.fee,
    required this.childName,
    required this.onTap,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = feeStatusLine(fee, l10n, isDark);
    final action = _action(l10n, isDark);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeMonthLabel(fee, context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.text,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: line.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action,
          ],
        ],
      ),
    );
  }

  Widget? _action(AppLocalizations l10n, bool isDark) {
    final status = fee.status.toLowerCase();
    final pay = onPay;

    if (status == 'paid') {
      return const Icon(
        Icons.check,
        size: 14,
        weight: 800,
        color: AppColors.present,
      );
    }
    if (feeIsUnderReview(fee) || status == 'cancelled' || pay == null) {
      return null;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDangerInk : AppColors.dangerInk,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: pay,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              l10n.parentPayAction,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkDangerSoft : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
