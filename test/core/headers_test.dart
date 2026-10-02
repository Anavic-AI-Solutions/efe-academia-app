import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/widgets/gradient_header.dart';
import 'package:efe_mobile/core/widgets/header_stats_row.dart';
import 'package:efe_mobile/core/widgets/home_header.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GradientHeader renders blue gradient with bottom radius 24',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GradientHeader(child: Text('x')))));
    final box = tester.widget<Container>(find.byType(Container).first);
    final deco = box.decoration as BoxDecoration;
    expect(deco.gradient, AppColors.primaryGradient);
    expect(deco.borderRadius,
        const BorderRadius.vertical(bottom: Radius.circular(24)));
  });

  testWidgets('ScreenHeader shows back, 14/w800 title and 11 subtitle',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ScreenHeader(title: 'Asistencia', subtitle: '1G'))));
    final title = tester.widget<Text>(find.text('Asistencia'));
    expect(title.style?.fontSize, 14);
    expect(title.style?.fontWeight, FontWeight.w800);
    expect(title.style?.color, AppColors.onPrimary);
    expect(find.text('1G'), findsOneWidget);
  });

  testWidgets('HomeHeader shows greeting, name and child stats',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HomeHeader(
          name: 'Ileana Gómez',
          unreadCount: 2,
          onNotifications: () {},
          onSearch: () {},
          child: const Text('stats'),
        ),
      ),
    ));
    expect(find.text('Prof. Ileana Gómez'), findsOneWidget);
    expect(find.text('stats'), findsOneWidget);
  });

  testWidgets('HeaderStatsRow renders 24/w900 values with highlighted tile',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HeaderStatsRow(stats: [
          HeaderStat(value: '3', label: 'Aulas'),
          HeaderStat(value: '4', label: 'Ausentes', highlighted: true),
        ]),
      ),
    ));
    final value = tester.widget<Text>(find.text('3'));
    expect(value.style?.fontSize, 24);
    expect(value.style?.fontWeight, FontWeight.w900);
    expect(value.style?.color, AppColors.onPrimary);
    expect(find.text('Ausentes'), findsOneWidget);
    final tiles = tester.widgetList<Container>(find.byType(Container));
    expect(
      tiles.any((c) =>
          (c.decoration as BoxDecoration?)?.color ==
          AppColors.overlayStrong),
      isTrue,
    );
  });
}
