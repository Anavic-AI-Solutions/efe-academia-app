import 'package:efe_mobile/core/api/page_pagination.dart';
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
  _FakeClassroomRepository({this.total = 1});

  final int total;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) async {
    calls.add({
      'search': search,
      'page': page,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
    });
    if (total == 0) return PageResult.empty(perPage: limit);
    final offset = (page - 1) * limit;
    final count = (total - offset).clamp(0, limit);
    return PageResult(
      data: List.generate(
        count,
        (i) => ClassroomModel(
          id: 'room-${offset + i + 1}',
          name: 'Clase ${offset + i + 1}',
        ),
      ),
      page: page,
      perPage: limit,
      total: total,
    );
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

Future<_FakeClassroomRepository> _pumpScreen(
  WidgetTester tester, {
  int total = 1,
}) async {
  final repository = _FakeClassroomRepository(total: total);
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

    expect(find.text('Clase 1'), findsOneWidget);
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

    expect(find.text('Clase 1'), findsOneWidget);

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

  testWidgets('shows numbered pagination and requests the tapped page',
      (tester) async {
    final repository = await _pumpScreen(tester, total: 57);

    expect(find.text('Mostrando 1–20 de 57'), findsOneWidget);
    expect(find.text('Clase 1'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['page'], 2);
    expect(find.text('Clase 21'), findsOneWidget);
    expect(find.text('Mostrando 21–40 de 57'), findsOneWidget);
  });

  testWidgets('goes back to page 1 when a filter is applied', (tester) async {
    final repository = await _pumpScreen(tester, total: 57);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(repository.calls.last['page'], 2);

    await tester.tap(find.byIcon(PhosphorIconsRegular.faders));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconquista'));
    await tester.pump();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['page'], 1);
    expect(repository.calls.last['branch'], 'Reconquista');
  });

  testWidgets('hides pagination when everything fits in one page',
      (tester) async {
    await _pumpScreen(tester, total: 3);

    expect(find.textContaining('Mostrando'), findsNothing);
  });
}
