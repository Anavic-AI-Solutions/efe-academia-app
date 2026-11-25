import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/pagination/cursor_list_notifier.dart';
import '../../students/domain/student_model.dart';
import '../data/parent_api.dart';
import '../data/parent_repository.dart';
import '../domain/parent_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final parentApiProvider = Provider<ParentApi>((ref) {
  return ParentApi(ref.watch(apiClientProvider));
});

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.watch(parentApiProvider));
});

// ---------------------------------------------------------------------------
// List Provider
// ---------------------------------------------------------------------------

final parentListProvider = StateNotifierProvider<CursorListNotifier<ParentModel>,
    CursorListState<ParentModel>>((ref) {
  final repository = ref.watch(parentRepositoryProvider);
  return CursorListNotifier<ParentModel>(
    ({String? cursor, String search = ''}) =>
        repository.getParents(cursor: cursor, search: search),
  );
});

// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final parentDetailProvider =
    FutureProvider.family<ParentModel, String>((ref, id) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParent(id);
});

final parentStudentsProvider =
    FutureProvider.family<List<StudentModel>, String>((ref, parentId) {
  return ref.watch(parentRepositoryProvider).getParentStudents(parentId);
});
