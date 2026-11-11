import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardApiProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
    bool clearData = false,
  }) {
    return DashboardState(
      data: clearData ? null : (data ?? this.data),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository, {bool enabled = true})
      : super(const DashboardState()) {
    if (enabled) {
      loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getDashboard();
      if (!mounted) return;
      print(
        '[Dashboard] SUCCESS students=${data.totalStudents} '
        'classrooms=${data.totalClassrooms} attendance=${data.attendanceRate} '
        'pendingFees=${data.pendingFees}',
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      print('[Dashboard] ERROR: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadDashboard();
}

/// Dashboard data is user-scoped: rebuild it whenever the authenticated user
/// changes (login, logout, account switch) so a new session never renders the
/// previous user's classrooms/metrics.
final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  return DashboardNotifier(
    ref.watch(dashboardRepositoryProvider),
    enabled: userId != null,
  );
});
