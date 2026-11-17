import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/domain/user_model.dart';
import 'profile_api.dart';

class ProfileRepository {
  final ProfileApi _api;

  ProfileRepository(this._api);

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _api.update(name: name, email: email);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final response = await _api.uploadAvatar(form);
      final url = response.data['data']?['avatar']?.toString() ?? '';
      if (url.isEmpty) throw ApiException(message: 'Avatar no disponible');
      return url;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _api.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
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
