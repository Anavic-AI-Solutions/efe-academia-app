import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'statistics_repository.dart';
import 'statistics_model.dart';

final statisticsRepositoryProvider =
    Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(statisticsApiProvider));
});

final statisticsApiProvider = Provider<StatisticsApi>((ref) {
  return StatisticsApi(ref.watch(apiClientProvider));
});

final statisticsDashboardProvider =
    StateNotifierProvider<StatisticsListNotifier, StatisticsModel>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsListNotifier(repository);
});

class StatisticsListNotifier extends StateNotifier<StatisticsModel> {
  final StatisticsRepository _repository;
  int _requestId = 0;

  StatisticsListNotifier(this._repository) :
      super(StatisticsModel(metrics: {}, details: [], role: 'student'));

  Future<void> load({String? role}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getDashboard(role: role);
      if (requestId != _requestId) return;
      state = result.copyWith(isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  StatisticsModel copyWith({
    StatisticsModel? page,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsModel(
      metrics: page?.metrics ?? metrics,
      details: page?.details ?? details,
      role: page?.role ?? role,
    );
  }

  Map<String, dynamic> get metrics => state.metrics;
  List<dynamic> get details => state.details;
  String get role => state.role;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}