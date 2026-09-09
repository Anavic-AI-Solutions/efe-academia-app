import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
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
  final List<NewsModel> news;
  final bool isLoading;
  final String? error;

  const NewsListState({
    this.news = const [],
    this.isLoading = false,
    this.error,
  });

  NewsListState copyWith({
    List<NewsModel>? news,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NewsListState(
      news: news ?? this.news,
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

  NewsListNotifier(this._repository) : super(const NewsListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final news = await _repository.getNews();
      state = state.copyWith(news: news, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final news = await _repository.getNews();
      state = state.copyWith(news: news, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final newsListProvider =
    StateNotifierProvider<NewsListNotifier, NewsListState>((ref) {
  return NewsListNotifier(ref.watch(newsRepositoryProvider));
});
