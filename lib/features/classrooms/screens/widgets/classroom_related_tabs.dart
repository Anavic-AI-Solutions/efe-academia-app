import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n.dart';
import '../../../students/domain/student_model.dart';
import '../../domain/material_model.dart';
import '../../domain/professor_model.dart';
import '../../providers/classroom_provider.dart';
import 'material_tile.dart';
import 'paged_tab_list.dart';
import 'professor_tile.dart';
import 'student_tile.dart';

class ClassroomStudentsTab extends ConsumerWidget {
  final String classroomId;

  const ClassroomStudentsTab({super.key, required this.classroomId});

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
        onTap: () => context.push('/students/${student.id}'),
      ),
    );
  }
}

class ClassroomProfessorsTab extends ConsumerWidget {
  final String classroomId;

  const ClassroomProfessorsTab({super.key, required this.classroomId});

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

  const ClassroomMaterialsTab({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = classroomMaterialsProvider(classroomId);
    final state = ref.watch(provider);

    return PagedTabList<MaterialModel>(
      state: state,
      emptyIcon: Icons.folder_outlined,
      emptyTitle: l10n.classroomsNoMaterials,
      errorMessage: l10n.classroomsRelatedLoadError,
      onRetry: () => ref.read(provider.notifier).refresh(),
      onPageChanged: (page) => ref.read(provider.notifier).goToPage(page),
      itemBuilder: (context, material) => MaterialTile(material: material),
    );
  }
}
