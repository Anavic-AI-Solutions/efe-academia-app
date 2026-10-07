import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/page_pagination.dart';
import '../../students/domain/student_model.dart';
import '../domain/material_model.dart';
import '../domain/material_upload_file.dart';
import 'classroom_api.dart';
import 'material_api.dart';

class MaterialRepository {
  final MaterialApi _api;
  final ClassroomApi _classroomApi;

  MaterialRepository(this._api, this._classroomApi);

  Future<MaterialModel> createMaterial({
    required String classroomId,
    required String name,
    String? description,
    String? type,
    String? category,
    String? visibility,
    String? availableUntil,
    List<String> studentIds = const [],
    required List<MaterialUploadFile> files,
  }) async {
    final form = await _buildFormData({
      'classroom_id': classroomId,
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (type != null && type.isNotEmpty) 'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
      if (availableUntil != null && availableUntil.isNotEmpty)
        'available_until': availableUntil,
      if (studentIds.isNotEmpty) 'student_ids': studentIds,
    }, files);
    try {
      final response = await _api.createMaterial(form);
      return MaterialModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MaterialModel> updateMaterial(
    String id, {
    String? name,
    String? description,
    String? type,
    String? category,
    String? visibility,
    String? availableUntil,
    List<String>? studentIds,

    /// En edición, envía `available_until: null` para limpiar la fecha.
    bool clearAvailableUntil = false,
  }) async {
    final data = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      if (type != null && type.isNotEmpty) 'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
      if (availableUntil != null && availableUntil.isNotEmpty)
        'available_until': availableUntil,
      if (clearAvailableUntil) 'available_until': null,
      if (studentIds != null) 'student_ids': studentIds,
    };
    try {
      final response = await _api.updateMaterial(id, data);
      return MaterialModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MaterialModel> replaceFiles(
    String id, {
    required List<MaterialUploadFile> files,
  }) async {
    final form = await _buildFormData({}, files);
    try {
      final response = await _api.replaceFiles(id, form);
      return MaterialModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _api.deleteMaterial(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MaterialModel> getMaterial(String id) async {
    try {
      final response = await _api.getMaterial(id);
      return MaterialModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<StudentModel>> getClassroomStudents(String classroomId) async {
    const limit = 100;
    final all = <StudentModel>[];
    var page = 1;
    try {
      while (true) {
        final response = await _classroomApi.getClassroomStudents(
          classroomId,
          page: page,
          limit: limit,
        );
        final result = PageResult.fromJson(
          response.data,
          page: page,
          perPage: limit,
          parse: StudentModel.fromJson,
        );
        all.addAll(result.data);
        if (all.length >= result.total || result.data.isEmpty) break;
        page++;
      }
      return all;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FormData> _buildFormData(
    Map<String, dynamic> fields,
    List<MaterialUploadFile> files,
  ) async {
    final form = FormData();
    fields.forEach((key, value) {
      if (value is List) {
        for (final item in value) {
          form.fields.add(MapEntry('$key[]', item.toString()));
        }
      } else if (value != null) {
        form.fields.add(MapEntry(key, value.toString()));
      }
    });
    for (final file in files) {
      final multipart = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);
      form.files.add(MapEntry('files[]', multipart));
    }
    return form;
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado',
      statusCode: e.response?.statusCode,
    );
  }
}
