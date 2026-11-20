import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/paged_tab_list.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../dashboard/domain/professor_classroom_summary.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../fees/domain/fee_model.dart';
import '../../../qualifications/domain/classroom_grades_summary.dart';
import '../../../qualifications/domain/qualification_model.dart';
import '../../../qualifications/domain/qualification_options.dart';
import '../../../qualifications/screens/widgets/qualification_form_sheet.dart';
import '../../domain/absence_model.dart';
import '../../providers/student_grades_provider.dart';
import '../../providers/student_provider.dart';
import 'absence_tile.dart';
import 'fee_tile.dart';
import 'mark_absence_sheet.dart';
import 'student_grades_grid.dart';

class StudentGradesTab extends ConsumerWidget {
  final String studentId;
  final String? classroomId;
  final bool canWrite;
  final String studentFullname;

  const StudentGradesTab({
    super.key,
    required this.studentId,
    this.classroomId,
    this.canWrite = false,
    this.studentFullname = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gradesAsync = ref.watch(studentGradesProvider(studentId));

    final Widget content = gradesAsync.when(
      loading: () => const ListShimmer(itemCount: 3, itemHeight: 120),
      error: (error, _) => _ScrollableCenter(
        child: ErrorView(
          message: l10n.studentsRelatedLoadError,
          detail: error.toString(),
          onRetry: () => ref.invalidate(studentGradesProvider(studentId)),
        ),
      ),
      data: (qualifications) {
        final sections = _buildSections(l10n, qualifications);
        if (sections.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: _ScrollableCenter(
                  child: EmptyState(
                    icon: Icons.grade_outlined,
                    title: l10n.studentsNoGrades,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _BoletinButton(studentId: studentId),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index == sections.length) {
              return _BoletinButton(studentId: studentId);
            }
            return StudentGradesGrid(
              qualifications: sections[index].qualifications,
              classroomName: sections[index].name,
            );
          },
        );
      },
    );

    if (!canWrite) return content;

    final classrooms = ref.watch(dashboardProvider).data?.classrooms ??
        const <ProfessorClassroomSummary>[];
    final hasClassroom = classroomId != null || classrooms.isNotEmpty;

    return Column(
      children: [
        Expanded(child: content),
        _StudentGradeActionBar(
          enabled: hasClassroom,
          disabledMessage: l10n.studentGradeNoClassrooms,
          label: l10n.studentGradeFromDetail,
          onTap: () => _openCreateSheet(context, ref, classrooms),
        ),
      ],
    );
  }

  Future<void> _openCreateSheet(
    BuildContext context,
    WidgetRef ref,
    List<ProfessorClassroomSummary> classrooms,
  ) async {
    final result = await showModalBottomSheet<QualificationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QualificationFormSheet(
        classroomId: classroomId,
        classrooms: classroomId == null
            ? classrooms
                .map(
                  (classroom) => QualificationClassroomOption(
                    id: classroom.id,
                    name: classroom.name,
                  ),
                )
                .toList()
            : null,
        students: [
          ClassroomGradeStudent(
            studentId: studentId,
            fullname: studentFullname,
          ),
        ],
        initialStudentId: studentId,
      ),
    );

    if (result == QualificationFormResult.saved && context.mounted) {
      ref.invalidate(studentGradesProvider(studentId));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.gradeFormSaved)));
    }
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
      groups
          .putIfAbsent(qualification.classroomId, () => [])
          .add(qualification);
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

/// Acceso al boletín del alumno desde el pie del tab Notas (todos los roles).
class _BoletinButton extends StatelessWidget {
  final String studentId;

  const _BoletinButton({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/students/$studentId/boletin'),
        icon: const Icon(PhosphorIconsRegular.fileText, size: 18),
        label: Text(l10n.boletinViewAction),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

/// Centers fixed-height states (empty/error) filling the available height,
/// scrolling instead of overflowing when the footer leaves little room.
class _ScrollableCenter extends StatelessWidget {
  final Widget child;

  const _ScrollableCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _StudentGradeActionBar extends StatelessWidget {
  final bool enabled;
  final String disabledMessage;
  final String label;
  final VoidCallback onTap;

  const _StudentGradeActionBar({
    required this.enabled,
    required this.disabledMessage,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child:
            enabled ? button : Tooltip(message: disabledMessage, child: button),
      ),
    );
  }
}

class _GradesSection {
  final String name;
  final List<QualificationModel> qualifications;

  const _GradesSection({required this.name, required this.qualifications});
}

class StudentAbsencesTab extends ConsumerWidget {
  final String studentId;
  final String? classroomId;
  final bool canWrite;

  const StudentAbsencesTab({
    super.key,
    required this.studentId,
    this.classroomId,
    this.canWrite = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = studentAbsencesProvider(studentId);
    final state = ref.watch(provider);

    final Widget content = PagedTabList<AbsenceModel>(
      state: state,
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: l10n.studentsNoAbsences,
      errorMessage: l10n.studentsRelatedLoadError,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, absence) => AbsenceTile(absence: absence),
    );

    if (!canWrite) return content;

    final classrooms = ref.watch(dashboardProvider).data?.classrooms ??
        const <ProfessorClassroomSummary>[];
    final hasClassroom = classroomId != null || classrooms.isNotEmpty;

    return Column(
      children: [
        Expanded(child: content),
        _StudentGradeActionBar(
          enabled: hasClassroom,
          disabledMessage: l10n.studentGradeNoClassrooms,
          label: l10n.absenceMarkTitle,
          onTap: () => _openMarkSheet(context, ref, classrooms),
        ),
      ],
    );
  }

  Future<void> _openMarkSheet(
    BuildContext context,
    WidgetRef ref,
    List<ProfessorClassroomSummary> classrooms,
  ) async {
    final marked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkAbsenceSheet(
        studentId: studentId,
        classroomId: classroomId,
        classrooms: classroomId == null ? classrooms : null,
      ),
    );

    if (marked == null || !context.mounted) return;
    ref.invalidate(studentAbsencesProvider(studentId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            marked
                ? context.l10n.absenceMarked
                : context.l10n.absenceAlreadyMarked,
          ),
        ),
      );
  }
}

class StudentFeesTab extends ConsumerWidget {
  final String studentId;

  const StudentFeesTab({
    super.key,
    required this.studentId,
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
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, fee) => FeeTile(fee: fee),
    );
  }
}
