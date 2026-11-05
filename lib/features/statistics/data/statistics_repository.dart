import '../data/statistics_api.dart';
import '../domain/statistics_model.dart';

class StatisticsRepository {
  final StatisticsApi _api;
  StatisticsRepository(this._api);

  Future<StatisticsModel> getDashboard() async {
    final response = await _api.getDashboard();
    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final payload = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    return StatisticsModel.fromJson(payload);
  }
}
