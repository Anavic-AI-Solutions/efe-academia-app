import '../domain/dashboard_data.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  final DashboardApi _api;

  DashboardRepository(this._api);

  Future<DashboardData> getDashboard() async {
    final response = await _api.getDashboard();
    final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
    return DashboardData.fromJson(data as Map<String, dynamic>);
  }
}
