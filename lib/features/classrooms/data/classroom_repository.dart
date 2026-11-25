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
    String? studentId,
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
        studentId: studentId,
      );
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
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
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
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
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
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
      return PageResult.fromJson(
        response.data,
        page: page,
        perPage: limit,
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

  Future<ClassroomModel> createClassroom({
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) async {
    try {
      final response = await _api.createClassroom({
        'name': name,
        'description': description,
        'status': status,
        'shift': shift,
        'day': day,
        'hour': hour,
        'room': room,
        'year': year,
        'branch': branch,
        'level': level,
        'grade': grade,
        'book': book,
        'commission': commission,
        'course_days': courseDays,
        'period_1_days': period1Days,
        'period_2_days': period2Days,
        'period_3_days': period3Days,
        'is_archivated': isArchived,
      });
      return ClassroomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ClassroomModel> updateClassroom(
    String id, {
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) async {
    try {
      final response = await _api.updateClassroom(id, {
        'name': name,
        'description': description,
        'status': status,
        'shift': shift,
        'day': day,
        'hour': hour,
        'room': room,
        'year': year,
        'branch': branch,
        'level': level,
        'grade': grade,
        'book': book,
        'commission': commission,
        'course_days': courseDays,
        'period_1_days': period1Days,
        'period_2_days': period2Days,
        'period_3_days': period3Days,
        'is_archivated': isArchived,
      });
      return ClassroomModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteClassroom(String id) async {
    try {
      await _api.deleteClassroom(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> setArchived(String id, bool isArchived) async {
    try {
      await _api.setArchived(id, isArchived);
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

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
