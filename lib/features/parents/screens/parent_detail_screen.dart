import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/detail_hero.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../students/domain/student_model.dart';
import '../../students/providers/student_provider.dart';
import '../domain/parent_model.dart';
import '../providers/parent_provider.dart';
import 'widgets/link_student_sheet.dart';
import 'widgets/parent_card.dart';

class ParentDetailScreen extends ConsumerWidget {
  final String parentId;

  const ParentDetailScreen({
    super.key,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentAsync = ref.watch(parentDetailProvider(parentId));
    final canManageParents =
        ref.watch(authProvider).user?.canManageParents ?? false;

    return parentAsync.when(
      loading: () => _buildLoading(isDark, l10n),
      error: (error, _) => _buildError(ref, isDark, l10n, error),
      data: (parent) => Scaffold(
        backgroundColor: AppColors.backgroundFor(isDark),
        body: Column(
          children: [
            DetailHero(
              leading: AppAvatar(
                name: parent.fullname,
                size: 52,
                showBorder: true,
              ),
              title: parent.fullname,
              status: parent.status,
              statusLabel: parent.status.isEmpty
                  ? null
                  : parentStatusLabel(parent.status, l10n),
              fallbackRoute: '/parents',
              bottom:
                  canManageParents ? ParentDetailActions(parent: parent) : null,
              chips: [
                if (parent.email.isNotEmpty)
                  DetailHeroChip(
                    icon: PhosphorIconsRegular.envelope,
                    label: parent.email,
                  ),
                DetailHeroChip(
                  icon: PhosphorIconsRegular.users,
                  label: l10n.parentsStudentCount(parent.studentCount),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        InfoRow(
                          label: l10n.parentsFormFullname,
                          value: parent.fullname,
                        ),
                        InfoRow(
                          label: l10n.parentsFormEmail,
                          value: parent.email,
                        ),
                        InfoRow(
                          label: l10n.parentsFormPhone,
                          value: parent.phone,
                        ),
                        InfoRow(
                          label: l10n.parentsFormAddress,
                          value: parent.address,
                        ),
                        InfoRow(
                          label: l10n.parentsFormIdentity,
                          value: parent.identityNumber,
                        ),
                        InfoRow(
                          label: l10n.parentsFormStatus,
                          value: parentStatusLabel(parent.status, l10n),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ParentLinkedStudentsSection(parentId: parentId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(title: l10n.parentsTitle),
          const Expanded(
            child: ListShimmer(itemCount: 6, itemHeight: 52),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    WidgetRef ref,
    bool isDark,
    AppLocalizations l10n,
    Object error,
  ) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(title: l10n.parentsTitle),
          Expanded(
            child: ErrorView(
              message: l10n.parentsLoadError,
              detail: error.toString(),
              onRetry: () => ref.invalidate(parentDetailProvider(parentId)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ParentAction { edit, delete }

/// Staff edit / delete menu rendered in the detail hero.
class ParentDetailActions extends ConsumerWidget {
  final ParentModel parent;

  const ParentDetailActions({
    super.key,
    required this.parent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<_ParentAction>(
        key: const Key('parent-detail-actions'),
        tooltip: l10n.commonActions,
        padding: EdgeInsets.zero,
        onSelected: (action) async {
          switch (action) {
            case _ParentAction.edit:
              await _edit(context, ref);
            case _ParentAction.delete:
              await _delete(context, ref);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ParentAction.edit,
            child: Text(l10n.commonEdit),
          ),
          PopupMenuItem(
            value: _ParentAction.delete,
            child: Text(l10n.commonDelete),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.commonActions,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await context.push<bool>(
      '/parents/${parent.id}/edit',
    );
    if (result != true || !context.mounted) return;
    ref.invalidate(parentDetailProvider(parent.id));
    ref.invalidate(studentParentsProvider);
    await ref.read(parentListProvider.notifier).refresh();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.parentsDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(parentRepositoryProvider).deleteParent(parent.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.parentsDeleted)),
      );
      // Refresh the list before popping: the detail is leaving the tree, so
      // re-fetching the just-deleted parent would only race a 404 against the
      // pop and could strand the user on the error view.
      ref.invalidate(studentParentsProvider);
      await ref.read(parentListProvider.notifier).refresh();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteError)),
      );
    }
  }
}

/// Sección “Alumnos vinculados” del detalle.
///
/// Lee `parentStudentsProvider(parentId)` y, para staff, permite vincular
/// (abre [LinkStudentSheet]) y desvincular (con confirmación destructiva).
class _ParentLinkedStudentsSection extends ConsumerStatefulWidget {
  final String parentId;

  const _ParentLinkedStudentsSection({required this.parentId});

  @override
  ConsumerState<_ParentLinkedStudentsSection> createState() =>
      _ParentLinkedStudentsSectionState();
}

class _ParentLinkedStudentsSectionState
    extends ConsumerState<_ParentLinkedStudentsSection> {
  String? _unlinkingId;

  Future<void> _openLinkSheet() async {
    final l10n = context.l10n;
    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinkStudentSheet(parentId: widget.parentId),
    );
    if (linked != true || !mounted) return;

    ref.invalidate(parentStudentsProvider(widget.parentId));
    ref.invalidate(parentDetailProvider(widget.parentId));
    ref.invalidate(studentParentsProvider);
    await ref.read(parentListProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.parentsLinked)),
    );
  }

  Future<void> _unlink(StudentModel student) async {
    if (_unlinkingId != null) return;

    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.parentsUnlinkTitle,
      message: l10n.parentsUnlinkMessage,
      confirmLabel: l10n.parentsUnlink,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _unlinkingId = student.id);
    try {
      await ref.read(parentRepositoryProvider).unlinkStudent(
            widget.parentId,
            student.id,
          );
      if (!mounted) return;
      setState(() => _unlinkingId = null);
      ref.invalidate(parentStudentsProvider(widget.parentId));
      ref.invalidate(parentDetailProvider(widget.parentId));
      ref.invalidate(studentParentsProvider);
      await ref.read(parentListProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.parentsUnlinked)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _unlinkingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.parentsUnlinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManageParents =
        ref.watch(authProvider).user?.canManageParents ?? false;
    final studentsAsync = ref.watch(parentStudentsProvider(widget.parentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.parentsLinkedStudents.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.sectionLabel,
                ),
              ),
            ),
            if (canManageParents)
              TextButton.icon(
                key: const Key('parent-link-student'),
                onPressed: _openLinkSheet,
                icon: const Icon(PhosphorIconsRegular.plus, size: 14),
                label: Text(l10n.parentsLinkStudent),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentFor(isDark),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        studentsAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: ListShimmer(itemCount: 2, itemHeight: 44),
          ),
          error: (error, _) => ErrorView(
            message: l10n.studentsLoadError,
            detail: error.toString(),
            onRetry: () =>
                ref.invalidate(parentStudentsProvider(widget.parentId)),
          ),
          data: (students) {
            if (students.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.userMinus,
                      size: 18,
                      color: AppColors.mutedFor(isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.parentsNoStudents,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final student in students) ...[
                  _LinkedStudentRow(
                    student: student,
                    isUnlinking: _unlinkingId == student.id,
                    onUnlink: canManageParents ? () => _unlink(student) : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LinkedStudentRow extends StatelessWidget {
  final StudentModel student;
  final bool isUnlinking;
  final VoidCallback? onUnlink;

  const _LinkedStudentRow({
    required this.student,
    required this.isUnlinking,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AppAvatar(name: student.fullname, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (student.year.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.year,
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
          if (onUnlink != null)
            IconButton(
              key: Key('parent-unlink-${student.id}'),
              tooltip: context.l10n.parentsUnlink,
              onPressed: isUnlinking ? null : onUnlink,
              icon: isUnlinking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      PhosphorIconsRegular.linkBreak,
                      size: 18,
                      color: AppColors.error,
                    ),
            ),
        ],
      ),
    );
  }
}
