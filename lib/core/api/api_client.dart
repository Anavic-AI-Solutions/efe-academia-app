import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
    // ignore: avoid_print
    print('[API] Base URL: $baseUrl');

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    dio.interceptors.addAll([
      AuthInterceptor(_storage),
      ErrorInterceptor(),
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        // ignore: avoid_print
        logPrint: (obj) => print('[API] $obj'),
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  /// Descarga binaria (p. ej. el PDF de una factura por URL firmada). Fuerza
  /// `ResponseType.bytes` para no intentar decodificar el cuerpo como JSON.
  Future<Response<List<int>>> getBytes(
    String path, {
    Map<String, String>? headers,
  }) =>
      dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
      );

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);

  Future<Response> upload(String path, FormData data, {Options? options}) =>
      dio.post(path, data: data, options: options);
}
