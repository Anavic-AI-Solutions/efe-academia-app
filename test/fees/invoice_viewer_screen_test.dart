import 'dart:async';
import 'dart:typed_data';

import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/data/invoice_saver.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/domain/invoice_file.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/invoice_viewer_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _fee = FeeModel(
  id: 'f1',
  studentName: 'Ana Pérez',
  numberFee: 3,
  month: '7',
  year: '2026',
  toPay: 25000,
  total: 25000,
  status: 'paid',
);

/// Repo falso: el visor solo usa getInvoiceFile (bytes) y getFee (subtítulo).
class _FakeFeeRepository implements FeeRepository {
  _FakeFeeRepository({this.error, this.pending = false});

  final Object? error;
  final bool pending;
  final pendingFile = Completer<InvoiceFile>();
  int invoiceFileCalls = 0;

  @override
  Future<InvoiceFile> getInvoiceFile(String feeId) {
    invoiceFileCalls++;
    final error = this.error;
    if (error != null) return Future.error(error);
    if (pending) return pendingFile.future;
    return Future.value(
      InvoiceFile(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        url: 'https://x/fees/f1/invoice-file?signature=abc',
      ),
    );
  }

  @override
  Future<FeeModel> getFee(String id) async => _fee;

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> getInvoiceUrl(String feeId) => throw UnimplementedError();

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      throw UnimplementedError();
}

/// Builder inyectable: evita cargar PDFium nativo en los widget tests.
Widget _fakePdf(Uint8List bytes) => Text('PDF ${bytes.length}');

Future<_FakeFeeRepository> _pumpScreen(
  WidgetTester tester, {
  _FakeFeeRepository? repo,
  InvoiceSaver? saver,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  final fakeRepo = repo ?? _FakeFeeRepository();
  final container = ProviderContainer(overrides: [
    feeRepositoryProvider.overrideWithValue(fakeRepo),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        home: InvoiceViewerScreen(
          feeId: 'f1',
          saver: saver,
          pdfBuilder: _fakePdf,
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

  testWidgets('loading → spinner centrado sin acciones', (tester) async {
    final repo = _FakeFeeRepository(pending: true);
    await _pumpScreen(tester, repo: repo, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PillButton), findsNothing);
  });

  testWidgets('data → header, subtítulo y PDF renderizado', (tester) async {
    await _pumpScreen(tester);

    expect(find.text(es.feesInvoiceViewerTitle), findsOneWidget);
    expect(find.text('Julio 2026 · Ana Pérez'), findsOneWidget);
    expect(find.text('PDF 3'), findsOneWidget);
    expect(
      find.widgetWithText(PillButton, es.feesInvoiceDownloadAction),
      findsOneWidget,
    );
  });

  testWidgets('404 → Factura no disponible sin retry', (tester) async {
    await _pumpScreen(
      tester,
      repo: _FakeFeeRepository(
        error: ApiException(message: 'Factura no disponible', statusCode: 404),
      ),
    );

    expect(find.text(es.feesInvoiceUnavailable), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(es.commonRetry), findsNothing);
    expect(find.byType(PillButton), findsNothing);
  });

  testWidgets('error de red → ErrorView y retry vuelve a pedir la factura',
      (tester) async {
    final repo = _FakeFeeRepository(
      error: ApiException(message: 'network error', statusCode: 500),
    );
    await _pumpScreen(tester, repo: repo);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(es.feesInvoiceLoadError), findsOneWidget);
    expect(repo.invoiceFileCalls, 1);

    await tester.tap(find.text(es.commonRetry));
    await tester.pumpAndSettle();

    expect(repo.invoiceFileCalls, 2);
  });

  testWidgets('descargar → guarda con nombre y avisa con snackbar',
      (tester) async {
    Uint8List? savedBytes;
    String? savedName;

    Future<String?> saver(Uint8List bytes, String name) async {
      savedBytes = bytes;
      savedName = name;
      return '/tmp/$name';
    }

    await _pumpScreen(tester, saver: saver);

    await tester.tap(find.widgetWithText(PillButton, es.feesInvoiceDownloadAction));
    await tester.pumpAndSettle();

    expect(savedBytes, Uint8List.fromList(const [1, 2, 3]));
    expect(savedName, 'Factura_Julio_2026_3.pdf');
    expect(find.text(es.feesInvoiceDownloadSuccess), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar la descarga no muestra aviso', (tester) async {
    Future<String?> saver(Uint8List bytes, String name) async => null;

    await _pumpScreen(tester, saver: saver);

    await tester.tap(find.widgetWithText(PillButton, es.feesInvoiceDownloadAction));
    await tester.pumpAndSettle();

    expect(find.text(es.feesInvoiceDownloadSuccess), findsNothing);
    expect(find.text(es.feesInvoiceDownloadError), findsNothing);
  });

  testWidgets('fallo al guardar → snackbar de error sin crash', (tester) async {
    Future<String?> saver(Uint8List bytes, String name) async =>
        throw Exception('disk');

    await _pumpScreen(tester, saver: saver);

    await tester.tap(find.widgetWithText(PillButton, es.feesInvoiceDownloadAction));
    await tester.pumpAndSettle();

    expect(find.text(es.feesInvoiceDownloadError), findsOneWidget);
    expect(find.text(es.feesInvoiceDownloadSuccess), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode renderiza sin excepciones', (tester) async {
    await _pumpScreen(tester, brightness: Brightness.dark);

    expect(find.text('PDF 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
