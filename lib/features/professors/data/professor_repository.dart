import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/cursor_pagination.dart';
import '../../classrooms/domain/professor_model.dart';
import 'professor_api.dart';

class ProfessorRepository {
  final ProfessorApi _api;

  ProfessorRepository(this._api);

  Future<CursorPagination<ProfessorModel>> getProfessors({
    String? search,
    String? cursor,
  }) async {
    try {
      final response = await _api.getProfessors(search: search, cursor: cursor);
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : data as List<dynamic>? ?? [];
      final meta = data is Map<String, dynamic>
          ? (data['meta'] as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};
      return CursorPagination(
        data: items
            .whereType<Map<String, dynamic>>()
            .map(ProfessorModel.fromJson)
            .toList(),
        nextCursor: meta['cursor']?.toString(),
        hasMore: meta['has_more'] as bool? ?? false,
        total: meta['total'] as int?,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProfessorModel> getProfessor(String id) async {
    try {
      final response = await _api.getProfessor(id);
      return ProfessorModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProfessorModel> createProfessor({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) async {
    try {
      final response = await _api.createProfessor(_payload(
        fullname: fullname,
        email: email,
        phone: phone,
        address: address,
        identityNumber: identityNumber,
        bio: bio,
        specialty: specialty,
      ));
      return ProfessorModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ProfessorModel> updateProfessor(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) async {
    try {
      final response = await _api.updateProfessor(
        id,
        _payload(
          fullname: fullname,
          email: email,
          phone: phone,
          address: address,
          identityNumber: identityNumber,
          bio: bio,
          specialty: specialty,
        ),
      );
      return ProfessorModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteProfessor(String id) async {
    try {
      await _api.deleteProfessor(id);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _payload({
    required String fullname,
    required String email,
    required String identityNumber,
    String? phone,
    String? address,
    String? bio,
    String? specialty,
  }) {
    return {
      'fullname': fullname,
      'email': email,
      if (_hasValue(phone)) 'phone': phone,
      if (_hasValue(address)) 'address': address,
      'identity_number': identityNumber,
      if (_hasValue(bio)) 'bio': bio,
      if (_hasValue(specialty)) 'specialty': specialty,
    };
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
