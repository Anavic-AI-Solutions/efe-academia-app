import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ProfileApi {
  final ApiClient _client;
  ProfileApi(this._client);

  Future<Response> update({
    required String name,
    required String email,
  }) =>
      _client.patch('/profile', data: {'name': name, 'email': email});

  Future<Response> uploadAvatar(FormData data) => _client.upload(
        '/profile/avatar',
        data,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

  Future<Response> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _client.patch('/profile/password', data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
}
