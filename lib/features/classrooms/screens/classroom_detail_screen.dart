import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../students/providers/student_provider.dart';
import '../domain/classroom_model.dart';
import '../providers/classroom_provider.dart';
import 'widgets/classroom_detail_header.dart';
import 'widgets/classroom_related_tabs.dart';
import 'widgets/classroom_summary_tab.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classroomAsync = ref.watch(classroomDetailProvider(classroomId));
    final user = ref.watch(authProvider).user;
    final isProfessor = user?.isProfessor ?? false;
    final canManageClassrooms = user?.canManageClassrooms ?? false;
    final canManageMaterials = user?.canManageMaterials ?? false;
    final accent = AppColors.accentFor(isDark);

    return classroomAsync.when(
      loading: () => _buildLoading(context, isDark, l10n),
      error: (e, _) => _buildError(context, isDark, l10n, e, ref),
      data: (classroom) => DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.backgroundFor(isDark),
          body: Column(
            children: [
              ClassroomDetailHeader(
                classroom: classroom,
                showActions: isProfessor,
                onAttendance: () =>
                    context.push('/classrooms/$classroomId/attendance'),
                onGrades: () => context.push('/classrooms/$classroomId/grades'),
                menu: canManageClassrooms
                    ? ClassroomStaffMenu(classroom: classroom)
                    : null,
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                labelColor: accent,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: accent,
                labelStyle: AppTypography.titleSmall,
                unselectedLabelStyle: AppTypography.titleSmall,
                tabs: [
                  Tab(text: l10n.classroomsTabSummary),
                  Tab(text: l10n.classroomsTabStudents),
                  Tab(text: l10n.classroomsTabProfessors),
                  Tab(text: l10n.classroomsTabMaterials),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ClassroomSummaryTab(
                      classroom: classroom,
                    ),
                    ClassroomStudentsTab(
                      classroomId: classroomId,
                    ),
                    ClassroomProfessorsTab(
                      classroomId: classroomId,
                    ),
                    ClassroomMaterialsTab(
                      classroomId: classroomId,
                      canManage: canManageMaterials,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.classroomsDetailTitle,
          ),
          Expanded(
            child: ListShimmer(itemCount: 5, itemHeight: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, AppLocalizations l10n,
      Object error, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.classroomsDetailTitle,
          ),
          Expanded(
            child: ErrorView(
              message: l10n.classroomsDetailLoadError,
              detail: error.toString(),
              onRetry: () =>
                  ref.invalidate(classroomDetailProvider(classroomId)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ClassroomAction { edit, toggleArchive, delete }

/// Staff-only edit / archive / delete menu rendered in the detail hero.
class ClassroomStaffMenu extends ConsumerWidget {
  final ClassroomModel classroom;

  const ClassroomStaffMenu({super.key, required this.classroom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return PopupMenuButton<_ClassroomAction>(
      key: const Key('classroom-detail-actions'),
      tooltip: l10n.commonActions,
      padding: EdgeInsets.zero,
      onSelected: (action) async {
        switch (action) {
          case _ClassroomAction.edit:
            await _edit(context, ref);
          case _ClassroomAction.toggleArchive:
            await _toggleArchive(context, ref);
          case _ClassroomAction.delete:
            await _delete(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ClassroomAction.edit,
          child: Text(l10n.commonEdit),
        ),
        PopupMenuItem(
          value: _ClassroomAction.toggleArchive,
          child: Text(
            classroom.isArchived
                ? l10n.classroomsUnarchive
                : l10n.classroomsArchive,
          ),
        ),
        PopupMenuItem(
          value: _ClassroomAction.delete,
          child: Text(l10n.commonDelete),
        ),
      ],
      child: Container(
        // Keep the trigger at the 48 dp minimum touch target.
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        alignment: Alignment.center,
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
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final id = classroom.id;
    await context.push<bool>('/classrooms/$id/edit');
    if (!context.mounted) return;
    // Refresh the list before invalidating the detail: the invalidated detail
    // rebuilds its subtree, so this widget must not use `ref` afterwards.
    await ref.read(classroomListProvider.notifier).refresh();
    if (!context.mounted) return;
    ref.invalidate(studentClassroomsProvider);
    ref.invalidate(classroomFiltersProvider);
    ref.invalidate(classroomDetailProvider(id));
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final archive = !classroom.isArchived;

    try {
      await ref
          .read(classroomRepositoryProvider)
          .setArchived(classroom.id, archive);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archive ? l10n.classroomsArchived : l10n.classroomsUnarchived,
          ),
        ),
      );
      // Refresh in place so the active search/filter/page survive.
      await ref.read(classroomListProvider.notifier).refresh();
      if (!context.mounted) return;
      ref.invalidate(studentClassroomsProvider);
      ref.invalidate(classroomDetailProvider(classroom.id));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classroomsArchiveError)),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.classroomsDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(classroomRepositoryProvider).deleteClassroom(classroom.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classroomsDeleted)),
      );
      // Refresh the list while the detail is still mounted, then pop. The
      // deleted detail must not be re-fetched: that would race a 404 against
      // the pop and could strand the user on the error view.
      await ref.read(classroomListProvider.notifier).refresh();
      if (!context.mounted) return;
      ref.invalidate(studentClassroomsProvider);
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonDeleteError)),
      );
    }
  }
}
