import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1',
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
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);

  Future<Response> upload(String path, FormData data) =>
      dio.post(path, data: data);
}
