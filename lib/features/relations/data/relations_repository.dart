import '../../../core/api/cursor_pagination.dart';
import '../domain/relation_model.dart';
import 'relations_api.dart';

class RelationsRepository {
  final RelationsApi _api;
  RelationsRepository(this._api);

  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async {
    final response = await _api.getRelations(query: query, cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => RelationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor'],
      hasMore: meta['has_more'] ?? false,
      total: meta['total'],
    );
  }
}
