import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/page_pagination.dart';

typedef PageFetcher<T> = Future<PageResult<T>> Function(int page);

class PagedListState<T> {
  final PageResult<T> page;
  final bool isLoading;
  final String? error;

  PagedListState({
    PageResult<T>? page,
    this.isLoading = false,
    this.error,
  }) : page = page ?? PageResult<T>.empty();

  PagedListState<T> copyWith({
    PageResult<T>? page,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PagedListState<T>(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PagedListNotifier<T> extends StateNotifier<PagedListState<T>> {
  final PageFetcher<T> _fetch;
  int _requestId = 0;

  PagedListNotifier(this._fetch) : super(PagedListState<T>()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _fetch(page);
      if (requestId != _requestId) return;
      if (result.data.isEmpty && page > 1 && result.total > 0) {
        await load(page: 1);
        return;
      }
      state = state.copyWith(page: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load(page: state.page.page);

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.page.totalPages || page == state.page.page) {
      return Future.value();
    }
    return load(page: page);
  }
}
