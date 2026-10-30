import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/widgets/classroom_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

const _options = ClassroomFilters(
  branches: ['Reconquista', 'Vera'],
  levels: ['A2', 'B1'],
  years: ['2025', '2026'],
  statuses: ['active', 'archived'],
);

Future<void> _pumpApp(
  WidgetTester tester, {
  ClassroomFilterSelection initial = const ClassroomFilterSelection(),
  required void Function(ClassroomFilterSelection?) onResult,
  Future<ClassroomFilters> Function()? loadOptions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        classroomFiltersProvider.overrideWith(
          (ref) => loadOptions?.call() ?? Future.value(_options),
        ),
      ],
      child: localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showClassroomFilterSheet(
                    context,
                    initial: initial,
                  );
                  onResult(result);
                },
                child: const Text('open filters'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open filters'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('applies the selected branch and level', (tester) async {
    ClassroomFilterSelection? result;
    await _pumpApp(tester, onResult: (r) => result = r);

    await _openSheet(tester);
    await tester.tap(find.text('Reconquista'));
    await tester.pump();
    await tester.tap(find.text('A2'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(result?.branch, 'Reconquista');
    expect(result?.level, 'A2');
    expect(result?.year, isNull);
    expect(result?.status, isNull);
  });

  testWidgets('pre-selects the current filters', (tester) async {
    ClassroomFilterSelection? result;
    await _pumpApp(
      tester,
      initial: const ClassroomFilterSelection(
        branch: 'Vera',
        status: 'archived',
      ),
      onResult: (r) => result = r,
    );

    await _openSheet(tester);
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(result?.branch, 'Vera');
    expect(result?.status, 'archived');
  });

  testWidgets('clear all resets a previous selection', (tester) async {
    ClassroomFilterSelection? result;
    await _pumpApp(
      tester,
      initial: const ClassroomFilterSelection(branch: 'Vera', level: 'B1'),
      onResult: (r) => result = r,
    );

    await _openSheet(tester);
    await tester.tap(find.text('Limpiá todo'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(result?.branch, isNull);
    expect(result?.level, isNull);
    expect(result?.isEmpty, isTrue);
  });

  testWidgets('shows a retry when options fail to load', (tester) async {
    await _pumpApp(
      tester,
      onResult: (_) {},
      loadOptions: () => Future.error('boom'),
    );

    await _openSheet(tester);

    expect(find.text('No se pudieron cargar los filtros'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('selected options use the single blue accent', (tester) async {
    ClassroomFilterSelection? result;
    await _pumpApp(tester, onResult: (r) => result = r);

    await _openSheet(tester);
    await tester.tap(find.text('Reconquista'));
    await tester.pump();

    final selected = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      selected.any(
        (chip) =>
            (chip.decoration as BoxDecoration?)?.color == AppColors.primary,
      ),
      isTrue,
    );

    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(result?.branch, 'Reconquista');
  });
}
