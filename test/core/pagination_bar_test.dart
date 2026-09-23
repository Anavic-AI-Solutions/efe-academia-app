import 'package:efe_mobile/core/widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../helpers/localized_app.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  required int page,
  required int totalPages,
  int total = 57,
  bool enabled = true,
  required ValueChanged<int> onPageChanged,
}) async {
  const perPage = 20;
  final from = total == 0 ? 0 : (page - 1) * perPage + 1;
  final to = from + perPage - 1 > total ? total : from + perPage - 1;
  await tester.pumpWidget(
    localizedApp(
      home: Scaffold(
        body: PaginationBar(
          page: page,
          totalPages: totalPages,
          from: from,
          to: to,
          total: total,
          enabled: enabled,
          onPageChanged: onPageChanged,
        ),
      ),
    ),
  );
}

void main() {
  group('pageWindow', () {
    test('returns every page when there are few', () {
      expect(pageWindow(current: 1, totalPages: 3), [1, 2, 3]);
      expect(pageWindow(current: 4, totalPages: 5), [1, 2, 3, 4, 5]);
    });

    test('pins the first pages and the last one near the start', () {
      expect(pageWindow(current: 2, totalPages: 10), [1, 2, 3, null, 10]);
    });

    test('centers the window in the middle', () {
      expect(
        pageWindow(current: 5, totalPages: 10),
        [1, null, 4, 5, 6, null, 10],
      );
    });

    test('pins the last pages near the end', () {
      expect(pageWindow(current: 9, totalPages: 10), [1, null, 8, 9, 10]);
    });
  });

  group('PaginationBar', () {
    testWidgets('shows the item range and the page window', (tester) async {
      await _pumpBar(
        tester,
        page: 2,
        totalPages: 3,
        onPageChanged: (_) {},
      );

      expect(find.text('Mostrando 21–40 de 57'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping a number reports the page', (tester) async {
      final taps = <int>[];
      await _pumpBar(
        tester,
        page: 1,
        totalPages: 3,
        onPageChanged: taps.add,
      );

      await tester.tap(find.text('3'));
      await tester.pump();

      expect(taps, [3]);
    });

    testWidgets('next arrow reports the next page and prev is disabled first',
        (tester) async {
      final taps = <int>[];
      await _pumpBar(
        tester,
        page: 1,
        totalPages: 3,
        onPageChanged: taps.add,
      );

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();
      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pump();

      expect(taps, [2]);
    });

    testWidgets('hides itself when there is a single page', (tester) async {
      await _pumpBar(
        tester,
        page: 1,
        totalPages: 1,
        onPageChanged: (_) {},
      );

      expect(find.text('Mostrando 1–20 de 57'), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.caretRight), findsNothing);
    });

    testWidgets('ignores taps while disabled', (tester) async {
      final taps = <int>[];
      await _pumpBar(
        tester,
        page: 2,
        totalPages: 3,
        enabled: false,
        onPageChanged: taps.add,
      );

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.byIcon(PhosphorIconsRegular.caretRight));
      await tester.pump();

      expect(taps, isEmpty);
    });
  });
}
