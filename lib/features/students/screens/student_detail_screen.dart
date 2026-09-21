import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../providers/student_provider.dart';
import '../domain/student_model.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: studentAsync.when(
          data: (s) => Text(s.fullname),
          loading: () => Text(l10n.studentsDetailFallbackTitle),
          error: (_, __) => Text(l10n.studentsDetailFallbackTitle),
        ),
      ),
      body: studentAsync.when(
        loading: () => const ListShimmer(itemCount: 5, itemHeight: 60),
        error: (e, _) => ErrorView(
          message: l10n.studentsDetailLoadError,
          detail: e.toString(),
          onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
        ),
        data: (student) => DefaultTabController(
          length: 4,
          child: Column(
            children: [
              _StudentHeader(student: student),
              TabBar(
                tabs: [
                  Tab(text: l10n.studentsTabGrades),
                  Tab(text: l10n.studentsTabAbsences),
                  Tab(text: l10n.studentsTabFees),
                  Tab(text: l10n.studentsTabInfo),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPlaceholder(l10n.studentsNoGrades),
                    _buildPlaceholder(l10n.studentsNoAbsences),
                    _buildPlaceholder(l10n.studentsNoFees),
                    _InfoTab(student: student),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  final StudentModel student;

  const _StudentHeader({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: student.avatarUrl,
            name: student.fullname,
            size: 64,
            showBorder: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullname,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                if (student.classroomNames.isNotEmpty)
                  Text(
                    student.classroomNames.join(', '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                const SizedBox(height: 4),
                _StatusBadge(status: student.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase() == 'active'
        ? AppColors.success
        : status.toLowerCase() == 'inactive'
            ? AppColors.error
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final StudentModel student;

  const _InfoTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: l10n.studentsInfoFullName, value: student.fullname),
        _InfoRow(label: l10n.studentsInfoEmail, value: student.email),
        _InfoRow(label: l10n.studentsInfoYear, value: student.year),
        _InfoRow(
          label: l10n.studentsInfoIdentityNumber,
          value: student.identityNumber,
        ),
        _InfoRow(label: l10n.studentsInfoBranch, value: student.branch),
        _InfoRow(
          label: l10n.studentsInfoClassrooms,
          value: student.classroomNames.isNotEmpty
              ? student.classroomNames.join(', ')
              : '-',
        ),
      ],
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
