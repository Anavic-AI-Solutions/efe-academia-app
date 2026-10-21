import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../domain/fee_model.dart';
import '../providers/fee_provider.dart';
import 'widgets/fee_common.dart';
import 'widgets/parent_fee_proof_sheet.dart';

/// Detalle de una cuota para el padre (`/payments/:id`).
///
/// Card con las filas de la cuota y acciones al pie según el estado: subir
/// comprobante (cuota accionable) o reemplazarlo (en revisión) — al cerrar el
/// sheet con `pop(true)` se refrescan detalle y lista — y ver la factura en el
/// visor in-app (`/payments/:id/invoice`, solo pagada).
class ParentFeeDetailScreen extends ConsumerStatefulWidget {
  final String feeId;

  /// Navegación inyectable para tests; por defecto empuja el visor de factura.
  final VoidCallback? onViewInvoice;

  const ParentFeeDetailScreen({
    super.key,
    required this.feeId,
    this.onViewInvoice,
  });

  @override
  ConsumerState<ParentFeeDetailScreen> createState() =>
      _ParentFeeDetailScreenState();
}

class _ParentFeeDetailScreenState extends ConsumerState<ParentFeeDetailScreen> {
  /// Abre el sheet de subida/reemplazo y, si termina en éxito (`pop(true)`),
  /// muestra el snackbar e invalida el detalle y la lista de cuotas.
  Future<void> _openProofSheet(FeeModel fee) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentFeeProofSheet(fee: fee),
    );
    if (result != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.feesProofSuccess)),
    );
    ref.invalidate(feeDetailProvider(widget.feeId));
    ref.invalidate(parentFeesProvider);
  }

  /// Abre el visor in-app de la factura; la descarga y el 404 los maneja la
  /// pantalla del visor (`InvoiceViewerScreen`).
  void _openInvoice() {
    final onViewInvoice = widget.onViewInvoice;
    if (onViewInvoice != null) {
      onViewInvoice();
      return;
    }

    context.push('/payments/${widget.feeId}/invoice');
  }

  @override
  Widget build(BuildContext context) {
    final feeAsync = ref.watch(feeDetailProvider(widget.feeId));
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: feeAsync.maybeWhen(
              data: (fee) => l10n.feesDetailTitle(fee.numberFee),
              orElse: () => l10n.feesDetailFallbackTitle,
            ),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody(feeAsync, l10n, isDark)),
          feeAsync.when(
            data: (fee) => _buildActions(fee, l10n),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      AsyncValue<FeeModel> feeAsync, AppLocalizations l10n, bool isDark) {
    return feeAsync.when(
      loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
      error: (error, _) => ErrorView(
        message: l10n.feesDetailLoadError,
        detail: error.toString(),
        onRetry: () => ref.invalidate(feeDetailProvider(widget.feeId)),
      ),
      data: (fee) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: _buildCard(fee, l10n, isDark),
      ),
    );
  }

  /// Card con las filas de la cuota: hijo, mes/año, estado (badge), montos,
  /// debe (si `owe > 0`), comprobante (si en revisión) y método/fecha
  /// (solo pagada).
  Widget _buildCard(FeeModel fee, AppLocalizations l10n, bool isDark) {
    final line = feeStatusLine(fee, l10n, isDark, includeAmount: false);
    final isPaid = fee.status.toLowerCase() == 'paid';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: l10n.roleStudent, value: fee.studentName),
          _DetailRow(
            label: l10n.feesDetailMonth,
            value: feeMonthLabel(fee, context),
          ),
          _DetailRow(
            label: l10n.feesDetailStatus,
            valueWidget: StatusBadge(
              status: fee.status,
              label: line.text,
              color: line.color,
            ),
          ),
          const Divider(height: 16),
          _DetailRow(
            label: l10n.feesDetailToPay,
            value: AppFormatters.formatCurrency(fee.toPay),
          ),
          _DetailRow(
            label: l10n.feesDetailPaid,
            value: AppFormatters.formatCurrency(fee.paid),
          ),
          _DetailRow(
            label: l10n.feesDetailTotal,
            value: AppFormatters.formatCurrency(fee.total),
          ),
          if (fee.owe > 0)
            _highlight(
              l10n.feesPartialOwed(AppFormatters.formatCurrency(fee.owe)),
              line.color,
            ),
          if (feeIsUnderReview(fee)) _reviewRow(l10n, isDark),
          if (isPaid) ...[
            const Divider(height: 16),
            _DetailRow(
              label: l10n.feesDetailPaymentMethod,
              value: fee.paymentMethod,
            ),
            _DetailRow(
              label: l10n.feesDetailPaymentDate,
              value: fee.paymentDate,
            ),
          ],
        ],
      ),
    );
  }

  /// Línea destacada de texto (p. ej. “debe 12.500,00 $”).
  Widget _highlight(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  /// Fila “Comprobante en revisión” (mientras administración lo evalúa).
  /// Usa `accentFor` para cumplir el contraste en dark (R15).
  Widget _reviewRow(AppLocalizations l10n, bool isDark) {
    final color = AppColors.accentFor(isDark);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            l10n.feesProofStatusReview,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Acciones al pie: ver factura (pagada), subir comprobante (accionable:
  /// pendiente/parcial fuera de revisión) o reemplazarlo (en revisión). Una
  /// `cancelled` u otro estado desconocido no ofrece acción.
  Widget _buildActions(FeeModel fee, AppLocalizations l10n) {
    final isPaid = fee.status.toLowerCase() == 'paid';

    if (isPaid) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: PillButton(
          label: l10n.feesInvoiceAction,
          onPressed: _openInvoice,
        ),
      );
    }

    if (!feeIsActionable(fee) && !feeIsUnderReview(fee)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: PillButton(
        label: feeIsUnderReview(fee)
            ? l10n.feesReplaceProofAction
            : l10n.feesUploadProofAction,
        onPressed: () => _openProofSheet(fee),
      ),
    );
  }
}

/// Fila etiqueta (izquierda, muted) y valor (derecha, bold) o widget propio.
class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueWidget = this.valueWidget;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedFor(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (valueWidget != null)
            valueWidget
          else
            Flexible(
              child: Text(
                (value ?? '').isNotEmpty ? value! : '-',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFor(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
