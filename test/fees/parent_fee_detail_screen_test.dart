import 'dart:async';

import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/parent_fee_detail_screen.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_proof_sheet.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// URL firmada que devuelve el repo falso en los tests de factura.
const _invoiceUrl = 'https://efe.test/fees/f1/invoice-file?signature=abc123';

/// Repositorio de cuotas falso: cuenta llamadas de detalle/lista, puede fallar
/// la primera lectura del detalle y puede quedar pendiente para el estado de
/// carga.
class _FakeFeeRepository implements FeeRepository {
  _FakeFeeRepository({
    FeeModel? fee,
    this.failFirst = false,
    this.pending = false,
  }) : fee = fee ?? _fee();

  final FeeModel fee;
  final bool failFirst;
  final bool pending;

  final pendingCompleter = Completer<FeeModel>();
  int getFeeCalls = 0;
  int getFeesCalls = 0;

  @override
  Future<FeeModel> getFee(String id) async {
    getFeeCalls++;
    if (pending) return pendingCompleter.future;
    if (failFirst && getFeeCalls == 1) {
      throw ApiException(message: 'network error', statusCode: 500);
    }
    return fee;
  }

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    getFeesCalls++;
    return CursorPagination.empty();
  }

  @override
  Future<String> getInvoiceUrl(String feeId) async => _invoiceUrl;

  @override
  Future<Never> getInvoiceFile(String feeId) => throw UnimplementedError();

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();
}

/// Cuota de prueba; por defecto, pendiente de julio 2026 de Ana Pérez.
FeeModel _fee({
  String id = 'f1',
  int numberFee = 3,
  String status = 'pending',
  String proofStatus = '',
  double toPay = 25000,
  double paid = 0,
  double total = 25000,
  double owe = 0,
  String paymentMethod = '',
  String paymentDate = '',
}) =>
    FeeModel(
      id: id,
      studentName: 'Ana Pérez',
      numberFee: numberFee,
      month: '7',
      year: '2026',
      toPay: toPay,
      paid: paid,
      total: total,
      status: status,
      proofStatus: proofStatus,
      owe: owe,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
    );

