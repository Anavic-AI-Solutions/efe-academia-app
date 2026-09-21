import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../providers/classroom_provider.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: classroomAsync.when(
          data: (c) => Text(c.name),
          loading: () => Text(l10n.classroomsDetailTitle),
          error: (_, __) => Text(l10n.classroomsDetailTitle),
        ),
      ),
      body: classroomAsync.when(
        loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
        error: (e, _) => ErrorView(
          message: l10n.classroomsDetailLoadError,
          detail: e.toString(),
          onRetry: () => ref.invalidate(classroomDetailProvider(classroomId)),
        ),
        data: (classroom) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoRow(label: l10n.classroomsName, value: classroom.name),
            _InfoRow(
              label: l10n.classroomsDescription,
              value: classroom.description,
            ),
            _InfoRow(label: l10n.classroomsStatus, value: classroom.status),
            _InfoRow(label: l10n.classroomsShift, value: classroom.shift),
            _InfoRow(label: l10n.classroomsDay, value: classroom.day),
            _InfoRow(label: l10n.classroomsHour, value: classroom.hour),
            _InfoRow(label: l10n.classroomsRoom, value: classroom.room),
            _InfoRow(label: l10n.classroomsYear, value: classroom.year),
            _InfoRow(label: l10n.classroomsBranch, value: classroom.branch),
            _InfoRow(
              label: l10n.classroomsStudents,
              value: classroom.studentCount.toString(),
            ),
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
