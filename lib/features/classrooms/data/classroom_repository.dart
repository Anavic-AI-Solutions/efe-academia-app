import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import '../../students/domain/student_model.dart';
import '../domain/classroom_filters.dart';
import '../domain/classroom_model.dart';
import '../domain/material_model.dart';
import '../domain/professor_model.dart';
import 'classroom_api.dart';

class ClassroomRepository {
  final ClassroomApi _api;

  ClassroomRepository(this._api);

  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async {
    try {
      final response = await _api.getClassrooms(
        search: search,
        page: page,
        limit: limit,
        branch: branch,
        level: level,
        year: year,
        status: status,
      );
      return _parsePage(
        response.data,
        page: page,
        limit: limit,
        parse: ClassroomModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getClassroomStudents(
        id,
        page: page,
        limit: limit,
      );
      return _parsePage(
        response.data,
        page: page,
        limit: limit,
        parse: StudentModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getClassroomProfessors(
        id,
        page: page,
        limit: limit,
      );
      return _parsePage(
        response.data,
        page: page,
        limit: limit,
        parse: ProfessorModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getClassroomMaterials(
        id,
        page: page,
        limit: limit,
      );
      return _parsePage(
        response.data,
        page: page,
        limit: limit,
        parse: MaterialModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ClassroomModel> getClassroom(String id) async {
    try {
      final response = await _api.getClassroom(id);
      return ClassroomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ClassroomFilters> getFilters() async {
    try {
      final response = await _api.getClassroomFilters();
      return ClassroomFilters.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  PageResult<T> _parsePage<T>(
    dynamic body, {
    required int page,
    required int limit,
    required T Function(Map<String, dynamic>) parse,
  }) {
    final items = (body['data'] as List)
        .map((e) => parse(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] ?? {};
    return PageResult(
      data: items,
      page: page,
      perPage: limit,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
    );
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
