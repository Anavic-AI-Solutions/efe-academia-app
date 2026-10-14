import 'package:efe_mobile/features/dashboard/screens/widgets/parent_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets('renders the three actions and fires their callbacks',
      (tester) async {
    var fees = 0, boletin = 0, chat = 0;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        body: ParentQuickActions(
          onFees: () => fees++,
          onBoletin: () => boletin++,
          onChat: () => chat++,
        ),
      ),
    ));
    expect(find.text('Cuotas'), findsOneWidget);
    expect(find.text('Boletín'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    await tester.tap(find.text('Cuotas'));
    await tester.tap(find.text('Boletín'));
    await tester.tap(find.text('Chat'));
    expect([fees, boletin, chat], [1, 1, 1]);
  });
}
