import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/fee_model.dart';

/// Línea de estado de la cuota: texto y color ya resueltos.
class _FeeLine {
  final String text;
  final Color color;

  const _FeeLine(this.text, this.color);
}

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

  /// Verdadero si el comprobante está en revisión, por cualquiera de las dos
  /// fuentes que usa la API (`proof_status` o `status`).
  bool get _isUnderReview =>
      fee.proofStatus.toLowerCase() == 'under_review' ||
      fee.status.toLowerCase() == 'under_review';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = _stateLine(l10n, isDark);
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
                  _monthLabel(context),
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

  /// Título “Julio 2026”: nombre del mes capitalizado en el idioma de la app
  /// (el mes de la API viene numérico); si no parsea, cae al valor crudo.
  String _monthLabel(BuildContext context) {
    final month = int.tryParse(fee.month);
    final year = fee.year;
    if (month == null || month < 1 || month > 12) {
      return '${fee.month} $year'.trim();
    }
    final name =
        DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag())
            .format(DateTime(int.tryParse(year) ?? 2000, month));
    final capitalized =
        name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
    return '$capitalized $year';
  }

  _FeeLine _stateLine(AppLocalizations l10n, bool isDark) {
    final status = fee.status.toLowerCase();
    final danger = isDark ? AppColors.darkDangerInk : AppColors.dangerInk;
    final muted = AppColors.mutedFor(isDark);
    final amount = AppFormatters.formatCurrency(fee.toPay);
    final partialLine = '${l10n.feesStatusPartial} · '
        '${l10n.feesPartialOwed(AppFormatters.formatCurrency(fee.owe))}';

    if (status == 'paid') {
      return _FeeLine(l10n.feesStatusPaid, AppColors.present);
    }
    if (_isUnderReview) {
      return _FeeLine(
          '${l10n.feesStatusUnderReview} · $amount', AppColors.primary);
    }
    if (fee.isOverdue) {
      return _FeeLine(
        status == 'partial'
            ? partialLine
            : '${l10n.feesStatusOverdue} · $amount',
        danger,
      );
    }
    if (status == 'partial') {
      return _FeeLine(partialLine, muted);
    }
    if (status == 'pending') {
      return _FeeLine('${l10n.feesStatusPending} · $amount', muted);
    }
    return _FeeLine(feeStatusLabel(fee.status, l10n), muted);
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
    if (_isUnderReview || status == 'cancelled' || pay == null) {
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
