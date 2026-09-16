import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api;
  final SecureStorage _storage;
  final ApiClient _client;

  AuthRepository(this._api, this._storage, this._client);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.login(email: email, password: password);
      final data = response.data['data'];
      final token = data['token'] as String?;
      if (token == null) {
        throw ApiException(message: 'No token received');
      }
      await _storage.saveToken(token);
      _client.dio.options.headers['Authorization'] = 'Bearer $token';
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _api.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      final data = response.data['data'];
      final token = data['token'] as String?;
      if (token == null) {
        throw ApiException(message: 'No token received');
      }
      await _storage.saveToken(token);
      _client.dio.options.headers['Authorization'] = 'Bearer $token';
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _api.me();
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on DioException {
      // Ignore logout errors — always clear local state
    } finally {
      await _storage.clearAll();
      _client.dio.options.headers.remove('Authorization');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _api.forgotPassword(email);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<bool> hasToken() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> loadTokenIntoClient() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      _client.dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }
    return ApiException(
      message: e.message ?? 'An unexpected error occurred',
      statusCode: e.response?.statusCode,
    );
  }
}
