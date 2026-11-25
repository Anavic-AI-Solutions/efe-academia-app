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
          includeOptionalEmpties: true,
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
    bool includeOptionalEmpties = false,
  }) {
    final payload = <String, dynamic>{
      'fullname': fullname,
      'email': email,
      'identity_number': identityNumber,
    };
    final optional = {
      'phone': phone,
      'address': address,
      'bio': bio,
      'specialty': specialty,
    };
    optional.forEach((key, value) {
      if (includeOptionalEmpties) {
        // Updates must send every optional key: the backend turns an empty
        // string into null, which is how a cleared field is persisted.
        payload[key] = value?.trim() ?? '';
      } else if (_hasValue(value)) {
        payload[key] = value;
      }
    });
    return payload;
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
