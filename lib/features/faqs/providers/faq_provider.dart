import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../data/faq_api.dart';
import '../data/faq_repository.dart';
import '../domain/faq_model.dart';

final faqApiProvider = Provider<FaqApi>((ref) {
  return FaqApi(ref.watch(apiClientProvider));
});

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.watch(faqApiProvider));
});

final faqListProvider = StateNotifierProvider.autoDispose<FaqListNotifier,
    PagedListState<FaqModel>>(
  (ref) => FaqListNotifier(ref.watch(faqRepositoryProvider)),
);

class FaqListNotifier extends StateNotifier<PagedListState<FaqModel>> {
  final FaqRepository _repository;
  int _requestId = 0;
  int _lastRequestedPage = 1;
  String _search = '';

  FaqListNotifier(this._repository) : super(PagedListState<FaqModel>());

  Future<void> load({int page = 1}) async {
    _lastRequestedPage = page;
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getFaqs(
        search: _search.isEmpty ? null : _search,
        page: page,
      );
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        page: result,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setSearch(String value) async {
    if (_search == value) return;
    _search = value;
    await load();
  }

  Future<void> refresh() => load(page: state.page.page);

  /// Retries the exact request that failed, including a failed search.
  Future<void> retry() => load(page: _lastRequestedPage);

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.page.totalPages || page == state.page.page) {
      return Future.value();
    }
    return load(page: page);
  }
}