/// Pumpea la pantalla con el provider de detalle overridado y mantiene vivo
/// `parentFeesProvider` (para verificar su invalidación tras subir).
Future<_FakeFeeRepository> _pumpScreen(
  WidgetTester tester, {
  _FakeFeeRepository? repo,
  VoidCallback? onViewInvoice,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  final fakeRepo = repo ?? _FakeFeeRepository();
  final container = ProviderContainer(overrides: [
    feeRepositoryProvider.overrideWithValue(fakeRepo),
  ]);
  addTearDown(container.dispose);
  final subscription = container.listen(parentFeesProvider, (_, __) {});
  addTearDown(subscription.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        home: ParentFeeDetailScreen(
          feeId: 'f1',
          onViewInvoice: onViewInvoice,
        ),
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

  group('cuota pendiente', () {
    testWidgets('muestra filas, estado y la acción Subir comprobante',
        (tester) async {
      await _pumpScreen(tester);

      // Título con el número de cuota y filas de identidad.
      expect(find.text(es.feesDetailTitle(3)), findsOneWidget);
      expect(find.text(es.roleStudent), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text(es.feesDetailMonth), findsOneWidget);
      expect(find.text('Julio 2026'), findsOneWidget);

      // Estado con badge, sin monto duplicado (los montos van en sus filas).
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(es.feesStatusPending),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('${es.feesStatusPending} · '), findsNothing);

      // Montos a pagar / pagado / total.
      expect(find.text(es.feesDetailToPay), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(25000)), findsNWidgets(2));
      expect(find.text(es.feesDetailPaid), findsOneWidget);
      expect(find.text(AppFormatters.formatCurrency(0)), findsOneWidget);
      expect(find.text(es.feesDetailTotal), findsOneWidget);

      // Acciones: subir visible; factura y reemplazo no.
      expect(find.text(es.feesUploadProofAction), findsOneWidget);
      expect(find.text(es.feesReplaceProofAction), findsNothing);
      expect(find.text(es.feesInvoiceAction), findsNothing);
    });

    testWidgets('muestra el debe solo cuando owe > 0', (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(
          fee: _fee(status: 'partial', paid: 10000, owe: 15000),
        ),
      );

      expect(
        find.text(es.feesPartialOwed(AppFormatters.formatCurrency(15000))),
        findsOneWidget,
      );

      await _pumpScreen(tester);

      expect(find.textContaining('debe '), findsNothing);
    });
  });

  group('comprobante en revisión', () {
    testWidgets('proof_status under_review → Reemplazar y fila de revisión',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(fee: _fee(proofStatus: 'under_review')),
      );

      expect(find.text(es.feesProofStatusReview), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(es.feesStatusUnderReview),
        ),
        findsOneWidget,
      );
      // Light: el estado en revisión usa el azul primary (5.2:1).
      expect(
        tester.widget<Text>(find.text(es.feesProofStatusReview)).style?.color,
        AppColors.primary,
      );
      expect(
        tester.widget<StatusBadge>(find.byType(StatusBadge)).color,
        AppColors.primary,
      );
      expect(find.text(es.feesReplaceProofAction), findsOneWidget);
      expect(find.text(es.feesUploadProofAction), findsNothing);
      expect(find.text(es.feesInvoiceAction), findsNothing);
    });

    testWidgets('status under_review → Reemplazar y fila de revisión',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(fee: _fee(status: 'under_review')),
      );

      expect(find.text(es.feesProofStatusReview), findsOneWidget);
      // En revisión (por cualquiera de las dos fuentes) mantiene Reemplazar.
      expect(find.text(es.feesReplaceProofAction), findsOneWidget);
      expect(find.text(es.feesUploadProofAction), findsNothing);
    });

    testWidgets('en dark la fila de revisión y el badge usan el token accent',
        (tester) async {
      await _pumpScreen(
        tester,
        brightness: Brightness.dark,
        repo: _FakeFeeRepository(fee: _fee(proofStatus: 'under_review')),
      );

      // Dark: accent (7.6:1) en vez de primary (2.7:1) — contrato R15.
      expect(
        tester.widget<Text>(find.text(es.feesProofStatusReview)).style?.color,
        AppColors.accent,
      );
      expect(
        tester.widget<StatusBadge>(find.byType(StatusBadge)).color,
        AppColors.accent,
      );
    });

    testWidgets('tap Reemplazar comprobante abre el sheet de la cuota',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(fee: _fee(proofStatus: 'under_review')),
      );

      await tester.tap(
        find.widgetWithText(PillButton, es.feesReplaceProofAction),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParentFeeProofSheet), findsOneWidget);
      // Título y botón submit del sheet usan la clave de reemplazo (2 textos).
      expect(
        find.descendant(
          of: find.byType(ParentFeeProofSheet),
          matching: find.text(es.feesReplaceProofAction),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.byType(ParentFeeProofSheet),
          matching: find.widgetWithText(PillButton, es.feesReplaceProofAction),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ParentFeeProofSheet),
          matching: find.textContaining('Ana Pérez'),
        ),
        findsOneWidget,
      );
    });
  });

  group('cuota no accionable', () {
    testWidgets('cancelled → sin botón de subir, reemplazar ni factura',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(fee: _fee(status: 'cancelled')),
      );

      expect(find.byType(PillButton), findsNothing);
      expect(find.text(es.feesUploadProofAction), findsNothing);
      expect(find.text(es.feesReplaceProofAction), findsNothing);
      expect(find.text(es.feesInvoiceAction), findsNothing);
    });
  });

  group('cuota pagada y factura', () {
    testWidgets('muestra Ver factura con método/fecha y oculta subir',
        (tester) async {
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(
          fee: _fee(
            status: 'paid',
            paid: 25000,
            paymentMethod: 'Transferencia',
            paymentDate: '2026-07-10',
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text(es.feesStatusPaid),
        ),
        findsOneWidget,
      );
      // A pagar / pagado / total (mismos 25.000 en una cuota saldada).
      expect(find.text(AppFormatters.formatCurrency(25000)), findsNWidgets(3));
      expect(find.text(es.feesDetailPaymentMethod), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);
      expect(find.text(es.feesDetailPaymentDate), findsOneWidget);
      expect(find.text('2026-07-10'), findsOneWidget);

      expect(
        find.widgetWithText(PillButton, es.feesInvoiceAction),
        findsOneWidget,
      );
      expect(find.text(es.feesUploadProofAction), findsNothing);
      expect(find.text(es.feesReplaceProofAction), findsNothing);
    });

    testWidgets('tap Ver factura navega al visor de la factura',
        (tester) async {
      var navigated = 0;
      await _pumpScreen(
        tester,
        repo: _FakeFeeRepository(fee: _fee(status: 'paid', paid: 25000)),
        onViewInvoice: () => navigated++,
      );

      await tester.tap(find.widgetWithText(PillButton, es.feesInvoiceAction));
      await tester.pumpAndSettle();

      expect(navigated, 1);
      expect(find.text(es.feesInvoiceUnavailable), findsNothing);
    });
  });

  group('subida de comprobante', () {
    testWidgets('pop(true) → snackbar e invalida detalle y lista',
        (tester) async {
      final repo = await _pumpScreen(tester);
      expect(repo.getFeeCalls, 1);
      expect(repo.getFeesCalls, 1);

      await tester.tap(
        find.widgetWithText(PillButton, es.feesUploadProofAction),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ParentFeeProofSheet), findsOneWidget);

      // La subida exitosa del sheet cierra con pop(true).
      Navigator.of(tester.element(find.byType(ParentFeeProofSheet))).pop(true);
      await tester.pumpAndSettle();

      expect(find.byType(ParentFeeProofSheet), findsNothing);
      expect(find.text(es.feesProofSuccess), findsOneWidget);
      // Detalle invalidado → el repo vuelve a pedirse; la lista también.
      expect(repo.getFeeCalls, 2);
      expect(repo.getFeesCalls, 2);
    });
  });

  group('estados del detalle', () {
    testWidgets('loading → shimmer y título fallback', (tester) async {
      final repo = _FakeFeeRepository(pending: true);
      await _pumpScreen(tester, repo: repo, settle: false);

      expect(find.text(es.feesDetailFallbackTitle), findsOneWidget);
      expect(find.byType(ListShimmer), findsOneWidget);
      expect(find.byType(PillButton), findsNothing);

      repo.pendingCompleter.complete(_fee());
      await tester.pumpAndSettle();

      expect(find.text(es.feesDetailTitle(3)), findsOneWidget);
      expect(find.byType(ListShimmer), findsNothing);
    });

    testWidgets('error → ErrorView y el retry vuelve a pedir la cuota',
        (tester) async {
      final repo = _FakeFeeRepository(failFirst: true);
      await _pumpScreen(tester, repo: repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(es.feesDetailLoadError), findsOneWidget);
      expect(find.byType(PillButton), findsNothing);

      await tester.tap(find.text(es.commonRetry));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(repo.getFeeCalls, 2);
    });
  });

  testWidgets('dark mode renderiza sin excepciones', (tester) async {
    await _pumpScreen(
      tester,
      brightness: Brightness.dark,
      repo: _FakeFeeRepository(
        fee: _fee(
          status: 'paid',
          paid: 25000,
          paymentMethod: 'Transferencia',
          paymentDate: '2026-07-10',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(PillButton, es.feesInvoiceAction),
      findsOneWidget,
    );
  });
}
