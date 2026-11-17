import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/profile/data/profile_api.dart';
import 'package:efe_mobile/features/profile/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data, {String path = '/profile'}) =>
    Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );

class _FakeProfileApi implements ProfileApi {
  Response<dynamic>? updateResponse;
  Response<dynamic>? avatarResponse;
  Response<dynamic>? passwordResponse;

  DioException? updateError;

  Map<String, dynamic>? lastUpdate;
  FormData? lastUpload;
  Map<String, dynamic>? lastPassword;

  @override
  Future<Response> update({
    required String name,
    required String email,
  }) async {
    lastUpdate = {'name': name, 'email': email};
    if (updateError != null) throw updateError!;
    return updateResponse!;
  }

  @override
  Future<Response> uploadAvatar(FormData data) async {
    lastUpload = data;
    return avatarResponse!;
  }

  @override
  Future<Response> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    lastPassword = {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    return passwordResponse!;
  }
}

void main() {
  group('ProfileRepository', () {
    test('updateProfile envía name y email y parsea el usuario', () async {
      final api = _FakeProfileApi()
        ..updateResponse = _response({
          'data': {
            'id': 7,
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'avatar_url': 'https://cdn/a.png',
          },
        });
      final repository = ProfileRepository(api);

      final user = await repository.updateProfile(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
      );

      expect(api.lastUpdate, {
        'name': 'Ada Lovelace',
        'email': 'ada@example.com',
      });
      expect(user.id, '7');
      expect(user.name, 'Ada Lovelace');
      expect(user.email, 'ada@example.com');
      expect(user.avatarUrl, 'https://cdn/a.png');
    });

    test('uploadAvatar envía el archivo en el campo avatar y devuelve la URL',
        () async {
      final api = _FakeProfileApi()
        ..avatarResponse = _response(
          {
            'data': {'avatar': 'https://cdn/new.png'},
          },
          path: '/profile/avatar',
        );
      final repository = ProfileRepository(api);

      final url = await repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'photo.png',
      );

      expect(url, 'https://cdn/new.png');
      final form = api.lastUpload!;
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.filename, 'photo.png');
    });

    test('uploadAvatar falla si la API no devuelve URL', () async {
      final api = _FakeProfileApi()
        ..avatarResponse = _response(
          {
            'data': {'avatar': null},
          },
          path: '/profile/avatar',
        );
      final repository = ProfileRepository(api);

      await expectLater(
        () => repository.uploadAvatar(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'photo.png',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('changePassword envía los tres campos', () async {
      final api = _FakeProfileApi()
        ..passwordResponse = _response(
          {'success': true},
          path: '/profile/password',
        );
      final repository = ProfileRepository(api);

      await repository.changePassword(
        currentPassword: 'old-secret',
        password: 'new-secret',
        passwordConfirmation: 'new-secret',
      );

      expect(api.lastPassword, {
        'current_password': 'old-secret',
        'password': 'new-secret',
        'password_confirmation': 'new-secret',
      });
    });

    test('preserva ValidationException al mapear DioException', () async {
      final api = _FakeProfileApi()
        ..updateError = DioException(
          requestOptions: RequestOptions(path: '/profile'),
          error: ValidationException(
            fieldErrors: {'email': 'El email ya está en uso'},
          ),
        );
      final repository = ProfileRepository(api);

      await expectLater(
        () => repository.updateProfile(
          name: 'Ada',
          email: 'dup@example.com',
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors,
            'fieldErrors',
            {'email': 'El email ya está en uso'},
          ),
        ),
      );
    });
  });
}
