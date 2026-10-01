import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/paged_tab_list.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../fees/domain/fee_model.dart';
import '../../../qualifications/domain/qualification_model.dart';
import '../../domain/absence_model.dart';
import '../../providers/student_grades_provider.dart';
import '../../providers/student_provider.dart';
import 'absence_tile.dart';
import 'fee_tile.dart';
import 'student_grades_grid.dart';

class StudentGradesTab extends ConsumerWidget {
  final String studentId;
  final String? classroomId;
  final bool isProfessor;

  const StudentGradesTab({
    super.key,
    required this.studentId,
    this.classroomId,
    this.isProfessor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accent = isProfessor ? AppColors.primarySoft : null;
    final gradesAsync = ref.watch(studentGradesProvider(studentId));

    return gradesAsync.when(
      loading: () => const ListShimmer(itemCount: 3, itemHeight: 120),
      error: (error, _) => ErrorView(
        message: l10n.studentsRelatedLoadError,
        detail: error.toString(),
        accentColor: accent,
        onRetry: () => ref.invalidate(studentGradesProvider(studentId)),
      ),
      data: (qualifications) {
        final sections = _buildSections(l10n, qualifications);
        if (sections.isEmpty) {
          return EmptyState(
            icon: Icons.grade_outlined,
            title: l10n.studentsNoGrades,
            accentColor: accent,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) => StudentGradesGrid(
            qualifications: sections[index].qualifications,
            classroomName: sections[index].name,
            isProfessor: isProfessor,
          ),
        );
      },
    );
  }

  List<_GradesSection> _buildSections(
    AppLocalizations l10n,
    List<QualificationModel> qualifications,
  ) {
    if (classroomId != null) {
      final filtered = qualifications
          .where((qualification) => qualification.classroomId == classroomId)
          .toList();
      if (filtered.isEmpty) return const [];
      return [
        _GradesSection(
          name: _classroomName(l10n, filtered),
          qualifications: filtered,
        ),
      ];
    }

    final groups = <String, List<QualificationModel>>{};
    for (final qualification in qualifications) {
      groups.putIfAbsent(qualification.classroomId, () => []).add(qualification);
    }

    return groups.values
        .map(
          (items) => _GradesSection(
            name: _classroomName(l10n, items),
            qualifications: items,
          ),
        )
        .toList();
  }

  String _classroomName(
    AppLocalizations l10n,
    List<QualificationModel> qualifications,
  ) {
    for (final qualification in qualifications) {
      if (qualification.classroomName.isNotEmpty) {
        return qualification.classroomName;
      }
    }
    return l10n.gradesGridClassroomFallback;
  }
}

class _GradesSection {
  final String name;
  final List<QualificationModel> qualifications;

  const _GradesSection({required this.name, required this.qualifications});
}

class StudentAbsencesTab extends ConsumerWidget {
  final String studentId;
  final bool isProfessor;

  const StudentAbsencesTab({
    super.key,
    required this.studentId,
    this.isProfessor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = studentAbsencesProvider(studentId);
    final state = ref.watch(provider);

    return PagedTabList<AbsenceModel>(
      state: state,
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: l10n.studentsNoAbsences,
      errorMessage: l10n.studentsRelatedLoadError,
      accentColor: isProfessor ? AppColors.primarySoft : null,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, absence) => AbsenceTile(absence: absence),
    );
  }
}

class StudentFeesTab extends ConsumerWidget {
  final String studentId;
  final bool isProfessor;

  const StudentFeesTab({
    super.key,
    required this.studentId,
    this.isProfessor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = studentFeesProvider(studentId);
    final state = ref.watch(provider);

    return PagedTabList<FeeModel>(
      state: state,
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitle: l10n.studentsNoFees,
      errorMessage: l10n.studentsRelatedLoadError,
      accentColor: isProfessor ? AppColors.primarySoft : null,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, fee) => FeeTile(fee: fee),
    );
  }
}
