import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/classroom_provider.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: classroomAsync.when(
          data: (c) => Text(c.name),
          loading: () => const Text('Classroom'),
          error: (_, __) => const Text('Classroom'),
        ),
      ),
      body: classroomAsync.when(
        loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
        error: (e, _) => ErrorView(
          message: 'Failed to load classroom',
          detail: e.toString(),
          onRetry: () => ref.invalidate(classroomDetailProvider(classroomId)),
        ),
        data: (classroom) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoRow(label: 'Name', value: classroom.name),
            _InfoRow(label: 'Description', value: classroom.description),
            _InfoRow(label: 'Status', value: classroom.status),
            _InfoRow(label: 'Shift', value: classroom.shift),
            _InfoRow(label: 'Day', value: classroom.day),
            _InfoRow(label: 'Hour', value: classroom.hour),
            _InfoRow(label: 'Room', value: classroom.room),
            _InfoRow(label: 'Year', value: classroom.year),
            _InfoRow(label: 'Branch', value: classroom.branch),
            _InfoRow(
              label: 'Students',
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
