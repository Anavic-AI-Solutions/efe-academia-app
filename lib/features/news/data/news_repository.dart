import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../../core/utils/upload_file.dart';
import '../domain/news_model.dart';
import 'news_api.dart';

class NewsRepository {
  final NewsApi _api;
  NewsRepository(this._api);

  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async {
    final response = await _api.getNews(cursor: cursor);
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    final meta = data is Map<String, dynamic>
        ? (data['meta'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    return CursorPagination(
      data: items
          .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: meta['cursor'],
      hasMore: meta['has_more'] ?? false,
      total: meta['total'],
    );
  }

  Future<NewsModel> createNews({
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async {
    final form = await _buildFormData(
      title: title,
      description: description,
      content: content,
      eventDate: eventDate,
      image: image,
    );
    try {
      final response = await _api.createNews(form);
      return NewsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<NewsModel> updateNews(
    String id, {
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async {
    final form = await _buildFormData(
      title: title,
      description: description,
      content: content,
      eventDate: eventDate,
      image: image,
      isUpdate: true,
    );
    try {
      final response = await _api.updateNews(id, form);
      return NewsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await _api.deleteNews(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FormData> _buildFormData({
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
    bool isUpdate = false,
  }) async {
    final form = FormData();
    if (isUpdate) form.fields.add(const MapEntry('_method', 'PATCH'));
    form.fields.add(MapEntry('title', title));
    form.fields.add(MapEntry('description', description));
    form.fields.add(MapEntry('content', content));
    if (eventDate != null) {
      form.fields.add(MapEntry('event_date', eventDate.toIso8601String()));
    }
    if (image != null) {
      final multipart = image.bytes != null
          ? MultipartFile.fromBytes(image.bytes!, filename: image.name)
          : await MultipartFile.fromFile(image.path!, filename: image.name);
      form.files.add(MapEntry('media', multipart));
    }
    return form;
  }

  /// Propaga tal cual la excepción que armó el interceptor (incluida
  /// [ValidationException] con sus errores por campo).
  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
