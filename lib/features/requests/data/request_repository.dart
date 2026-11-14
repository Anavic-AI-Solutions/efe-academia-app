import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import '../domain/request_model.dart';
import 'request_api.dart';

class RequestRepository {
  final RequestApi _api;

  RequestRepository(this._api);

  Future<PageResult<RequestModel>> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.getRequests(
        search: search,
        status: status,
        type: type,
        page: page,
        perPage: perPage,
      );
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final result = PageResult.fromJson(
        body,
        page: page,
        perPage: perPage,
        parse: RequestModel.fromJson,
      );
      final meta = body['meta'] is Map<String, dynamic>
          ? body['meta'] as Map<String, dynamic>
          : <String, dynamic>{};
      final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;

      return PageResult(
        data: result.data,
        page: currentPage,
        perPage: result.perPage,
        total: result.total,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<RequestModel> getRequest(RequestKind kind, String id) async {
    try {
      final response = kind == RequestKind.parent
          ? await _api.getParentRequest(id)
          : await _api.getStudentRequest(id);
      return RequestModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<bool> approve(
    RequestModel request, {
    String? classroomId,
  }) async {
    if (request.kind == RequestKind.student &&
        (classroomId == null || classroomId.isEmpty)) {
      throw ApiException(message: 'Elegí un curso para aprobar al alumno.');
    }

    try {
      final response = request.kind == RequestKind.student
          ? await _api.approveStudent(request.id, classroomId!)
          : await _api.approveParent(request.id);
      return _changed(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<bool> reject(RequestModel request) async {
    try {
      final response = request.kind == RequestKind.student
          ? await _api.rejectStudent(request.id)
          : await _api.rejectParent(request.id);
      return _changed(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  bool _changed(Response response) {
    final body = response.data;
    if (body is Map) {
      final data = body['data'];
      if (data is Map && data['changed'] is bool) {
        return data['changed'] as bool;
      }
    }
    return true;
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
