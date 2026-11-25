import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
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
import '../../classrooms/domain/professor_model.dart';
import '../providers/professor_provider.dart';

class ProfessorDetailScreen extends ConsumerWidget {
  final String professorId;

  const ProfessorDetailScreen({
    super.key,
    required this.professorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final professorAsync = ref.watch(professorDetailProvider(professorId));
    final canManageProfessors =
        ref.watch(authProvider).user?.canManageProfessors ?? false;

    return professorAsync.when(
      loading: () => _buildLoading(isDark, l10n),
      error: (error, _) => _buildError(ref, isDark, l10n, error),
      data: (professor) => Scaffold(
        backgroundColor: AppColors.backgroundFor(isDark),
        body: Column(
          children: [
            DetailHero(
              leading: AppAvatar(
                name: professor.fullname,
                size: 52,
                showBorder: true,
              ),
              title: professor.fullname,
              fallbackRoute: '/professors',
              bottom: canManageProfessors
                  ? ProfessorDetailActions(professor: professor)
                  : null,
              chips: [
                if (professor.specialty.isNotEmpty)
                  DetailHeroChip(
                    icon: PhosphorIconsRegular.bookOpen,
                    label: professor.specialty,
                  ),
                if (professor.email.isNotEmpty)
                  DetailHeroChip(
                    icon: PhosphorIconsRegular.envelope,
                    label: professor.email,
                  ),
                DetailHeroChip(
                  icon: PhosphorIconsRegular.users,
                  label: l10n.professorsClassroomsCount(
                    professor.classroomCount,
                  ),
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
                          label: l10n.professorsFormFullname,
                          value: professor.fullname,
                        ),
                        InfoRow(
                          label: l10n.professorsFormEmail,
                          value: professor.email,
                        ),
                        InfoRow(
                          label: l10n.professorsFormPhone,
                          value: professor.phone,
                        ),
                        InfoRow(
                          label: l10n.professorsFormAddress,
                          value: professor.address,
                        ),
                        InfoRow(
                          label: l10n.professorsFormIdentity,
                          value: professor.identityNumber,
                        ),
                        InfoRow(
                          label: l10n.professorsFormSpecialty,
                          value: professor.specialty,
                        ),
                        InfoRow(
                          label: l10n.professorsFormBio,
                          value: professor.bio,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
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
          ScreenHeader(title: l10n.professorsTitle),
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
          ScreenHeader(title: l10n.professorsTitle),
          Expanded(
            child: ErrorView(
              message: l10n.professorsLoadError,
              detail: error.toString(),
              onRetry: () =>
                  ref.invalidate(professorDetailProvider(professorId)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProfessorAction { edit, delete }

/// Admin-only edit / delete menu rendered in the detail hero.
class ProfessorDetailActions extends ConsumerWidget {
  final ProfessorModel professor;

  const ProfessorDetailActions({
    super.key,
    required this.professor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<_ProfessorAction>(
        key: const Key('professor-detail-actions'),
        tooltip: l10n.commonActions,
        padding: EdgeInsets.zero,
        onSelected: (action) async {
          switch (action) {
            case _ProfessorAction.edit:
              await _edit(context, ref);
            case _ProfessorAction.delete:
              await _delete(context, ref);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ProfessorAction.edit,
            child: Text(l10n.commonEdit),
          ),
          PopupMenuItem(
            value: _ProfessorAction.delete,
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
      '/professors/${professor.id}/edit',
    );
    if (result != true || !context.mounted) return;
    ref.invalidate(professorDetailProvider(professor.id));
    await ref.read(professorListProvider.notifier).refresh();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.professorsDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(professorRepositoryProvider).deleteProfessor(
            professor.id,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.professorsDeleted)),
      );
      ref.invalidate(professorDetailProvider(professor.id));
      await ref.read(professorListProvider.notifier).refresh();
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
