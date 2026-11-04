import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/faq_api.dart';
import '../domain/faq_model.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

class FaqRepository {
  final FaqApi _api;
  FaqRepository(this._api);

  Future<CursorPagination<FaqModel>> getFaqs({
    String? search,
    String? nextCursor,
  }) async {
    final response = await _api.getFaqs(
      search: search,
      nextCursor: nextCursor,
    );

    final data = (response.data['data'] as List?)
        ?.map((json) => FaqModel.fromJson(json))
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
