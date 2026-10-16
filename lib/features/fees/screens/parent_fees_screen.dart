import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../domain/fee_model.dart';
import '../providers/fee_provider.dart';
import 'widgets/fee_common.dart';
import 'widgets/parent_fee_card.dart';
import 'widgets/parent_fee_proof_sheet.dart';

/// Pantalla Pagos de padres: mora total, todas las cuotas de la familia
/// (ordenadas por el backend) y CTA global para subir comprobantes.
class ParentFeesScreen extends ConsumerStatefulWidget {
  const ParentFeesScreen({super.key});

  @override
  ConsumerState<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends ConsumerState<ParentFeesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(parentFeesProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(parentFeesProvider.notifier).refresh(),
      ref.read(dashboardProvider.notifier).refresh(),
    ]);
  }

  /// Abre el sheet de subida y, si termina en éxito (`pop(true)`), muestra el
  /// snackbar y recarga la lista.
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
    await ref.read(parentFeesProvider.notifier).refresh();
  }

  /// CTA con 2+ accionables: elige la cuota y abre su sheet de subida.
  Future<void> _openFeePicker(List<FeeModel> accionables) async {
    final selected = await showModalBottomSheet<FeeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeePickerSheet(fees: accionables),
    );
    if (selected == null || !mounted) return;
    await _openProofSheet(selected);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentFeesProvider);
    final moraTotal = ref.watch(dashboardProvider).data?.parentHome?.moraTotal;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accionables = state.pagination.data
        .where((fee) =>
            (fee.status == 'pending' || fee.status == 'partial') &&
            !feeIsUnderReview(fee))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          _buildHeader(moraTotal),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(state, l10n),
            ),
          ),
          if (accionables.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: PillButton(
                label: l10n.feesUploadProofAction,
                onPressed: () {
                  if (accionables.length == 1) {
                    _openProofSheet(accionables.first);
                  } else {
                    _openFeePicker(accionables);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Header gradiente: título “Cuotas” y tile de mora (oculto si 0 o sin dato).
  Widget _buildHeader(double? moraTotal) {
    final l10n = context.l10n;

    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feesTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
          if (moraTotal != null && moraTotal > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.parentMoraTotal,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onPrimaryMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(moraTotal),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(FeeListState state, AppLocalizations l10n) {
    final fees = state.pagination.data;

    if (state.isLoading && fees.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: LoadingShimmer(width: double.infinity, height: 68),
            ),
        ],
      );
    }

    if (state.error != null && fees.isEmpty) {
      return _scrollableState(
        ErrorView(
          message: l10n.feesLoadError,
          detail: state.error,
          onRetry: () => ref.read(parentFeesProvider.notifier).refresh(),
        ),
      );
    }

    if (fees.isEmpty) {
      return _scrollableState(
        EmptyState(
          icon: Icons.receipt_long_outlined,
          title: l10n.feesEmptyTitle,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: ParentFeeCard(
            fee: fee,
            childName: fee.studentName,
            onTap: () => context.push('/payments/${fee.id}'),
            onPay: () => context.push('/payments/${fee.id}'),
          ),
        );
      },
    );
  }

  /// Centra vacío/error dentro del viewport sin perder el scroll (para que
  /// siga funcionando el pull-to-refresh).
  Widget _scrollableState(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// Selector de cuota del CTA global (2+ accionables): una fila por cuota con
/// hijo · mes/año · monto/estado; al elegir devuelve la cuota con `pop(fee)`.
class _FeePickerSheet extends StatelessWidget {
  final List<FeeModel> fees;

  const _FeePickerSheet({required this.fees});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightInk;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.navInactive.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.feesChooseFeeTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            for (final fee in fees) _row(context, fee, l10n, isDark),
          ],
        ),
      ),
    );
  }

  /// Fila hijo · mes/año · monto/línea de estado de una cuota accionable.
  Widget _row(
    BuildContext context,
    FeeModel fee,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightInk;
    // La fila ya muestra el monto aparte: la línea de estado va sin monto.
    final line = feeStatusLine(fee, l10n, isDark, includeAmount: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        onTap: () => Navigator.of(context).pop(fee),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fee.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feeMonthLabel(fee, context),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatCurrency(fee.toPay),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textColor,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
