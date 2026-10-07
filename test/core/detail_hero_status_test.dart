import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/widgets/detail_hero.dart';
import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

bool _hasDotWithColor(WidgetTester tester, Color color) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  return containers.any((container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration && decoration.color == color;
  });
}

void main() {
  testWidgets('hero pinta el punto con el color del estado crudo activo',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: DetailHero(
            leading: DetailHeroIcon(icon: Icons.school),
            title: 'A2 A',
            status: 'active',
            statusLabel: 'Activo',
          ),
        ),
      ),
    );

    expect(find.text('Activo'), findsOneWidget);
    expect(_hasDotWithColor(tester, AppColors.success), isTrue);
    expect(_hasDotWithColor(tester, Colors.white70), isFalse);
  });

  testWidgets('hero pinta el punto con el color del estado crudo archivado',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: DetailHero(
            leading: DetailHeroIcon(icon: Icons.school),
            title: 'A2 A',
            status: 'archived',
            statusLabel: 'Archivado',
          ),
        ),
      ),
    );

    expect(_hasDotWithColor(tester, AppColors.error), isTrue);
  });

  testWidgets('hero pinta el punto de un alumno aprobado en verde',
      (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: const Scaffold(
          body: DetailHero(
            leading: DetailHeroIcon(icon: Icons.person),
            title: 'Ana',
            status: 'approved',
            statusLabel: 'Aprobado',
          ),
        ),
      ),
    );

    expect(_hasDotWithColor(tester, AppColors.success), isTrue);
  });

  test('StatusBadge.colorFor mapea los estados de la tabla del spec', () {
    expect(StatusBadge.colorFor('active'), AppColors.success);
    expect(StatusBadge.colorFor('approved'), AppColors.success);
    expect(StatusBadge.colorFor('rejected'), AppColors.error);
    expect(StatusBadge.colorFor('archived'), AppColors.error);
    expect(StatusBadge.colorFor('justified'), AppColors.success);
    expect(StatusBadge.colorFor('pending'), AppColors.warning);
    expect(StatusBadge.colorFor('desconocido'), AppColors.lightTextTertiary);
  });
}
