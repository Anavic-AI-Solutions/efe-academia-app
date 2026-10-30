import 'package:efe_mobile/core/widgets/badge_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester,
    {required int count, bool showCount = false}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: BadgeCounter(
            count: count,
            showCount: showCount,
            child: const Icon(Icons.chat_bubble),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hides the badge at zero', (tester) async {
    await _pump(tester, count: 0, showCount: true);

    expect(find.text('0'), findsNothing);
    expect(find.text('99+'), findsNothing);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
  });

  testWidgets('renders the numeric count when showCount is true',
      (tester) async {
    await _pump(tester, count: 7, showCount: true);

    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('keeps the dot when showCount is false', (tester) async {
    await _pump(tester, count: 7);

    expect(find.text('7'), findsNothing);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
  });

  testWidgets('caps the count at 99+', (tester) async {
    await _pump(tester, count: 150, showCount: true);

    expect(find.text('99+'), findsOneWidget);
    expect(find.text('150'), findsNothing);
  });
}
