import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../../requests/domain/request_model.dart';
import '../../../requests/providers/request_provider.dart';
import '../../../requests/screens/widgets/request_media_section.dart';
import '../../domain/student_model.dart';

class StudentRequestTab extends ConsumerWidget {
  final StudentModel student;

  const StudentRequestTab({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requestAsync = ref.watch(
      requestDetailProvider((kind: RequestKind.student, id: student.id)),
    );

    return requestAsync.when(
      loading: () => const ListShimmer(itemCount: 4, itemHeight: 70),
      error: (error, _) => Center(
        child: ErrorView(
          message: l10n.studentsRequestLoadError,
          detail: error.toString(),
          onRetry: () => ref.invalidate(
            requestDetailProvider((kind: RequestKind.student, id: student.id)),
          ),
        ),
      ),
      data: (request) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final rows = <Widget>[
          InfoRow(label: l10n.studentsInfoFullName, value: request.fullname),
          InfoRow(label: l10n.studentsInfoEmail, value: request.email),
          InfoRow(
            label: l10n.studentsInfoIdentityNumber,
            value: request.identityNumber,
          ),
          InfoRow(label: l10n.studentsInfoBranch, value: request.branch),
          InfoRow(label: l10n.studentsInfoYear, value: request.year),
          if (request.createdAt != null)
            InfoRow(
              label: l10n.studentsRequestCreatedAt,
              value: DateFormat('d/M/y').format(request.createdAt!),
            ),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.studentsTabRequest,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                if (request.status.isNotEmpty)
                  StatusBadge(
                    status: request.status,
                    label: studentStatusLabel(request.status, l10n),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: l10n.studentsSectionPersonal,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var index = 0; index < rows.length; index++)
                    KeyedSubtree(
                      key: ValueKey('student-request-info-$index'),
                      child: rows[index],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RequestMediaSection(media: request.media),
          ],
        );
      },
    );
  }
}
