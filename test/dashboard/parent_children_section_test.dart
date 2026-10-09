import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/parent_children_section.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

class _FakeParentDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboard() async =>
      const DashboardData(role: 'parent');
}

class _FakeRelationsRepository implements RelationsRepository {
  final List<RelationModel> children;
  final bool shouldFail;

  _FakeRelationsRepository({this.children = const [], this.shouldFail = false});

  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async {
    if (shouldFail) throw Exception('network error');
    return CursorPagination(
      data: children,
      nextCursor: null,
      hasMore: false,
      total: children.length,
    );
  }
}

const _ana = RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11);
const _bruno = RelationModel(id: 'r2', fullname: 'Bruno Pérez', role: 'student', userId: 12);

Future<void> _pumpSection(
  WidgetTester tester, {
  List<RelationModel> children = const [_ana, _bruno],
  bool shouldFail = false,
  void Function(RelationModel child)? onSelect,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      relationsRepositoryProvider.overrideWithValue(
        _FakeRelationsRepository(children: children, shouldFail: shouldFail),
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
        home: Scaffold(
          body: ParentChildrenSection(onSelect: onSelect ?? (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpParentHome(
  WidgetTester tester, {
  List<RelationModel> children = const [_ana],
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      dashboardRepositoryProvider
          .overrideWithValue(_FakeParentDashboardRepository()),
      relationsRepositoryProvider.overrideWithValue(
        _FakeRelationsRepository(children: children),
      ),
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
        home: const DashboardScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('parent section lists children from relations', (tester) async {
    await _pumpSection(tester);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Bruno Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a child calls onSelect with that child',
      (tester) async {
    RelationModel? selected;
    await _pumpSection(tester, onSelect: (c) => selected = c);
    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();
    expect(selected?.fullname, 'Ana Pérez');
    expect(selected?.userId, 11);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent section empty shows neutral copy', (tester) async {
    await _pumpSection(tester, children: const []);
    expect(find.text('No se encontraron estudiantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent section error shows retry', (tester) async {
    await _pumpSection(tester, shouldFail: true);
    expect(find.text('No se pudieron cargar los estudiantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent home shows children section', (tester) async {
    await _pumpParentHome(tester);
    expect(find.byType(ParentChildrenSection), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a child on parent home navigates to student detail route',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
        dashboardRepositoryProvider
            .overrideWithValue(_FakeParentDashboardRepository()),
        relationsRepositoryProvider.overrideWithValue(
          _FakeRelationsRepository(children: const [_ana]),
        ),
        unreadCountProvider.overrideWith((ref) async => 0),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/students/:id',
          builder: (context, state) => Scaffold(
            body: Text('student:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();

    expect(find.text('student:11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
