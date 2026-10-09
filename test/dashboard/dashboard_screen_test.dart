import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/widgets/header_stats_row.dart';
import 'package:efe_mobile/core/widgets/home_header.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/professor_classroom_summary.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeParentAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u-parent',
        name: 'María López',
        email: 'maria@test.com',
        role: 'parent',
      );

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
      getCurrentUser();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      getCurrentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

const _parentData = DashboardData(
  role: 'parent',
  totalStudents: 2,
  totalClassrooms: 2,
  pendingFees: 1,
  classrooms: [
    ProfessorClassroomSummary(
      id: 'c1',
      name: '3G X · 2026',
      studentsCount: 24,
    ),
    ProfessorClassroomSummary(
      id: 'c2',
      name: '1G X · 2026',
      studentsCount: 30,
    ),
  ],
);

class _FakeParentDashboardRepository implements DashboardRepository {
  final DashboardData data;

  const _FakeParentDashboardRepository([this.data = _parentData]);

  @override
  Future<DashboardData> getDashboard() async => data;
}

class _FakeEmptyRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination.empty();
}

Future<void> _pumpParentHome(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  DashboardData data = _parentData,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      dashboardRepositoryProvider
          .overrideWithValue(_FakeParentDashboardRepository(data)),
      relationsRepositoryProvider
          .overrideWithValue(_FakeEmptyRelationsRepository()),
      unreadCountProvider.overrideWith((ref) async => 0),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('parent home uses the unified header system', (tester) async {
    await _pumpParentHome(tester);
    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.byType(HeaderStatsRow), findsOneWidget);
    // section label en versalitas del sistema
    final label = tester.widget<Text>(find.text('CLASES'));
    expect(label.style?.color, AppColors.sectionLabel);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('parent home renders in dark mode', (tester) async {
    await _pumpParentHome(tester, brightness: Brightness.dark);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.darkBackground);
  });

  testWidgets('parent home keeps the parent role badge palette', (tester) async {
    await _pumpParentHome(tester);
    final badge = tester.widget<Text>(find.text('Tutor'));
    expect(badge.style?.color, AppColors.roleParent);
  });

  testWidgets('parent home holds a single column at 320x568', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpParentHome(tester);

    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.text('3G X · 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent home empty classrooms uses neutral copy', (tester) async {
    await _pumpParentHome(
      tester,
      data: const DashboardData(role: 'parent'),
    );

    expect(find.text('CLASES'), findsOneWidget);
    expect(find.text('No se encontraron clases'), findsOneWidget);
    expect(find.text('No hay clases disponibles'), findsOneWidget);
  });
}
