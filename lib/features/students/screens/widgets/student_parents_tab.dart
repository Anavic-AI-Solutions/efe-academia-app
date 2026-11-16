import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../../requests/screens/widgets/request_media_section.dart';
import '../../domain/student_model.dart';
import '../../domain/student_parent_model.dart';
import '../../providers/student_provider.dart';

class StudentParentsTab extends ConsumerWidget {
  final StudentModel student;

  const StudentParentsTab({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final parentsAsync = ref.watch(studentParentsProvider(student.id));

    return parentsAsync.when(
      loading: () => const ListShimmer(itemCount: 3, itemHeight: 140),
      error: (error, _) => Center(
        child: ErrorView(
          message: l10n.studentsParentsLoadError,
          detail: error.toString(),
          onRetry: () => ref.invalidate(studentParentsProvider(student.id)),
        ),
      ),
      data: (parents) {
        if (parents.isEmpty) {
          return Center(
            child: EmptyState(
              icon: PhosphorIconsRegular.users,
              title: l10n.studentsParentsEmpty,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SectionHeader(
              title: l10n.studentsTabParents,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            for (final parent in parents) ...[
              _ParentCard(parent: parent),
              const SizedBox(height: 12),
              if (parent.media.isNotEmpty) ...[
                RequestMediaSection(media: parent.media),
                const SizedBox(height: 16),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _ParentCard extends StatelessWidget {
  final StudentParentModel parent;

  const _ParentCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rows = <Widget>[
      InfoRow(label: l10n.studentsInfoEmail, value: parent.email),
      InfoRow(label: l10n.requestsPhone, value: parent.phone),
      InfoRow(label: l10n.requestsAddress, value: parent.address),
      InfoRow(
        label: l10n.studentsInfoIdentityNumber,
        value: parent.identityNumber,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: parent.fullname, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  parent.fullname.isNotEmpty
                      ? parent.fullname
                      : l10n.studentsTabParents,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (parent.status.isNotEmpty)
                StatusBadge(
                  status: parent.status,
                  label: studentStatusLabel(parent.status, l10n),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < rows.length; index++)
            KeyedSubtree(
              key: ValueKey('student-parent-info-$index'),
              child: rows[index],
            ),
        ],
      ),
    );
  }
}
