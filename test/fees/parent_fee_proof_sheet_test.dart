import 'dart:typed_data';

import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_proof_sheet.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

/// Repositorio falso: cuenta subidas y captura feeId/bytes/filename.
class _FakeFeeRepository implements FeeRepository {
  int uploadCalls = 0;
  String? lastFeeId;
  List<int>? lastBytes;
  String? lastFilename;
  bool failUpload = false;

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) async {
    uploadCalls++;
    lastFeeId = feeId;
    lastBytes = bytes;
    lastFilename = filename;
    if (failUpload) {
      throw ApiException(message: 'boom', statusCode: 422);
    }
  }

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) =>
      throw UnimplementedError();

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
  String status = 'pending',
  String proofStatus = '',
  double toPay = 25000,
}) =>
    FeeModel(
      id: 'f1',
      studentName: 'Ana Pérez',
      month: '7',
      year: '2026',
      toPay: toPay,
      total: toPay,
      status: status,
      proofStatus: proofStatus,
    );

ProofUploadFile _validFile() => ProofUploadFile(
      bytes: Uint8List.fromList(List.filled(2048, 1)),
      name: 'comprobante.jpg',
    );

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// ElevatedButton interno del PillButton "Subir".
ElevatedButton _submitButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(PillButton),
        matching: find.byType(ElevatedButton),
      ),
    );

void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es', 'AR'));
  });

  /// Abre el sheet como modal real para poder verificar el pop(true).
  Future<_FakeFeeRepository> pumpSheet(
    WidgetTester tester, {
    _FakeFeeRepository? repo,
    FeeModel? fee,
    Future<ProofUploadFile?> Function()? pickFile,
    void Function(bool? result)? onResult,
  }) async {
    final fakeRepo = repo ?? _FakeFeeRepository();
    final sheet = ParentFeeProofSheet(
      fee: fee ?? _fee(),
      pickFile: pickFile,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [feeRepositoryProvider.overrideWithValue(fakeRepo)],
        child: localizedApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => sheet,
                    );
                    onResult?.call(result);
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return fakeRepo;
  }

  testWidgets('pick válido → preview, sube con bytes/filename y pop(true)',
      (tester) async {
    bool? result;
    final repo = await pumpSheet(
      tester,
      pickFile: () async => _validFile(),
      onResult: (value) => result = value,
    );

    // Título de subida y contexto de la cuota (mes · hijo · monto).
    expect(find.text(es.feesUploadProofAction), findsOneWidget);
    expect(
      find.text(
        'Julio 2026 · Ana Pérez · ${AppFormatters.formatCurrency(25000)}',
      ),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text(es.feesProofPickFile));

    // Preview con nombre y tamaño.
    expect(find.text('comprobante.jpg'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);

    await _tapVisible(
      tester,
      find.widgetWithText(PillButton, es.feesProofSubmit),
    );

    expect(repo.uploadCalls, 1);
    expect(repo.lastFeeId, 'f1');
    expect(repo.lastBytes, _validFile().bytes);
    expect(repo.lastFilename, 'comprobante.jpg');
    expect(result, isTrue);
    expect(find.byType(ParentFeeProofSheet), findsNothing);
  });

  testWidgets('extensión inválida → error inline y no llama al repo',
      (tester) async {
    final repo = await pumpSheet(
      tester,
      pickFile: () async => ProofUploadFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'virus.exe',
      ),
    );

    await _tapVisible(tester, find.text(es.feesProofPickFile));

    expect(find.text('virus.exe'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    final error = tester.widget<Text>(find.text(es.feesProofHint));
    expect(error.style?.color, AppColors.absent);
    expect(_submitButton(tester).onPressed, isNull);
    expect(repo.uploadCalls, 0);
    expect(find.byType(ParentFeeProofSheet), findsOneWidget);
  });

  testWidgets('archivo mayor a 10 MB → error inline y no llama al repo',
      (tester) async {
    final repo = await pumpSheet(
      tester,
      pickFile: () async => ProofUploadFile(
        bytes: Uint8List(10 * 1024 * 1024 + 1),
        name: 'grande.pdf',
      ),
    );

    await _tapVisible(tester, find.text(es.feesProofPickFile));

    expect(find.text('grande.pdf'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    final error = tester.widget<Text>(find.text(es.feesProofHint));
    expect(error.style?.color, AppColors.absent);
    expect(_submitButton(tester).onPressed, isNull);
    expect(repo.uploadCalls, 0);
    expect(find.byType(ParentFeeProofSheet), findsOneWidget);
  });

  testWidgets('error 422 del repo → mensaje inline y el sheet sigue abierto',
      (tester) async {
    bool? result;
    final repo = await pumpSheet(
      tester,
      pickFile: () async => _validFile(),
      onResult: (value) => result = value,
    )
      ..failUpload = true;

    await _tapVisible(tester, find.text(es.feesProofPickFile));
    await _tapVisible(
      tester,
      find.widgetWithText(PillButton, es.feesProofSubmit),
    );

    expect(repo.uploadCalls, 1);
    expect(find.text(es.feesProofError), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(ParentFeeProofSheet), findsOneWidget);
    expect(result, isNull);
    // El preview sigue visible y se puede reintentar.
    expect(find.text('comprobante.jpg'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('sin archivo el botón Subir está deshabilitado', (tester) async {
    final repo = await pumpSheet(tester);

    expect(find.text(es.feesProofHint), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNull);

    await tester.tap(find.byType(PillButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(repo.uploadCalls, 0);
  });

  testWidgets('título Reemplazar comprobante si proof_status está en revisión',
      (tester) async {
    await pumpSheet(tester, fee: _fee(proofStatus: 'under_review'));
    expect(find.text(es.feesReplaceProofAction), findsOneWidget);
    expect(find.text(es.feesUploadProofAction), findsNothing);
  });

  testWidgets('título Reemplazar comprobante si status está en revisión',
      (tester) async {
    await pumpSheet(tester, fee: _fee(status: 'under_review'));
    expect(find.text(es.feesReplaceProofAction), findsOneWidget);
    expect(find.text(es.feesUploadProofAction), findsNothing);
  });
}
