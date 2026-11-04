import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/statistics_model.dart';

class StatisticsApi {
  final ApiClient _client;
  StatisticsApi(this._client);

  Future<Response> getDashboard() => _client.get('/statistics/dashboard');
}