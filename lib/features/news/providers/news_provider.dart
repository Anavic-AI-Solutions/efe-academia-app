import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/news_api.dart';
import '../data/news_repository.dart';
import '../domain/news_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final newsApiProvider = Provider<NewsApi>((ref) {
  return NewsApi(ref.watch(apiClientProvider));
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(ref.watch(newsApiProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NewsListState {
  final CursorPagination<NewsModel> pagination;
  final bool isLoading;
  final String? error;

  NewsListState({
    CursorPagination<NewsModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<NewsModel>.empty();

  NewsListState copyWith({
    CursorPagination<NewsModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NewsListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NewsListNotifier extends StateNotifier<NewsListState> {
  final NewsRepository _repository;

  NewsListNotifier(this._repository) : super(NewsListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNews();
      print('[News] Loaded ${result.data.length} items');
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      print('[News] ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNews();
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getNews(
        cursor: state.pagination.nextCursor,
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final newsListProvider =
    StateNotifierProvider<NewsListNotifier, NewsListState>((ref) {
  return NewsListNotifier(ref.watch(newsRepositoryProvider));
});
