import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/cursor_pagination.dart';

/// Fetches one cursor page for the active [search] term.
///
/// A `null` [cursor] requests the first page; every other value is the
/// `nextCursor` of the page that was loaded before.
typedef CursorPageLoader<T> = Future<CursorPagination<T>> Function({
  String? cursor,
  String search,
});

class CursorListState<T> {
  final CursorPagination<T> pagination;
  final bool isLoading;
  final String? error;
  final String search;

  CursorListState({
    CursorPagination<T>? pagination,
    this.isLoading = false,
    this.error,
    this.search = '',
  }) : pagination = pagination ?? CursorPagination<T>.empty();

  List<T> get data => pagination.data;
  bool get hasMore => pagination.hasMore;

  CursorListState<T> copyWith({
    CursorPagination<T>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
  }) {
    return CursorListState<T>(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
    );
  }
}

/// Cursor based list state shared by the people management screens.
///
/// It loads the first page on creation and tracks a [requestId] so responses
/// from an older search or refresh never overwrite newer results. [loadMore]
/// appends the page addressed by `pagination.nextCursor`.
class CursorListNotifier<T> extends StateNotifier<CursorListState<T>> {
  final CursorPageLoader<T> _loader;
  int _requestId = 0;
  bool _loadingMore = false;

  CursorListNotifier(this._loader) : super(CursorListState<T>()) {
    load();
  }

  /// Loads the first page for the active [CursorListState.search].
  ///
  /// With [refresh] the current results stay visible until the new page
  /// arrives, which avoids an empty flash on pull to refresh. Without it the
  /// list is cleared first, as expected for an initial load or a new search.
  Future<void> load({bool refresh = false}) async {
    final requestId = ++_requestId;
    final search = state.search;
    _loadingMore = false;
    state = state.copyWith(
      pagination: refresh ? null : CursorPagination<T>.empty(),
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await _loader(cursor: null, search: search);
      if (requestId != _requestId) return;
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Appends the next page, if any, using `pagination.nextCursor`.
  Future<void> loadMore() async {
    if (_loadingMore || state.isLoading || !state.pagination.hasMore) return;

    final cursor = state.pagination.nextCursor;
    if (cursor == null) return;

    final requestId = _requestId;
    final search = state.search;
    _loadingMore = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _loader(cursor: cursor, search: search);
      if (requestId != _requestId) return;
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      if (requestId == _requestId) _loadingMore = false;
    }
  }

  /// Applies a new search term and reloads from the first page.
  Future<void> setSearch(String value) {
    final search = value.trim();
    if (search == state.search) return Future<void>.value();

    state = state.copyWith(search: search);
    return load();
  }

  /// Reloads the first page keeping the active search and current results.
  Future<void> refresh() => load(refresh: true);
}
