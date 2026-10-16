import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/domain/parent_home_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/parent_fees_screen.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_card.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_proof_sheet.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
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

/// Dashboard falso: mora configurable (null ⇒ sin `parentHome`) y contador
/// de llamadas para verificar el pull-to-refresh.
class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository({this.moraTotal = 1300000});

  final double? moraTotal;
  int calls = 0;

  @override
  Future<DashboardData> getDashboard() async {
    calls++;
    return DashboardData(
      role: 'parent',
      parentHome:
          moraTotal == null ? null : ParentHomeData(moraTotal: moraTotal!),
    );
  }
}

/// Repositorio de cuotas falso: responde las páginas en orden (la última se
/// repite), puede fallar la primera llamada y puede quedar pendiente para el
/// estado de carga.
class _FakeFeeRepository implements FeeRepository {
  _FakeFeeRepository({
    List<CursorPagination<FeeModel>>? responses,
    this.failFirst = false,
    this.pending = false,
  }) : responses = responses ?? [];

  final List<CursorPagination<FeeModel>> responses;
  final bool failFirst;
  final bool pending;
  final pendingCompleter = Completer<CursorPagination<FeeModel>>();
  int calls = 0;
  int uploadCalls = 0;
  Map<String, dynamic>? lastQuery;

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    calls++;
    lastQuery = {'studentId': studentId, 'search': search, 'cursor': cursor};
    if (pending) return pendingCompleter.future;
    if (failFirst && calls == 1) throw Exception('network error');
    if (responses.isEmpty) return CursorPagination.empty();
    if (responses.length == 1) return responses.first;
    return responses.removeAt(0);
  }

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) async {
    uploadCalls++;
  }

  @override
  Future<FeeModel> getFee(String id) => throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> getInvoiceUrl(String feeId) => throw UnimplementedError();
}

/// Cuota de prueba; por defecto, pendiente de julio 2026 de Ana Pérez.
FeeModel _fee({
  required String id,
  String status = 'pending',
  String proofStatus = '',
  bool isOverdue = false,
  double toPay = 25000,
  double owe = 0,
  String studentName = 'Ana Pérez',
  String month = '7',
  String year = '2026',
}) =>
    FeeModel(
      id: id,
      studentName: studentName,
      month: month,
      year: year,
      toPay: toPay,
      total: toPay,
      status: status,
      proofStatus: proofStatus,
      isOverdue: isOverdue,
      owe: owe,
    );

CursorPagination<FeeModel> _page(
  List<FeeModel> data, {
  String? nextCursor,
  bool hasMore = false,
}) =>
    CursorPagination(
      data: data,
      nextCursor: nextCursor,
      hasMore: hasMore,
      total: data.length,
    );

