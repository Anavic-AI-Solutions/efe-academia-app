import '../../../core/api/api_client.dart';

class DashboardApi {
  final ApiClient _client;

  DashboardApi(this._client);

  Future<dynamic> getDashboard() => _client.get('/statistics/dashboard');
}
