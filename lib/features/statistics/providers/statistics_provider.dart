import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../data/statistics_api.dart';
import '../data/statistics_repository.dart';
import '../domain/statistics_model.dart';

final statisticsApiProvider = Provider<StatisticsApi>((ref) {
  return StatisticsApi(ref.watch(apiClientProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(statisticsApiProvider));
});

final statisticsDashboardProvider =
    StateNotifierProvider.autoDispose<StatisticsListNotifier, StatisticsState>(
  (ref) => StatisticsListNotifier(ref.watch(statisticsRepositoryProvider)),
);

class StatisticsState {
  final StatisticsModel data;
  final bool isLoading;
  final bool hasLoaded;
  final String? error;

  StatisticsState({
    required this.data,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

  StatisticsState copyWith({
    StatisticsModel? data,
    bool? isLoading,
    bool? hasLoaded,
    String? error,
    bool clearError = false,
  }) {
    return StatisticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StatisticsListNotifier extends StateNotifier<StatisticsState> {
  final StatisticsRepository _repository;
  int _requestId = 0;

  StatisticsListNotifier(this._repository)
      : super(StatisticsState(data: StatisticsModel.empty()));

  Future<void> load() async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getDashboard();
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        data: result,
        isLoading: false,
        hasLoaded: true,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: e.toString(),
      );
    }
  }
}
