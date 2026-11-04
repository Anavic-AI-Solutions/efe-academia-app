import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/faq_repository.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/pagination/async_list_state.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  final api = ref.watch(faqApiProvider);
  return FaqRepository(api);
});

final faqApiProvider = Provider<FaqApi>((ref) {
  return FaqApi(ref.watch(apiClientProvider));
});

final faqListProvider =
    StateNotifierProvider<FaqListNotifier, AsyncListState<FaqModel>>(
  (ref) {
    final repository = ref.watch(faqRepositoryProvider);
    return FaqListNotifier(repository);
  },
);

class FaqListNotifier extends StateNotifier<AsyncListState<FaqModel>> {
  final FaqRepository _repository;
  int _requestId = 0;

  FaqListNotifier(this._repository)
      : super(const AsyncListState(page: CursorPagination.empty()));

  Future<void> load({String? search, String? cursor}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getFaqs(
        search: search,
        cursor: cursor,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(page: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String? get cursor => state.page.nextCursor;
  List<FaqModel> get data => state.page.data;
  bool get hasMore => state.page.hasMore;
  int get total => state.page.total ?? 0;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}
