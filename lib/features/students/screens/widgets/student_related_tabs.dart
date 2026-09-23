import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/paged_tab_list.dart';
import '../../../../l10n/l10n.dart';
import '../../../fees/domain/fee_model.dart';
import '../../../qualifications/domain/qualification_model.dart';
import '../../domain/absence_model.dart';
import '../../providers/student_provider.dart';
import 'absence_tile.dart';
import 'fee_tile.dart';
import 'qualification_tile.dart';

class StudentGradesTab extends ConsumerWidget {
  final String studentId;

  const StudentGradesTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = studentQualificationsProvider(studentId);
    final state = ref.watch(provider);

    return PagedTabList<QualificationModel>(
      state: state,
      emptyIcon: Icons.grade_outlined,
      emptyTitle: l10n.studentsNoGrades,
      errorMessage: l10n.studentsRelatedLoadError,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, qualification) =>
          QualificationTile(qualification: qualification),
    );
  }
}

class StudentAbsencesTab extends ConsumerWidget {
  final String studentId;

  const StudentAbsencesTab({super.key, required this.studentId});

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
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, absence) => AbsenceTile(absence: absence),
    );
  }
}

class StudentFeesTab extends ConsumerWidget {
  final String studentId;

  const StudentFeesTab({super.key, required this.studentId});

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
