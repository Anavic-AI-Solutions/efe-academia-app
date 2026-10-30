import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses the unified blue system', () {
    final t = AppTheme.light;
    expect(t.colorScheme.primary, AppColors.primary);
    expect(t.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(t.appBarTheme.backgroundColor, AppColors.primary);
    expect(t.appBarTheme.titleTextStyle?.color, Colors.white);
  });
  testWidgets('buttons render r13 and h46 from the theme', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: ElevatedButton(onPressed: () {}, child: const Text('CTA')))));
    expect(tester.getSize(find.byType(ElevatedButton)).height, 46);
    // NOTE (Task 2): widget.style is null when the style comes from the
    // theme; resolve the shape from the theme style instead (same assertion).
    final style = AppTheme.light.elevatedButtonTheme.style!;
    expect(style.shape!.resolve(const <WidgetState>{}),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)));
  });
  test('dark theme keeps blue accents on dark surfaces', () {
    final t = AppTheme.dark;
    expect(t.colorScheme.primary, AppColors.primary);
    expect(t.scaffoldBackgroundColor, AppColors.darkBackground);
  });
}
