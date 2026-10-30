import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../qualifications/domain/qualification_model.dart';
import '../../qualifications/providers/qualification_provider.dart';

/// Fetches every qualification of a student (all pages) so the grade grid can
/// be built at once.
final studentGradesProvider =
    FutureProvider.family<List<QualificationModel>, String>(
        (ref, studentId) async {
  final repository = ref.watch(qualificationRepositoryProvider);
  final all = <QualificationModel>[];
  var page = 1;
  var total = 0;

  do {
    final result = await repository.getStudentQualifications(
      studentId,
      page: page,
      limit: 100,
    );
    all.addAll(result.data);
    total = result.total;
    if (result.data.isEmpty) break;
    page++;
  } while (all.length < total && page <= 5);

  return all;
});
