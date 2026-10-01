import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../providers/fee_provider.dart';

class FeeDetailScreen extends ConsumerWidget {
  final String feeId;

  const FeeDetailScreen({super.key, required this.feeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(feeDetailProvider(feeId));
    final l10n = context.l10n;

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: feeAsync.when(
              data: (f) => l10n.feesDetailTitle(f.numberFee),
              loading: () => l10n.feesDetailFallbackTitle,
              error: (_, __) => l10n.feesDetailFallbackTitle,
            ),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: feeAsync.when(
              loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
              error: (e, _) => ErrorView(
                message: l10n.feesDetailLoadError,
                detail: e.toString(),
                onRetry: () => ref.invalidate(feeDetailProvider(feeId)),
              ),
              data: (fee) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoRow(label: l10n.roleStudent, value: fee.studentName),
                  _InfoRow(
                    label: l10n.feesDetailFeeNumber,
                    value: fee.numberFee.toString(),
                  ),
                  _InfoRow(label: l10n.feesDetailMonth, value: fee.month),
                  _InfoRow(label: l10n.feesDetailYear, value: fee.year),
                  const Divider(height: 32),
                  _InfoRow(
                    label: l10n.feesDetailToPay,
                    value: AppFormatters.formatCurrency(fee.toPay),
                  ),
                  _InfoRow(
                    label: l10n.feesDetailPaid,
                    value: AppFormatters.formatCurrency(fee.paid),
                  ),
                  _InfoRow(
                    label: l10n.feesDetailTotal,
                    value: AppFormatters.formatCurrency(fee.total),
                  ),
                  const Divider(height: 32),
                  _InfoRow(label: l10n.feesDetailStatus, value: fee.status),
                  _InfoRow(
                    label: l10n.feesDetailPaymentMethod,
                    value: fee.paymentMethod,
                  ),
                  _InfoRow(
                    label: l10n.feesDetailPaymentDate,
                    value: fee.paymentDate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedFor(isDark),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '-',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkFor(isDark),
                ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
