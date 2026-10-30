import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/screens/widgets/fee_card.dart';
import 'package:efe_mobile/features/students/screens/widgets/fee_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets('FeeCard muestra el estado normalizado', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: FeeCard(
            fee: FeeModel(
              id: 'f1',
              studentName: 'Ana',
              numberFee: 1,
              month: 'Enero',
              year: '2024',
              total: 5000,
              status: 'paid',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pagado'), findsOneWidget);
    expect(find.text('paid'), findsNothing);
  });

  testWidgets('FeeTile muestra un estado parcial', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: FeeTile(
            fee: FeeModel(
              id: 'f1',
              numberFee: 2,
              month: 'Febrero',
              year: '2024',
              total: 5000,
              status: 'partial',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Parcial'), findsOneWidget);
  });

  testWidgets('FeeTile muestra un estado vencido', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: FeeTile(
            fee: FeeModel(
              id: 'f1',
              numberFee: 3,
              month: 'Marzo',
              year: '2024',
              total: 5000,
              status: 'overdue',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vencido'), findsOneWidget);
  });
}
