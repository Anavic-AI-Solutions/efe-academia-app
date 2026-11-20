import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/student_grades_provider.dart';
import '../../domain/classroom_grades_summary.dart';
import '../../domain/qualification_model.dart';
import '../../providers/qualification_provider.dart';
import 'qualification_form_sheet.dart';

/// Bottom sheet that lists every grade of a student, grouped by classroom, and
/// exposes the edit/delete actions allowed by the current role.
class QualificationManagerSheet extends ConsumerStatefulWidget {
  final String studentId;
  final String studentFullname;

  /// When set, only grades of that classroom are listed.
  final String? classroomId;

  const QualificationManagerSheet({
    super.key,
    required this.studentId,
    required this.studentFullname,
    this.classroomId,
  });

  @override
  ConsumerState<QualificationManagerSheet> createState() =>
      _QualificationManagerSheetState();
}

class _QualificationManagerSheetState
    extends ConsumerState<QualificationManagerSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final canManage = user?.canManageQualifications ?? false;
    final canDelete = user?.canDeleteQualifications ?? false;
    final gradesAsync = ref.watch(studentGradesProvider(widget.studentId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navInactive.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.gradeFormManageTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightInk,
            ),
          ),
          if (widget.studentFullname.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.studentFullname,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: gradesAsync.when(
              data: (grades) => _buildList(
                context,
                grades,
                canManage: canManage,
                canDelete: canDelete,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.gradesLoadError,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        studentGradesProvider(widget.studentId),
                      ),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<QualificationModel> grades, {
    required bool canManage,
    required bool canDelete,
  }) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classroomId = widget.classroomId;
    final visible = classroomId == null
        ? grades
        : grades
            .where((qualification) => qualification.classroomId == classroomId)
            .toList();

    if (visible.isEmpty) {
      return KeyedSubtree(
        key: const Key('qualification-manager-empty'),
        child: EmptyState(
          icon: Icons.grade_outlined,
          title: l10n.gradeFormManageEmpty,
          subtitle: l10n.gradeFormManageEmptyHint,
        ),
      );
    }

    final groups = <String, List<QualificationModel>>{};
    for (final qualification in visible) {
      final name = qualification.classroomName.isNotEmpty
          ? qualification.classroomName
          : l10n.studentGradeClassroom;
      groups.putIfAbsent(name, () => []).add(qualification);
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Text(
              entry.key,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.sectionLabel,
              ),
            ),
          ),
          for (final qualification in entry.value)
            _QualificationRow(
              qualification: qualification,
              canManage: canManage,
              canDelete: canDelete,
              onEdit: () => _edit(qualification),
              onDelete: () => _delete(qualification),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _edit(QualificationModel qualification) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<QualificationFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QualificationFormSheet(
        qualification: qualification,
        classroomId: qualification.classroomId,
        students: [
          ClassroomGradeStudent(
            studentId: widget.studentId,
            fullname: widget.studentFullname,
          ),
        ],
        initialStudentId: widget.studentId,
      ),
    );
    if (!mounted || result == null) return;

    _invalidate(qualification);
    if (!mounted) return;
    _showSnack(
      result == QualificationFormResult.deleted
          ? l10n.gradeFormDeleted
          : l10n.gradeFormUpdated,
    );
  }

  Future<void> _delete(QualificationModel qualification) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.gradeFormDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(qualificationRepositoryProvider)
          .deleteQualification(qualification.id);
      _invalidate(qualification);
      if (!mounted) return;
      _showSnack(l10n.gradeFormDeleted);
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.gradeFormDeleteError);
    }
  }

  void _invalidate(QualificationModel qualification) {
    final studentId = qualification.studentId.isNotEmpty
        ? qualification.studentId
        : widget.studentId;
    ref.invalidate(studentGradesProvider(studentId));

    final classroomId = qualification.classroomId.isNotEmpty
        ? qualification.classroomId
        : widget.classroomId;
    if (classroomId != null && classroomId.isNotEmpty) {
      ref.invalidate(classroomGradesProvider(classroomId));
      ref.invalidate(
        boletinProvider((studentId: studentId, classroomId: classroomId)),
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QualificationRow extends StatelessWidget {
  final QualificationModel qualification;
  final bool canManage;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QualificationRow({
    required this.qualification,
    required this.canManage,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: Key('qualification-manager-row-${qualification.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.gradeEmptyBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ScorePill(qualification: qualification),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        qualification.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightInk,
                        ),
                      ),
                    ),
                    if (qualification.category.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          qualification.category,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (qualification.period.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${qualification.period}°',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              key: Key('qualification-manager-menu-${qualification.id}'),
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              tooltip: l10n.gradeFormManageTitle,
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: Key('qualification-manager-edit-${qualification.id}'),
                  value: 'edit',
                  child: Text(l10n.commonEdit),
                ),
                if (canDelete)
                  PopupMenuItem(
                    key:
                        Key('qualification-manager-delete-${qualification.id}'),
                    value: 'delete',
                    child: Text(l10n.gradeFormDelete),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final QualificationModel qualification;

  const _ScorePill({required this.qualification});

  @override
  Widget build(BuildContext context) {
    final label = qualification.scoreLabel.isNotEmpty
        ? qualification.scoreLabel
        : AppColors.formatGrade(qualification.score);
    final numeric = double.tryParse(qualification.scoreLabel);
    final color =
        numeric != null ? AppColors.gradeColor(numeric) : AppColors.primary;

    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.titleSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
