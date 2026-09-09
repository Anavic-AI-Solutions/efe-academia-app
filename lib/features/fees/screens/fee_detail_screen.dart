import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/fee_provider.dart';

class FeeDetailScreen extends ConsumerWidget {
  final String feeId;

  const FeeDetailScreen({super.key, required this.feeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeAsync = ref.watch(feeDetailProvider(feeId));

    return Scaffold(
      appBar: AppBar(
        title: feeAsync.when(
          data: (f) => Text('Fee #${f.numberFee}'),
          loading: () => const Text('Fee'),
          error: (_, __) => const Text('Fee'),
        ),
      ),
      body: feeAsync.when(
        loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
        error: (e, _) => ErrorView(
          message: 'Failed to load fee',
          detail: e.toString(),
          onRetry: () => ref.invalidate(feeDetailProvider(feeId)),
        ),
        data: (fee) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoRow(label: 'Student', value: fee.studentName),
            _InfoRow(label: 'Fee Number', value: fee.numberFee.toString()),
            _InfoRow(label: 'Month', value: fee.month),
            _InfoRow(label: 'Year', value: fee.year),
            const Divider(height: 32),
            _InfoRow(
              label: 'To Pay',
              value: AppFormatters.formatCurrency(fee.toPay),
            ),
            _InfoRow(
              label: 'Paid',
              value: AppFormatters.formatCurrency(fee.paid),
            ),
            _InfoRow(
              label: 'Total',
              value: AppFormatters.formatCurrency(fee.total),
            ),
            const Divider(height: 32),
            _InfoRow(label: 'Status', value: fee.status),
            _InfoRow(label: 'Payment Method', value: fee.paymentMethod),
            _InfoRow(label: 'Payment Date', value: fee.paymentDate),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '-',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
