import 'library_api.dart';
import '../../classrooms/domain/material_model.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

class LibraryRepository {
  final LibraryApi _api;
  LibraryRepository(this._api);

  Future<CursorPagination<MaterialModel>> getMaterials({
    String? search,
    String? nextCursor,
  }) async {
    final response = await _api.getMaterials(
      search: search,
      nextCursor: nextCursor,
    );

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawData = body['data'];
    final data = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(MaterialModel.fromJson)
            .toList()
        : <MaterialModel>[];
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CursorPagination(
      data: data,
      nextCursor: meta['cursor'] as String?,
      hasMore: meta['has_more'] as bool? ?? false,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
    );
  }
}
