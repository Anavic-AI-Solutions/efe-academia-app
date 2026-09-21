import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/classroom_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../helpers/localized_app.dart';

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<CursorPagination<ClassroomModel>> getClassrooms({
    String? search,
    String? cursor,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async {
    calls.add({
      'search': search,
      'cursor': cursor,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
    });
    return CursorPagination(
      data: const [ClassroomModel(id: 'room-1', name: 'A2 A')],
      hasMore: false,
      total: 1,
    );
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

Future<_FakeClassroomRepository> _pumpScreen(WidgetTester tester) async {
  final repository = _FakeClassroomRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        classroomRepositoryProvider.overrideWithValue(repository),
        classroomFiltersProvider.overrideWith(
          (ref) => const ClassroomFilters(
            branches: ['Reconquista'],
            statuses: ['active', 'archived'],
          ),
        ),
      ],
      child: localizedApp(home: const ClassroomListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('applies the sheet selection and shows active filter chips',
      (tester) async {
    final repository = await _pumpScreen(tester);

    expect(find.text('A2 A'), findsOneWidget);
    expect(find.text('Sucursal: Reconquista'), findsNothing);

    await tester.tap(find.byIcon(PhosphorIconsRegular.faders));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconquista'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['branch'], 'Reconquista');
    expect(find.text('Sucursal: Reconquista'), findsOneWidget);
  });

  testWidgets('renders without overflow on a small phone and opens the sheet',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester);

    expect(find.text('A2 A'), findsOneWidget);

    await tester.tap(find.byIcon(PhosphorIconsRegular.faders));
    await tester.pumpAndSettle();

    expect(find.text('Aplicar filtros'), findsOneWidget);
  });

  testWidgets('removing an active chip clears that filter', (tester) async {
    final repository = await _pumpScreen(tester);

    await tester.tap(find.byIcon(PhosphorIconsRegular.faders));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconquista'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sucursal: Reconquista'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['branch'], isNull);
    expect(find.text('Sucursal: Reconquista'), findsNothing);
  });
}
