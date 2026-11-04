import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_api.dart';
import '../../classrooms/domain/material_model.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

class LibraryRepository {
  final LibraryApi _api;
  LibraryRepository(this._api);

  Future<CursorPagination<MaterialModel>> getMaterials({
    String? search,
    String? cursor,
  }) async {
    final response = await _api.getMaterials(
      search: search,
      cursor: cursor,
    );

    final data = (response.data['data'] as List?)
        ?.map((json) => MaterialModel.fromJson(json))
        .toList() ??
        [];

    final cursorStr = response.data['cursor'] as String?;
    final hasMore = response.data['has_more'] as bool? ?? false;
    final total = response.data['total'] as int? ?? data.length;

    return CursorPagination(
      data: data,
      nextCursor: cursorStr,
      hasMore: hasMore,
      total: total,
    );
  }
}