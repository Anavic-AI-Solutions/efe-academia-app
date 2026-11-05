import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../../core/pagination/async_list_state.dart';
import '../../classrooms/domain/material_model.dart';
import '../data/library_api.dart';
import '../data/library_repository.dart';

final libraryApiProvider = Provider<LibraryApi>((ref) {
  return LibraryApi(ref.watch(apiClientProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(libraryApiProvider));
});

final libraryProvider = StateNotifierProvider.autoDispose<LibraryListNotifier,
    AsyncListState<MaterialModel>>(
  (ref) => LibraryListNotifier(ref.watch(libraryRepositoryProvider)),
);

class LibraryListNotifier extends StateNotifier<AsyncListState<MaterialModel>> {
  final LibraryRepository _repository;
  int _requestId = 0;
  bool _firstPageFailed = false;

  LibraryListNotifier(this._repository)
      : super(AsyncListState(page: CursorPagination<MaterialModel>.empty()));

  /// Loads the first page, replacing the current results.
  Future<void> load({String? search}) async {
    final requestId = ++_requestId;
    _firstPageFailed = false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMaterials(search: search);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        page: result,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _firstPageFailed = true;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Appends the next cursor page. No-op when there is nothing else to load.
  Future<void> loadMore({String? search}) async {
    final current = state;
    final cursor = current.page.nextCursor;
    if (current.isLoading || !current.page.hasMore || cursor == null) return;

    final requestId = ++_requestId;
    _firstPageFailed = false;
    state = current.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getMaterials(
        search: search,
        nextCursor: cursor,
      );
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        page: current.page.copyWith(
          data: [...current.page.data, ...result.data],
          nextCursor: result.nextCursor,
          hasMore: result.hasMore,
          total: result.total,
        ),
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _firstPageFailed = false;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Retries whichever operation failed: a first-page load or a cursor page.
  Future<void> retry({String? search}) =>
      _firstPageFailed ? load(search: search) : loadMore(search: search);
}
