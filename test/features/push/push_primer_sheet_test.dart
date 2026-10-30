import 'package:efe_mobile/features/push/widgets/push_primer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

void main() {
  testWidgets('muestra copy, Activar devuelve true y Ahora no false',
      (tester) async {
    bool? result;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(body: PushPrimerSheet(onResult: (v) => result = v)),
    ));
    expect(find.text('Activá las notificaciones'), findsOneWidget);
    expect(find.textContaining('aunque la app esté cerrada'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    expect(result, isFalse);
  });

  testWidgets('tocar Activar devuelve true', (tester) async {
    bool? result;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(body: PushPrimerSheet(onResult: (v) => result = v)),
    ));
    await tester.tap(find.text('Activar'));
    expect(result, isTrue);
  });
}
