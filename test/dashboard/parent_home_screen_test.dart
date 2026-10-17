import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/core/widgets/app_card.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/parent_home_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/parent_home_screen.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _FakeParentAuthRepository implements AuthRepository {
  final String name;

  _FakeParentAuthRepository({this.name = 'María López'});

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: 'u-parent',
        name: name,
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

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardData? data;
  final bool fails;

  _FakeDashboardRepository({this.data, this.fails = false});

  @override
  Future<DashboardData> getDashboard() async {
    if (fails) throw Exception('network error');
    return data ?? const DashboardData(role: 'parent');
  }
}

class _FakeRelationsRepository implements RelationsRepository {
  final List<RelationModel> children;
  final bool fails;

  _FakeRelationsRepository({this.children = const [], this.fails = false});

  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async {
    if (fails) throw Exception('network error');
    return CursorPagination(
      data: children,
      nextCursor: null,
      hasMore: false,
      total: children.length,
    );
  }
}

/// Nunca resuelve: mantiene el home en el estado de carga inicial.
class _PendingDashboardRepository implements DashboardRepository {
  final Completer<DashboardData> completer = Completer<DashboardData>();

  @override
  Future<DashboardData> getDashboard() => completer.future;
}

const _ana = RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11);
const _bruno = RelationModel(id: 'r2', fullname: 'Bruno Pérez', role: 'student', userId: 12);

DashboardData _parentData({
  int overdue = 2,
  List<ParentChildSummary> children = const [
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
    ParentChildSummary(userId: 12, studentId: 's-bruno', name: 'Bruno Pérez'),
  ],
}) =>
    DashboardData(
      role: 'parent',
      parentHome: ParentHomeData(
        overdueFeesCount: overdue,
        moraTotal: 1300000,
        children: children,
      ),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const ParentHomeScreen()),
        GoRoute(
          path: '/students/:id',
          builder: (_, s) => Text('student:${s.pathParameters['id']}'),
          routes: [
            GoRoute(
              path: 'boletin',
              builder: (_, s) => Text('boletin:${s.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(path: '/payments', builder: (_, __) => const Text('payments')),
        GoRoute(path: '/chat', builder: (_, __) => const Text('chat')),
      ],
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  DashboardData? data,
  List<RelationModel> children = const [_ana, _bruno],
  bool relationsFail = false,
  bool dashboardFails = false,
  String parentName = 'María López',
  Brightness brightness = Brightness.light,
}) async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider
        .overrideWithValue(_FakeParentAuthRepository(name: parentName)),
    dashboardRepositoryProvider.overrideWithValue(
        _FakeDashboardRepository(data: data ?? _parentData(), fails: dashboardFails)),
    relationsRepositoryProvider.overrideWithValue(
        _FakeRelationsRepository(children: children, fails: relationsFail)),
    unreadCountProvider.overrideWith((ref) async => 0),
  ]);
  addTearDown(container.dispose);

  final router = _router();
  addTearDown(router.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('es', 'AR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('header shows Hola + Familia <apellido>', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Familia López'), findsOneWidget);
    expect(
      find.byIcon(PhosphorIconsRegular.magnifyingGlass),
      findsNothing,
    );
  });

  testWidgets('shows mora alert with count and total', (tester) async {
    await _pumpHome(tester);
    expect(find.text('2 cuotas vencidas'), findsOneWidget);
    // La expectativa se computa contra el formatter (R9): su salida real para
    // es_AR pospone el símbolo ("1.300.000,00\u00A0$").
    expect(
      find.text('Mora total ${AppFormatters.formatCurrency(1300000)}'),
      findsOneWidget,
    );
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();
    expect(find.text('payments'), findsOneWidget);
  });

  testWidgets('hides the alert when there are no overdue fees', (tester) async {
    await _pumpHome(tester, data: _parentData(overdue: 0));
    expect(find.text('Pagar'), findsNothing);
  });

  testWidgets('renders one card per child with stats and dashes',
      (tester) async {
    await _pumpHome(tester);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Bruno Pérez'), findsOneWidget);
    expect(find.text('7.9'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('3G X · 3° año'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('joins summaries by user id regardless of order',
      (tester) async {
    await _pumpHome(tester, children: const [_bruno, _ana]);
    final anaCard =
        find.ancestor(of: find.text('Ana Pérez'), matching: find.byType(AppCard));
    expect(find.descendant(of: anaCard, matching: find.text('7.9')),
        findsOneWidget);
  });

  testWidgets('degrades when no summary matches any child', (tester) async {
    await _pumpHome(
      tester,
      data: const DashboardData(
        role: 'parent',
        parentHome: ParentHomeData(),
      ),
    );
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Bruno Pérez'), findsOneWidget);
    // Dos tarjetas sin resumen: 2 guiones por tarjeta (Promedio/Asistencia).
    expect(find.text('—'), findsNWidgets(4));
    expect(find.textContaining('·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-token parent name shows without Familia', (tester) async {
    await _pumpHome(tester, parentName: 'Rocío');
    expect(find.text('Rocío'), findsOneWidget);
    expect(find.textContaining('Familia'), findsNothing);
  });

  testWidgets('relations error keeps the alert and shows bounded error',
      (tester) async {
    await _pumpHome(tester, relationsFail: true);
    expect(find.text('No se pudieron cargar los estudiantes'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);
  });

  testWidgets('empty children shows the neutral empty state', (tester) async {
    await _pumpHome(
      tester,
      children: const [],
      data: _parentData(children: const []),
    );
    expect(find.text('No se encontraron estudiantes'), findsOneWidget);
  });

  testWidgets('tapping a child navigates with the student id', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();
    expect(find.text('student:s-ana'), findsOneWidget);
  });

  testWidgets('falls back to the user id when the summary lacks student id',
      (tester) async {
    // Degradación backend viejo: sin `student_id` en el resumen, la ruta usa
    // el `user_id` del vínculo.
    await _pumpHome(
      tester,
      data: const DashboardData(
        role: 'parent',
        parentHome: ParentHomeData(
          children: [
            ParentChildSummary(userId: 11, name: 'Ana Pérez'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();
    expect(find.text('student:11'), findsOneWidget);
  });

  testWidgets('boletin with a single child navigates directly', (tester) async {
    await _pumpHome(tester, children: const [_ana]);
    await tester.tap(find.text('Boletín'));
    await tester.pumpAndSettle();
    expect(find.text('boletin:s-ana'), findsOneWidget);
  });

  testWidgets('boletin with two children asks which one', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Boletín'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí un hijo'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Bruno Pérez'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('boletin:s-bruno'), findsOneWidget);
  });

  testWidgets('chat action opens the chat tab', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets('dashboard failure shows retry error', (tester) async {
    await _pumpHome(tester, dashboardFails: true);
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('shows shimmer cards while the dashboard is loading',
      (tester) async {
    final pending = _PendingDashboardRepository();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      dashboardRepositoryProvider.overrideWithValue(pending),
      relationsRepositoryProvider
          .overrideWithValue(_FakeRelationsRepository(children: const [_ana])),
      unreadCountProvider.overrideWith((ref) async => 0),
    ]);
    addTearDown(container.dispose);

    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();

    expect(find.byType(LoadingShimmer), findsWidgets);

    pending.completer.complete(_parentData());
    await tester.pumpAndSettle();
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a 320px screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpHome(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
