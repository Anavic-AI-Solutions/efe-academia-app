import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _userA = UserModel(
  id: 'u-a',
  name: 'Admin A',
  email: 'a@test.com',
  role: 'admin',
);
const _userB = UserModel(
  id: 'u-b',
  name: 'Profe B',
  email: 'b@test.com',
  role: 'professor',
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => _userA;

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
      Future.value(_userB);

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.value(_userB);

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

class _FakeDashboardRepository implements DashboardRepository {
  final List<DashboardData> responses;
  int calls = 0;

  _FakeDashboardRepository(this.responses);

  @override
  Future<DashboardData> getDashboard() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}

void main() {
  test('dashboard reloads when the authenticated user changes', () async {
    final repository = _FakeDashboardRepository([
      const DashboardData(role: 'admin'),
      const DashboardData(
        role: 'professor',
        totalClassrooms: 1,
        classrooms: [
          ProfessorClassroomSummary(
            id: 'c1',
            name: '3G X',
            studentsCount: 10,
          ),
        ],
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        dashboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(dashboardProvider, (_, __) {});

    await pumpEventQueue();
    expect(container.read(dashboardProvider).data?.role, 'admin');
    expect(container.read(dashboardProvider).data?.classrooms, isEmpty);

    await container.read(authProvider.notifier).login(
          'b@test.com',
          'secret',
        );
    await pumpEventQueue();

    final state = container.read(dashboardProvider);
    expect(repository.calls, 2);
    expect(state.data?.role, 'professor');
    expect(state.data?.classrooms.single.name, '3G X');
  });

  test('dashboard does not fetch without an authenticated user', () async {
    final repository = _FakeDashboardRepository([
      const DashboardData(role: 'admin'),
    ]);
    final notifier = DashboardNotifier(repository, enabled: false);

    await pumpEventQueue();

    expect(repository.calls, 0);
    expect(notifier.state.data, isNull);
    expect(notifier.state.isLoading, isFalse);
    notifier.dispose();
  });
}