/// Pumpea la pantalla con GoRouter plano (dummy `/payments/:id`).
Future<_FakeFeeRepository> _pumpScreen(
  WidgetTester tester, {
  _FakeFeeRepository? repo,
  _FakeDashboardRepository? dashboard,
  double? moraTotal = 1300000,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  final fakeRepo = repo ??
      _FakeFeeRepository(responses: [
        _page([_fee(id: 'f1')])
      ]);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    feeRepositoryProvider.overrideWithValue(fakeRepo),
    dashboardRepositoryProvider.overrideWithValue(
      dashboard ?? _FakeDashboardRepository(moraTotal: moraTotal),
    ),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/payments',
    routes: [
      GoRoute(path: '/payments', builder: (_, __) => const ParentFeesScreen()),
      GoRoute(
        path: '/payments/:id',
        builder: (_, state) => Text('fee:${state.pathParameters['id']}'),
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
        theme: ThemeData(brightness: brightness),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return fakeRepo;
}

void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es', 'AR'));
  });

  group('header de mora', () {
    testWidgets('muestra título y mora total del dashboard', (tester) async {
      await _pumpScreen(tester, moraTotal: 1300000);

      expect(find.text(es.feesTitle), findsOneWidget);
      expect(find.text(es.parentMoraTotal), findsOneWidget);
      expect(
        find.text(AppFormatters.formatCurrency(1300000)),
        findsOneWidget,
      );
    });

    testWidgets('oculta el tile con mora 0 o sin dato', (tester) async {
      await _pumpScreen(tester, moraTotal: 0);
      expect(find.text(es.parentMoraTotal), findsNothing);

      await _pumpScreen(tester, moraTotal: null);
      expect(find.text(es.parentMoraTotal), findsNothing);
    });
  });

  group('lista de cuotas', () {
    testWidgets('renderiza las cards en el orden del provider y sin filtros',
        (tester) async {
      final repo = await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([
            _fee(id: 'f-vencida', isOverdue: true),
            _fee(id: 'f-pendiente', studentName: 'Bruno Pérez'),
            _fee(id: 'f-pagada', status: 'paid'),
          ]),
        ]),
      );

      final ids = tester
          .widgetList<ParentFeeCard>(find.byType(ParentFeeCard))
          .map((card) => card.fee.id)
          .toList();
      expect(ids, ['f-vencida', 'f-pendiente', 'f-pagada']);
      // `parentFeesProvider` es el mismo notifier sin hijo ni búsqueda.
      expect(repo.lastQuery?['studentId'], isNull);
      expect(repo.lastQuery?['search'], isEmpty);
    });

    testWidgets('carga la página siguiente al scrollear', (tester) async {
      final repo = await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page(
            List.generate(10, (i) => _fee(id: 'f$i')),
            nextCursor: 'c1',
            hasMore: true,
          ),
          _page([_fee(id: 'f-extra', studentName: 'Extra Niño')]),
        ]),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(repo.lastQuery?['cursor'], 'c1');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Extra Niño'), findsOneWidget);
    });
  });

  group('navegación al detalle', () {
    testWidgets('tap en la card navega a /payments/:id', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(
          responses: [
            _page([_fee(id: 'f1', isOverdue: true)])
          ],
        ),
      );

      await tester.tap(find.byType(ParentFeeCard));
      await tester.pumpAndSettle();
      expect(find.text('fee:f1'), findsOneWidget);
    });

    testWidgets('tap en el pill Pagar navega a /payments/:id', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([_fee(id: 'f2')])
        ]),
      );

      await tester.tap(find.text(es.parentPayAction));
      await tester.pumpAndSettle();
      expect(find.text('fee:f2'), findsOneWidget);
    });
  });

  group('CTA de subida de comprobante', () {
    testWidgets(
        'con 1 accionable abre el sheet directo y al pop(true) refresca',
        (tester) async {
      final repo = await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([_fee(id: 'f1')])
        ]),
      );

      await tester
          .tap(find.widgetWithText(PillButton, es.feesUploadProofAction));
      await tester.pumpAndSettle();

      expect(find.byType(ParentFeeProofSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ParentFeeProofSheet),
          matching: find.textContaining('Ana Pérez'),
        ),
        findsOneWidget,
      );

      // La subida exitosa del sheet cierra con pop(true).
      Navigator.of(tester.element(find.byType(ParentFeeProofSheet))).pop(true);
      await tester.pumpAndSettle();

      expect(find.byType(ParentFeeProofSheet), findsNothing);
      expect(find.text(es.feesProofSuccess), findsOneWidget);
      expect(repo.calls, 2);
    });

    testWidgets('con 2+ accionables abre el selector y luego el sheet elegido',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([
            _fee(id: 'f1', isOverdue: true, studentName: 'Ana Pérez'),
            _fee(id: 'f2', studentName: 'Bruno Pérez'),
            _fee(id: 'f3', status: 'paid', studentName: 'Ana Pérez'),
          ]),
        ]),
      );

      await tester
          .tap(find.widgetWithText(PillButton, es.feesUploadProofAction));
      await tester.pumpAndSettle();

      // Selector: una fila por cuota accionable con hijo · mes/año · monto.
      expect(find.text(es.feesChooseFeeTitle), findsOneWidget);
      expect(find.byType(ParentFeeProofSheet), findsNothing);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Julio 2026')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(AppFormatters.formatCurrency(25000)),
        ),
        findsNWidgets(2),
      );

      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Bruno Pérez')),
      );
      await tester.pumpAndSettle();

      expect(find.text(es.feesChooseFeeTitle), findsNothing);
      expect(find.byType(ParentFeeProofSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ParentFeeProofSheet),
          matching: find.textContaining('Bruno Pérez'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin accionables oculta el CTA', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([
            _fee(id: 'f1', status: 'paid'),
            _fee(id: 'f2', proofStatus: 'under_review'),
            _fee(id: 'f3', status: 'under_review'),
          ]),
        ]),
      );

      expect(find.text(es.feesUploadProofAction), findsNothing);
      expect(find.byType(PillButton), findsNothing);
    });
  });

  group('estados de la lista', () {
    testWidgets('vacío muestra EmptyState', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [_page([])]),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(es.feesEmptyTitle), findsOneWidget);
    });

    testWidgets('error muestra ErrorView y el retry recarga', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(
          responses: [
            _page([_fee(id: 'f1')])
          ],
          failFirst: true,
        ),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(es.feesLoadError), findsOneWidget);

      await tester.tap(find.text(es.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byType(ParentFeeCard), findsOneWidget);
    });

    testWidgets('loading muestra 3 shimmer', (tester) async {
      final repo = _FakeFeeRepository(pending: true);
      await _pumpScreen(tester, repo: repo, settle: false);

      expect(find.byType(LoadingShimmer), findsNWidgets(3));

      repo.pendingCompleter.complete(_page([_fee(id: 'f1')]));
      await tester.pumpAndSettle();
      expect(find.byType(ParentFeeCard), findsOneWidget);
    });

    testWidgets('pull-to-refresh refresca cuotas y dashboard', (tester) async {
      final dashboard = _FakeDashboardRepository();
      final repo = await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(responses: [
          _page([_fee(id: 'f1')])
        ]),
        dashboard: dashboard,
      );
      expect(repo.calls, 1);
      expect(dashboard.calls, 1);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(repo.calls, 2);
      expect(dashboard.calls, 2);
    });
  });

  testWidgets('dark mode renderiza sin excepciones', (tester) async {
    await _pumpScreen(
      tester,
      brightness: Brightness.dark,
      repo: _FakeFeeRepository(responses: [
        _page([
          _fee(id: 'f1', isOverdue: true),
          _fee(id: 'f2', status: 'paid'),
        ]),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ParentFeeCard), findsNWidgets(2));
    expect(find.text(es.parentMoraTotal), findsOneWidget);
  });
}
