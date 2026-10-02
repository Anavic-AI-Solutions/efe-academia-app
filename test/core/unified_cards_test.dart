import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/widgets/app_card.dart';
import 'package:efe_mobile/core/widgets/section_header.dart';
import 'package:efe_mobile/core/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BoxDecoration _appCardDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppCard),
      matching: find.byType(Container),
    ).first,
  );
  return container.decoration as BoxDecoration;
}

void main() {
  testWidgets('SectionHeader renders uppercase micro label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SectionHeader(title: 'Mis aulas'))),
    );
    final text = tester.widget<Text>(find.text('MIS AULAS'));
    expect(text.style?.fontSize, 10);
    expect(text.style?.fontWeight, FontWeight.w800);
    expect(text.style?.letterSpacing, 0.6);
    expect(text.style?.color, AppColors.sectionLabel);
  });

  testWidgets('AppCard uses r16 padding 14 and selected border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(selected: true, child: Text('x'))),
      ),
    );
    final deco = _appCardDecoration(tester);
    expect(deco.borderRadius, BorderRadius.circular(16));
    expect(deco.border, Border.all(color: AppColors.primarySoft, width: 1.5));

    // Inner padding 14.
    final paddings = tester.widgetList<Padding>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Padding),
      ),
    );
    expect(
      paddings.any(
        (p) => p.padding == const EdgeInsets.all(14),
      ),
      isTrue,
    );
  });

  testWidgets('AppCard without selected has no border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppCard(child: Text('x')))),
    );
    final deco = _appCardDecoration(tester);
    expect(deco.border, isNull);
  });

  testWidgets('SectionHeader action uses accent style and h16 padding',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'Mis aulas',
            actionLabel: 'Ver todo',
            onAction: () {},
          ),
        ),
      ),
    );
    final action = tester.widget<Text>(find.text('Ver todo'));
    expect(action.style?.fontSize, 11);
    expect(action.style?.fontWeight, FontWeight.w800);
    expect(action.style?.color, AppColors.accentFor(false));
  });

  testWidgets('StatCard uses chip, value and label styles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            icon: Icons.group,
            value: '24',
            label: 'Estudiantes',
            iconColor: Colors.blue,
          ),
        ),
      ),
    );
    final value = tester.widget<Text>(find.text('24'));
    expect(value.style?.fontSize, 22);
    expect(value.style?.fontWeight, FontWeight.w800);
    expect(value.style?.color, AppColors.inkFor(false));

    final label = tester.widget<Text>(find.text('Estudiantes'));
    expect(label.style?.fontSize, 12);
    expect(label.style?.color, AppColors.mutedFor(false));
  });
}
