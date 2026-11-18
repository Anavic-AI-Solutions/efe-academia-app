import 'package:efe_mobile/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a screen with a button that opens [showConfirmDialog] and stores the
/// dialog result in [result].
Future<void> _pumpConfirmHost(
  WidgetTester tester, {
  required ValueNotifier<bool?> result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await showConfirmDialog(
                context,
                title: 'Title',
                message: 'Message',
                confirmLabel: 'Confirm',
                cancelLabel: 'Cancel',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirm returns true', (tester) async {
    final result = ValueNotifier<bool?>(null);
    await _pumpConfirmHost(tester, result: result);

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result.value, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    final result = ValueNotifier<bool?>(null);
    await _pumpConfirmHost(tester, result: result);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result.value, isFalse);
  });

  testWidgets('dismissing returns false', (tester) async {
    final result = ValueNotifier<bool?>(null);
    await _pumpConfirmHost(tester, result: result);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.value, isFalse);
  });
}
