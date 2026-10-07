import 'package:efe_mobile/features/students/domain/absence_model.dart';
import 'package:efe_mobile/features/students/screens/widgets/absence_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets('AbsenceTile muestra una falta pendiente', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: AbsenceTile(
            absence: AbsenceModel(
              id: 'a1',
              quantity: 2,
              period: '1',
              status: 'pending',
              date: '12/03/2026',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('AbsenceTile cae al heurístico cuando el status está vacío',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: AbsenceTile(
            absence: AbsenceModel(
              id: 'a1',
              quantity: 2,
              period: '1',
              justified: 'si',
              description: 'Fiebre',
              date: '12/03/2026',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Justificada'), findsOneWidget);
  });

  testWidgets('AbsenceTile muestra una falta sin justificar', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: AbsenceTile(
            absence: AbsenceModel(
              id: 'a1',
              quantity: 2,
              period: '1',
              status: 'unjustified',
              date: '12/03/2026',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sin justificar'), findsOneWidget);
  });
}