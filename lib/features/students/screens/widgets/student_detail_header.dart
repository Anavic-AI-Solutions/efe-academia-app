import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/detail_hero.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/student_model.dart';
import '../../providers/student_provider.dart';

class StudentDetailHeader extends StatelessWidget {
  final StudentModel student;
  final Widget? actions;

  const StudentDetailHeader({
    super.key,
    required this.student,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DetailHero(
      leading: AppAvatar(
        imageUrl: student.avatarUrl,
        name: student.fullname,
        size: 52,
        showBorder: true,
      ),
      title: student.fullname,
      status: student.status,
      statusLabel: studentStatusLabel(student.status, context.l10n),
      fallbackRoute: '/students',
      bottom: actions,
      chips: [
        if (student.branch.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.mapPin,
            label: student.branch,
          ),
        if (student.year.isNotEmpty)
          DetailHeroChip(
            icon: PhosphorIconsRegular.calendarBlank,
            label: student.year,
          ),
      ],
    );
  }
}

enum _StudentAction { edit, toggle }

/// Staff-only edit / deactivate / reactivate menu rendered in the hero.
class StudentDetailActions extends ConsumerWidget {
  final StudentModel student;

  const StudentDetailActions({super.key, required this.student});

  bool get _isActive => student.status.toLowerCase() == 'active';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<_StudentAction>(
        key: const Key('student-detail-actions'),
        tooltip: l10n.commonActions,
        padding: EdgeInsets.zero,
        onSelected: (action) async {
          switch (action) {
            case _StudentAction.edit:
              await _edit(context, ref);
            case _StudentAction.toggle:
              await _toggle(context, ref);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _StudentAction.edit,
            child: Text(l10n.studentsEditAction),
          ),
          PopupMenuItem(
            value: _StudentAction.toggle,
            child: Text(
              _isActive ? l10n.studentsDeactivate : l10n.studentsReactivate,
            ),
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
    final result = await context.push<bool>('/students/${student.id}/edit');
    if (result != true || !context.mounted) return;
    ref.invalidate(studentDetailProvider(student.id));
    await ref.read(studentListProvider.notifier).refresh();
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final deactivating = _isActive;

    if (deactivating) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.studentsDeactivateTitle,
        message: l10n.studentsDeactivateMessage,
        confirmLabel: l10n.studentsDeactivate,
        cancelLabel: l10n.commonCancel,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }

    try {
      final repository = ref.read(studentRepositoryProvider);
      if (deactivating) {
        await repository.deactivateStudent(student.id);
      } else {
        await repository.reactivateStudent(student.id);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deactivating ? l10n.studentsDeactivated : l10n.studentsReactivated,
          ),
        ),
      );
      ref.invalidate(studentDetailProvider(student.id));
      await ref.read(studentListProvider.notifier).refresh();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonSaveError)),
      );
    }
  }
}
