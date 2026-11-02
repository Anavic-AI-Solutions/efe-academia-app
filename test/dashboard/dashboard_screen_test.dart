import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/widgets/header_stats_row.dart';
import 'package:efe_mobile/core/widgets/home_header.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/parent_home_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:efe_mobile/features/dashboard/screens/parent_home_screen.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
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
  parentHome: ParentHomeData(
    overdueFeesCount: 2,
    moraTotal: 1300000,
    children: [
      ParentChildSummary(
        userId: 11,
        studentId: 's-ana',
        name: 'Ana Pérez',
        classroomName: '3G X',
        classroomsCount: 1,
        year: '3',
        averageGrade: 7.9,
        attendanceRate: 95.0,
      ),
    ],
  ),
);

class _FakeParentDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboard() async => _parentData;
}

class _FakeRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination(
        data: const [
          RelationModel(
              id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11),
        ],
        nextCursor: null,
        hasMore: false,
        total: 1,
      );
}

class _FakeNewsRepository implements NewsRepository {
  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination(data: const [], hasMore: false);
}

Future<void> _pumpParentHome(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      dashboardRepositoryProvider
          .overrideWithValue(_FakeParentDashboardRepository()),
      relationsRepositoryProvider.overrideWithValue(_FakeRelationsRepository()),
      unreadCountProvider.overrideWith((ref) async => 0),
      homeDocumentsProvider.overrideWith((ref) async => const []),
      homeCalendarProvider.overrideWith((ref) async => const []),
      newsListProvider.overrideWith(
        (ref) => NewsListNotifier(_FakeNewsRepository()),
      ),
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
  testWidgets('parent delegates to ParentHomeScreen', (tester) async {
    await _pumpParentHome(tester);
    expect(find.byType(ParentHomeScreen), findsOneWidget);
    expect(find.byType(HomeHeader), findsOneWidget);
    // El padre ya no usa la fila de métricas genérica.
    expect(find.byType(HeaderStatsRow), findsNothing);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent home renders in dark mode', (tester) async {
    await _pumpParentHome(tester, brightness: Brightness.dark);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.darkBackground);
  });

  testWidgets('parent home holds a single column at 320x568', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpParentHome(tester);

    expect(find.byType(ParentHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
