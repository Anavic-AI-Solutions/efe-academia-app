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
    StateNotifierProvider<StatisticsListNotifier, StatisticsState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsListNotifier(repository);
});

class StatisticsState {
  final StatisticsModel data;
  final bool isLoading;
  final String? error;

  const StatisticsState({
    required this.data,
    this.isLoading = false,
    this.error,
  });

  StatisticsState copyWith({
    StatisticsModel? data,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StatisticsListNotifier extends StateNotifier<StatisticsState> {
  final StatisticsRepository _repository;
  int _requestId = 0;

  StatisticsListNotifier(this._repository)
      : super(const StatisticsState(
            data: StatisticsModel(metrics: {}, details: [], role: 'student')));

  Future<void> load({String? role}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getDashboard(role: role);
      if (requestId != _requestId) return;
      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Map<String, dynamic> get metrics => state.data.metrics;
  List<dynamic> get details => state.data.details;
  String get role => state.data.role;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}
