import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../classrooms/domain/classroom_model.dart';
import '../../providers/student_provider.dart';

/// Aulas del alumno dentro de la ficha: nombre + chevron que abre
/// `/classrooms/{id}`. Sin aulas la sección queda oculta.
class StudentClassroomsSection extends ConsumerWidget {
  final String studentId;

  const StudentClassroomsSection({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final classrooms = ref.watch(studentClassroomsProvider(studentId));

    return classrooms.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.classroomsTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 11),
          const LoadingShimmer(
            width: double.infinity,
            height: 56,
            borderRadius: 16,
          ),
          const SizedBox(height: 10),
          const LoadingShimmer(
            width: double.infinity,
            height: 56,
            borderRadius: 16,
          ),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.classroomsTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 11),
          ErrorView(
            message: l10n.classroomsLoadError,
            detail: error.toString(),
            onRetry: () => ref.invalidate(studentClassroomsProvider(studentId)),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.classroomsTitle,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 11),
            for (final classroom in items)
              _StudentClassroomCard(classroom: classroom),
          ],
        );
      },
    );
  }
}

class _StudentClassroomCard extends StatelessWidget {
  final ClassroomModel classroom;

  const _StudentClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push('/classrooms/${classroom.id}'),
      child: Row(
        children: [
          Expanded(
            child: Text(
              classroom.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.inkFor(isDark),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
