import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_card.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

/// Cuota de prueba; por defecto, pendiente de julio 2026 de Ana Pérez.
/// El mes va numérico como lo devuelve la API.
FeeModel _fee({
  String status = 'pending',
  String proofStatus = '',
  bool isOverdue = false,
  double toPay = 25000,
  double owe = 0,
  String month = '7',
  String year = '2026',
}) =>
    FeeModel(
      id: 'f1',
      studentName: 'Ana Pérez',
      month: month,
      year: year,
      toPay: toPay,
      total: toPay,
      status: status,
      proofStatus: proofStatus,
      isOverdue: isOverdue,
      owe: owe,
    );

Future<void> _pumpCard(
  WidgetTester tester,
  FeeModel fee, {
  VoidCallback? onTap,
  VoidCallback? onPay,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: testLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        body: ParentFeeCard(
          fee: fee,
          childName: fee.studentName,
          onTap: onTap ?? () {},
          onPay: onPay,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Color del texto de la línea de estado.
Color? _lineColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('renders overdue fee with danger line and pay pill',
      (tester) async {
    var paid = false;
    await _pumpCard(tester, _fee(isOverdue: true), onPay: () => paid = true);

    expect(find.text('Julio 2026'), findsOneWidget);
    final overdueLine = 'Vencido · ${AppFormatters.formatCurrency(25000)}';
    expect(find.text(overdueLine), findsOneWidget);
    expect(_lineColor(tester, overdueLine), AppColors.dangerInk);
    expect(find.text('Ana Pérez'), findsOneWidget);

    await tester.tap(find.text('Pagar'));
    expect(paid, isTrue);
  });

  testWidgets('uses dark danger tokens for the overdue line in dark mode',
      (tester) async {
    await _pumpCard(tester, _fee(isOverdue: true), dark: true);

    final overdueLine = 'Vencido · ${AppFormatters.formatCurrency(25000)}';
    expect(_lineColor(tester, overdueLine), AppColors.darkDangerInk);
    expect(_lineColor(tester, 'Julio 2026'), AppColors.darkTextPrimary);
  });

  testWidgets('renders pending without danger color', (tester) async {
    await _pumpCard(tester, _fee(), onPay: () {});

    final pendingLine = 'Pendiente · ${AppFormatters.formatCurrency(25000)}';
    expect(_lineColor(tester, pendingLine), AppColors.lightMuted);
    expect(_lineColor(tester, pendingLine), isNot(AppColors.dangerInk));
    expect(find.text('Pagar'), findsOneWidget);
  });

  testWidgets('renders the capitalized month name from the numeric month',
      (tester) async {
    Widget card(String month) => localizedApp(
          home: Scaffold(
            body: ParentFeeCard(
              fee: _fee(month: month, year: '2026'),
              childName: 'Ana Pérez',
              onTap: () {},
            ),
          ),
        );

    // Locale es_AR: nombre del mes capitalizado + año.
    await tester.pumpWidget(card('7'));
    expect(find.text('Julio 2026'), findsOneWidget);

    // Mismo dato en inglés.
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ParentFeeCard(
            fee: _fee(month: '7', year: '2026'),
            childName: 'Ana Pérez',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);

    // Mes no numérico: fallback al valor crudo.
    await tester.pumpWidget(card('Invierno'));
    await tester.pumpAndSettle();
    expect(find.text('Invierno 2026'), findsOneWidget);
  });

  testWidgets('renders partial with owed amount', (tester) async {
    await _pumpCard(
      tester,
      _fee(status: 'partial', toPay: 25000, owe: 12500),
      onPay: () {},
    );

    final partialLine = 'Parcial · debe ${AppFormatters.formatCurrency(12500)}';
    expect(find.text(partialLine), findsOneWidget);
    expect(_lineColor(tester, partialLine), AppColors.lightMuted);
    expect(find.text('Pagar'), findsOneWidget);

    // Vencida además de parcial: misma línea, en rojo.
    await _pumpCard(
      tester,
      _fee(status: 'partial', isOverdue: true, toPay: 25000, owe: 12500),
      onPay: () {},
    );
    expect(find.text(partialLine), findsOneWidget);
    expect(_lineColor(tester, partialLine), AppColors.dangerInk);
  });

  testWidgets('renders under review from proof_status or status without action',
      (tester) async {
    final reviewLine = 'En revisión · ${AppFormatters.formatCurrency(25000)}';

    await _pumpCard(tester, _fee(proofStatus: 'under_review'));
    expect(find.text(reviewLine), findsOneWidget);
    expect(_lineColor(tester, reviewLine), AppColors.primary);
    expect(find.text('Pagar'), findsNothing);

    await _pumpCard(tester, _fee(status: 'under_review'));
    expect(find.text(reviewLine), findsOneWidget);
    expect(_lineColor(tester, reviewLine), AppColors.primary);
    expect(find.text('Pagar'), findsNothing);
  });

  testWidgets('renders paid with check and no action', (tester) async {
    await _pumpCard(tester, _fee(status: 'paid'), onPay: () {});

    expect(_lineColor(tester, 'Pagado'), AppColors.present);
    final check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, AppColors.present);
    expect(check.size, 14);
    expect(find.text('Pagar'), findsNothing);
  });

  testWidgets('unknown status falls back to muted system label',
      (tester) async {
    // Cancelada: etiqueta cruda del sistema, en muted y sin acción de pago.
    await _pumpCard(tester, _fee(status: 'cancelled'), onPay: () {});
    expect(_lineColor(tester, 'cancelled'), AppColors.lightMuted);
    expect(find.text('Pagar'), findsNothing);

    // Estado desconocido cualquiera: no crashea y conserva el fallback.
    await _pumpCard(tester, _fee(status: 'mystery'), onPay: () {});
    expect(_lineColor(tester, 'mystery'), AppColors.lightMuted);
    expect(find.text('Pagar'), findsOneWidget);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await _pumpCard(
      tester,
      _fee(),
      onTap: () => tapped = true,
      onPay: () {},
    );

    await tester.tap(find.byType(ParentFeeCard));
    expect(tapped, isTrue);
  });
}
