import '../domain/news_model.dart';
import 'news_api.dart';

class NewsRepository {
  final NewsApi _api;
  NewsRepository(this._api);

  Future<List<NewsModel>> getNews({String? cursor}) async {
    final response = await _api.getNews(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    return items
        .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
