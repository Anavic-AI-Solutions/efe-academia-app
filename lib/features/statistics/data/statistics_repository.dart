import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/statistics_api.dart';
import '../domain/statistics_model.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

class StatisticsRepository {
  final StatisticsApi _api;
  StatisticsRepository(this._api);

  Future<StatisticsModel> getDashboard({String? role}) async {
    final response = await _api.getDashboard();

    final metrics = response.data['metrics'] as Map<String, dynamic>;
    final details = response.data['details'] as List<dynamic>;

    return StatisticsModel.fromJson(metrics, details, role ?? 'student');
  }
}