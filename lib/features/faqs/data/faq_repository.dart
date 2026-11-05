import '../data/faq_api.dart';
import '../domain/faq_model.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';

class FaqRepository {
  final FaqApi _api;
  FaqRepository(this._api);

  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _api.getFaqs(
      search: search,
      page: page,
      perPage: perPage,
    );

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final rawData = body['data'];
    final data = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(FaqModel.fromJson)
            .toList()
        : <FaqModel>[];
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return PageResult(
      data: data,
      page: (meta['current_page'] as num?)?.toInt() ?? page,
      perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
    );
  }
}
