import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<Response> login({required String email, required String password}) =>
      _client.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      _client.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  Future<Response> me() => _client.get('/auth/me');

  Future<Response> logout() => _client.post('/auth/logout');

  Future<Response> forgotPassword(String email) =>
      _client.post('/auth/forgot-password', data: {'email': email});
}
