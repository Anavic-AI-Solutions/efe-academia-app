import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/pagination/cursor_list_notifier.dart';
import '../../classrooms/domain/professor_model.dart';
import '../data/professor_api.dart';
import '../data/professor_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final professorApiProvider = Provider<ProfessorApi>((ref) {
  return ProfessorApi(ref.watch(apiClientProvider));
});

final professorRepositoryProvider = Provider<ProfessorRepository>((ref) {
  return ProfessorRepository(ref.watch(professorApiProvider));
});

// ---------------------------------------------------------------------------
// List Provider
// ---------------------------------------------------------------------------

final professorListProvider = StateNotifierProvider<
    CursorListNotifier<ProfessorModel>, CursorListState<ProfessorModel>>((ref) {
  final repository = ref.watch(professorRepositoryProvider);
  return CursorListNotifier<ProfessorModel>(
    ({String? cursor, String search = ''}) =>
        repository.getProfessors(cursor: cursor, search: search),
  );
});

// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final professorDetailProvider =
    FutureProvider.family<ProfessorModel, String>((ref, id) async {
  final repository = ref.watch(professorRepositoryProvider);
  return repository.getProfessor(id);
});
