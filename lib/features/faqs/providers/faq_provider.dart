import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'faq_repository.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  final api = ref.watch(faqApiProvider);
  return FaqRepository(api);
});

final faqApiProvider = Provider<FaqApi>((ref) {
  return FaqApi(ref.watch(apiClientProvider));
});

final faqListProvider =
    StateNotifierProvider<FaqListNotifier, CursorPagination<FaqModel>>((ref) {
  final repository = ref.watch(faqRepositoryProvider);
  return FaqListNotifier(repository);
});

class FaqListNotifier extends StateNotifier<CursorPagination<FaqModel>> {
  final FaqRepository _repository;
  int _requestId = 0;

  FaqListNotifier(this._repository) : super(CursorPagination.empty());

  Future<void> load({String? search, String? cursor}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getFaqs(
        search: search,
        cursor: cursor,
      );
      if (requestId != _requestId) return;
      state = result.copyWith(isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  CursorPagination<FaqModel> copyWith({
    CursorPagination<FaqModel>? page,
    bool? isLoading,
    String? error,
  }) {
    return CursorPagination(
      cursor: page?.cursor ?? cursor,
      data: page?.data ?? data,
      hasMore: page?.hasMore ?? hasMore,
      total: page?.total ?? total,
    );
  }

  String? get cursor => state.cursor;
  List<FaqModel> get data => state.data;
  bool get hasMore => state.hasMore;
  int get total => state.total;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}