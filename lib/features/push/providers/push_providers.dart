import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/push_api.dart';
import '../data/push_repository.dart';

final pushApiProvider = Provider<PushApi>((ref) {
  return PushApi(ref.watch(apiClientProvider));
});

final pushTokenProviderProvider = Provider<PushTokenProvider>((ref) {
  return FirebasePushTokenProvider();
});

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(
    api: ref.watch(pushApiProvider),
    storage: ref.watch(secureStorageProvider),
    tokens: ref.watch(pushTokenProviderProvider),
  );
});
