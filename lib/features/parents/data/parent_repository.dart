import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../students/domain/student_model.dart';
import '../domain/parent_model.dart';
import 'parent_api.dart';

class ParentRepository {
  static const _maxStudentPages = 5;
  static const _studentPageSize = 100;

  final ParentApi _api;

  ParentRepository(this._api);

  Future<CursorPagination<ParentModel>> getParents({
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getParents(search: search, cursor: cursor);
      return _parseCursorPage(response.data, ParentModel.fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ParentModel> getParent(String id) async {
    try {
      final response = await _api.getParent(id);
      return ParentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ParentModel> createParent({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String status = 'pending',
  }) async {
    try {
      final response = await _api.createParent({
        'fullname': fullname,
        'email': email,
        'identity_number': identityNumber,
        'status': status,
        if (_hasValue(phone)) 'phone': phone,
        if (_hasValue(address)) 'address': address,
      });
      return ParentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ParentModel> updateParent(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    required String status,
  }) async {
    try {
      final response = await _api.updateParent(id, {
        'fullname': fullname,
        'email': email,
        // Updates send every optional key: the backend turns an empty string
        // into null, which is how a cleared field is persisted.
        'phone': phone?.trim() ?? '',
        'address': address?.trim() ?? '',
        'identity_number': identityNumber,
        'status': status,
      });
      return ParentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteParent(String id) async {
    try {
      await _api.deleteParent(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Loads every linked student, following cursors for at most five pages.
  Future<List<StudentModel>> getParentStudents(String parentId) async {
    try {
      final students = <StudentModel>[];
      String? cursor;

      for (var page = 0; page < _maxStudentPages; page++) {
        final response = await _api.getParentStudents(
          parentId,
          cursor: cursor,
          limit: _studentPageSize,
        );
        final result = _parseCursorPage(response.data, StudentModel.fromJson);
        students.addAll(result.data);

        final nextCursor = result.nextCursor;
        if (!result.hasMore ||
            result.data.isEmpty ||
            nextCursor == null ||
            nextCursor == cursor) {
          break;
        }
        cursor = nextCursor;
      }

      return students;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> linkStudent(String parentId, String studentId) async {
    try {
      await _api.linkStudent(parentId, studentId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> unlinkStudent(String parentId, String studentId) async {
    try {
      await _api.unlinkStudent(parentId, studentId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  CursorPagination<T> _parseCursorPage<T>(
    dynamic body,
    T Function(Map<String, dynamic>) parse,
  ) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final rawItems = map['data'] is List
        ? map['data'] as List<dynamic>
        : body is List
            ? body
            : const <dynamic>[];
    final meta = map['meta'] is Map<String, dynamic>
        ? map['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return CursorPagination<T>(
      data: rawItems.whereType<Map<String, dynamic>>().map(parse).toList(),
      nextCursor: meta['cursor']?.toString(),
      hasMore: meta['has_more'] == true,
      total: (meta['total'] as num?)?.toInt(),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
