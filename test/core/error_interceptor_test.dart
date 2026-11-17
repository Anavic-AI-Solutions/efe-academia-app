import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/interceptors/error_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('maps Laravel validation errors to field errors', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = _JsonAdapter(422, {
      'message': 'The given data was invalid.',
      'errors': {
        'email': ['The email has already been taken.'],
        'password': ['The password field is required.'],
      },
    });
    dio.interceptors.add(ErrorInterceptor());

    try {
      await dio.patch('/profile', data: {});
      fail('should throw');
    } on DioException catch (e) {
      final error = e.error;
      expect(error, isA<ValidationException>());
      final validation = error as ValidationException;
      expect(
        validation.fieldErrors['email'],
        'The email has already been taken.',
      );
      expect(validation.detail, 'The email has already been taken.');
    }
  });

  test('keeps JSON:API list validation errors working', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = _JsonAdapter(422, {
      'errors': [
        {
          'source': {'pointer': '/data/attributes/email'},
          'detail': 'Email inválido.',
        },
      ],
    });
    dio.interceptors.add(ErrorInterceptor());

    try {
      await dio.patch('/profile', data: {});
      fail('should throw');
    } on DioException catch (e) {
      final validation = e.error as ValidationException;
      expect(validation.fieldErrors['email'], 'Email inválido.');
      expect(validation.detail, 'Email inválido.');
    }
  });
}
