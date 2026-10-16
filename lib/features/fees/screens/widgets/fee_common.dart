import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fee_model.dart';

/// Helpers compartidos de la UI de cuotas de padres (R14): mes, línea de
/// estado y accionable, usados por la card, el detalle, el sheet de subida y
/// el selector de cuota.

/// “Julio 2026”: nombre del mes capitalizado en el idioma de la app (el mes
/// de la API viene numérico); si no parsea, cae al valor crudo.
String feeMonthLabel(FeeModel fee, BuildContext context) {
  final month = int.tryParse(fee.month);
  final year = fee.year;
  if (month == null || month < 1 || month > 12) {
    return '${fee.month} $year'.trim();
  }
  final name = DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag())
      .format(DateTime(int.tryParse(year) ?? 2000, month));
  final capitalized =
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  return '$capitalized $year';
}

/// Verdadero si el comprobante está en revisión, por cualquiera de las dos
/// fuentes que usa la API (`proof_status` o `status`).
bool feeIsUnderReview(FeeModel fee) =>
    fee.proofStatus.toLowerCase() == 'under_review' ||
    fee.status.toLowerCase() == 'under_review';

/// Verdadero si la cuota admite subir/reemplazar comprobante (spec §7.3):
/// pendiente o parcial y fuera de revisión. Una `cancelled` u otro estado
/// desconocido no ofrece acción.
bool feeIsActionable(FeeModel fee) {
  final status = fee.status.toLowerCase();
  return (status == 'pending' || status == 'partial') && !feeIsUnderReview(fee);
}

/// Línea de estado de la cuota (reglas de §7.2 del spec): texto y color ya
/// resueltos. Con `includeAmount: false` el texto es solo el label del estado
/// (para filas que ya muestran el monto aparte), con el mismo color.
({String text, Color color}) feeStatusLine(
  FeeModel fee,
  AppLocalizations l10n,
  bool isDark, {
  bool includeAmount = true,
}) {
  final status = fee.status.toLowerCase();
  final danger = isDark ? AppColors.darkDangerInk : AppColors.dangerInk;
  final muted = AppColors.mutedFor(isDark);
  final amount = AppFormatters.formatCurrency(fee.toPay);
  final partialLine = includeAmount
      ? '${l10n.feesStatusPartial} · '
          '${l10n.feesPartialOwed(AppFormatters.formatCurrency(fee.owe))}'
      : l10n.feesStatusPartial;
  String withAmount(String label) => includeAmount ? '$label · $amount' : label;

  if (status == 'paid') {
    return (text: l10n.feesStatusPaid, color: AppColors.present);
  }
  if (feeIsUnderReview(fee)) {
    return (
      text: withAmount(l10n.feesStatusUnderReview),
      // accentFor: primary en claro, accent en oscuro (contrato de contraste).
      color: AppColors.accentFor(isDark),
    );
  }
  if (fee.isOverdue) {
    return (
      text: status == 'partial'
          ? partialLine
          : withAmount(l10n.feesStatusOverdue),
      color: danger,
    );
  }
  if (status == 'partial') {
    return (text: partialLine, color: muted);
  }
  if (status == 'pending') {
    return (text: withAmount(l10n.feesStatusPending), color: muted);
  }
  return (text: feeStatusLabel(fee.status, l10n), color: muted);
}
