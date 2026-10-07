import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/paged_tab_list.dart';
import '../../../../l10n/l10n.dart';
import '../../../students/domain/student_model.dart';
import '../../../students/screens/widgets/student_tile.dart';
import '../../domain/material_model.dart';
import '../../domain/material_upload_file.dart';
import '../../domain/professor_model.dart';
import '../../providers/classroom_provider.dart';
import '../../providers/material_provider.dart';
import 'material_form_sheet.dart';
import 'material_tile.dart';
import 'professor_tile.dart';

class ClassroomStudentsTab extends ConsumerWidget {
  final String classroomId;

  const ClassroomStudentsTab({
    super.key,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = classroomStudentsProvider(classroomId);
    final state = ref.watch(provider);

    return PagedTabList<StudentModel>(
      state: state,
      emptyIcon: Icons.school_outlined,
      emptyTitle: l10n.classroomsNoStudents,
      errorMessage: l10n.classroomsRelatedLoadError,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, student) => StudentTile(
        student: student,
        onTap: () => context.push(
          '/students/${student.id}?classroomId=$classroomId',
        ),
      ),
    );
  }
}

class ClassroomProfessorsTab extends ConsumerWidget {
  final String classroomId;

  const ClassroomProfessorsTab({
    super.key,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = classroomProfessorsProvider(classroomId);
    final state = ref.watch(provider);

    return PagedTabList<ProfessorModel>(
      state: state,
      emptyIcon: Icons.person_outline,
      emptyTitle: l10n.classroomsNoProfessors,
      errorMessage: l10n.classroomsRelatedLoadError,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, professor) => ProfessorTile(professor: professor),
    );
  }
}

class ClassroomMaterialsTab extends ConsumerWidget {
  final String classroomId;
  final bool canManage;

  /// Picker de archivos inyectable (tests); el sheet usa el suyo por defecto.
  final Future<List<MaterialUploadFile>> Function()? pickFiles;

  const ClassroomMaterialsTab({
    super.key,
    required this.classroomId,
    this.canManage = false,
    this.pickFiles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = classroomMaterialsProvider(classroomId);
    final state = ref.watch(provider);

    return Column(
      children: [
        Expanded(
          child: PagedTabList<MaterialModel>(
            state: state,
            emptyIcon: Icons.folder_outlined,
            emptyTitle: l10n.classroomsNoMaterials,
            errorMessage: l10n.classroomsRelatedLoadError,
            onRetry: () => ref.read(provider.notifier).refresh(),
            onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
            itemBuilder: (context, material) => MaterialTile(
              material: material,
              canManage: canManage,
              onEdit: () => _openForm(context, ref, material),
              onDelete: () => _confirmDelete(context, ref, material),
            ),
          ),
        ),
        if (canManage)
          _UploadMaterialBar(
            onTap: () => _openForm(context, ref, null),
          ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    MaterialModel? material,
  ) async {
    final l10n = context.l10n;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaterialFormSheet(
        classroomId: classroomId,
        material: material,
        pickFiles: pickFiles,
      ),
    );

    if (saved == true && context.mounted) {
      final message =
          material == null ? l10n.materialsCreated : l10n.materialsUpdated;
      ref.invalidate(classroomMaterialsProvider(classroomId));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MaterialModel material,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.materialsDeleteTitle),
        content: Text(l10n.materialsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.materialsDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.materialsDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(materialRepositoryProvider).deleteMaterial(material.id);
      if (!context.mounted) return;
      ref.invalidate(classroomMaterialsProvider(classroomId));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.materialsDeleted)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.materialsDeleteError)));
    }
  }
}

class _UploadMaterialBar extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadMaterialBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(PhosphorIconsRegular.uploadSimple, size: 18),
            label: Text(context.l10n.materialsAdd),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
