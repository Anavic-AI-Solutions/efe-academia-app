import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/utils/formatters.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/parent_overdue_fees_card.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets('renders count, formatted total and triggers pay',
      (tester) async {
    var paid = false;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        body: ParentOverdueFeesCard(
            count: 2, total: 1300000, onPay: () => paid = true),
      ),
    ));
    expect(find.text('2 cuotas vencidas'), findsOneWidget);
    // La expectativa se computa contra el formatter (R9): su salida real para
    // es_AR es "1.300.000,00\u00A0$" (símbolo después del monto, NBSP U+00A0).
    expect(
      find.text('Mora total ${AppFormatters.formatCurrency(1300000)}'),
      findsOneWidget,
    );
    await tester.tap(find.text('Pagar'));
    expect(paid, isTrue);
  });

  testWidgets('singular copy and danger tokens in light/dark', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
          body: ParentOverdueFeesCard(count: 1, total: 50000, onPay: () {})),
    ));
    expect(find.text('1 cuota vencida'), findsOneWidget);
    final light =
        tester.widget<Container>(find.byKey(const Key('parent-mora-card')));
    expect((light.decoration as BoxDecoration).color, AppColors.dangerSoft);

    // El pump oscuro del brief no traía delegates de l10n (el widget usa
    // context.l10n y AppLocalizations.of usa `!`) ni esperaba la animación de
    // tema de MaterialApp (AnimatedTheme); ambos ajustes son de harness.
    await tester.pumpWidget(MaterialApp(
      locale: testLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
          body: ParentOverdueFeesCard(count: 1, total: 50000, onPay: () {})),
    ));
    await tester.pumpAndSettle();
    final dark =
        tester.widget<Container>(find.byKey(const Key('parent-mora-card')));
    expect((dark.decoration as BoxDecoration).color, AppColors.darkDangerSoft);
  });
}
