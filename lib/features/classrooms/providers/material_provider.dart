import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/material_api.dart';
import '../data/material_repository.dart';
import 'classroom_provider.dart';

final materialApiProvider = Provider<MaterialApi>((ref) {
  return MaterialApi(ref.watch(apiClientProvider));
});

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(
    ref.watch(materialApiProvider),
    ref.watch(classroomApiProvider),
  );
});