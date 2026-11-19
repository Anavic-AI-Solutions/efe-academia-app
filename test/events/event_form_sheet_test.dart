import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/events/data/event_repository.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/events/screens/widgets/event_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeEventRepository implements EventRepository {
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;
  Object? error;

  @override
  Future<CursorPagination<EventModel>> getEvents({String? cursor}) async =>
      CursorPagination<EventModel>.empty();

  @override
  Future<List<EventModel>> getCalendarEvents({
    required String startDate,
    required String endDate,
  }) async =>
      const [];

  @override
  Future<EventModel> createEvent({
    required String title,
    String description = '',
    required DateTime start,
    required DateTime end,
    int color = 0xFF3B82F6,
  }) async {
    if (error != null) throw error!;
    createdArgs = {
      'title': title,
      'description': description,
      'start': start,
      'end': end,
      'color': color,
    };
    return EventModel(
      id: 'e1',
      title: title,
      description: description,
      start: start,
      end: end,
      color: color,
    );
  }

  @override
  Future<EventModel> updateEvent(
    String id, {
    required String title,
    String description = '',
    required DateTime start,
    required DateTime end,
    int color = 0xFF3B82F6,
  }) async {
    if (error != null) throw error!;
    updatedId = id;
    updatedArgs = {
      'title': title,
      'description': description,
      'start': start,
      'end': end,
      'color': color,
    };
    return EventModel(
      id: id,
      title: title,
      description: description,
      start: start,
      end: end,
      color: color,
    );
  }

  @override
  Future<void> deleteEvent(String id) async {}
}

class _Picker {
  _Picker(this.values);

  final List<DateTime?> values;
  int calls = 0;

  Future<DateTime?> pick(DateTime initial) async {
    final value = values[calls];
    calls++;
    return value;
  }
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeEventRepository repository, {
  EventModel? event,
  _Picker? picker,
  ValueNotifier<bool?>? result,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [eventRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EventFormSheet(
                    event: event,
                    pickDateTime: picker?.pick,
                  ),
                );
                if (result != null) result.value = saved;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Guardar');
  await tester.ensureVisible(save);
  await tester.pump();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('título vacío muestra el error de campo y no llama al repo',
      (tester) async {
    final repository = _FakeEventRepository();
    await _pumpForm(tester, repository);

    await _tapSave(tester);

    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(repository.createdArgs, isNull);
    expect(repository.updatedArgs, isNull);
  });

  testWidgets('fin anterior al inicio muestra eventFormInvalidRange',
      (tester) async {
    final repository = _FakeEventRepository();
    final picker = _Picker([
      DateTime(2026, 12, 2, 10),
      DateTime(2026, 12, 1, 10),
    ]);
    await _pumpForm(tester, repository, picker: picker);

    await tester.enterText(
      find.byKey(const Key('event-title-field')),
      'Acto',
    );
    await tester.tap(find.byKey(const Key('event-start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-end-button')));
    await tester.pumpAndSettle();

    await _tapSave(tester);

    expect(find.text('El fin debe ser posterior al inicio'), findsOneWidget);
    expect(repository.createdArgs, isNull);
    expect(repository.updatedArgs, isNull);
  });

  testWidgets('creación válida llama createEvent con start/end/color exactos',
      (tester) async {
    final repository = _FakeEventRepository();
    final picker = _Picker([
      DateTime(2026, 12, 1, 10, 30),
      DateTime(2026, 12, 1, 12, 45),
    ]);
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, picker: picker, result: result);

    await tester.enterText(
      find.byKey(const Key('event-title-field')),
      'Acto escolar',
    );
    await tester.enterText(
      find.byKey(const Key('event-description-field')),
      'Patio central',
    );
    await tester.tap(find.byKey(const Key('event-start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-end-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('event-color-${eventColorPalette[1]}')),
    );
    await tester.pumpAndSettle();

    await _tapSave(tester);

    expect(repository.createdArgs, isNotNull);
    expect(repository.createdArgs!['title'], 'Acto escolar');
    expect(repository.createdArgs!['description'], 'Patio central');
    expect(
      repository.createdArgs!['start'],
      DateTime(2026, 12, 1, 10, 30),
    );
    expect(repository.createdArgs!['end'], DateTime(2026, 12, 1, 12, 45));
    expect(repository.createdArgs!['color'], eventColorPalette[1]);
    expect(result.value, isTrue);
  });

  testWidgets('edición prellena y llama updateEvent', (tester) async {
    final repository = _FakeEventRepository();
    final result = ValueNotifier<bool?>(null);
    final event = EventModel(
      id: 'e1',
      title: 'Original',
      description: 'Bajada original',
      start: DateTime(2026, 12, 1, 10),
      end: DateTime(2026, 12, 1, 12),
      color: 0xFFEF4444,
    );
    await _pumpForm(tester, repository, event: event, result: result);

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Bajada original'), findsOneWidget);
    expect(find.text('Editar evento'), findsOneWidget);
    expect(find.text('01/12/2026 10:00'), findsOneWidget);
    expect(find.text('01/12/2026 12:00'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('event-title-field')),
      'Editado',
    );
    await _tapSave(tester);

    expect(repository.updatedId, 'e1');
    expect(repository.updatedArgs!['title'], 'Editado');
    expect(repository.updatedArgs!['description'], 'Bajada original');
    expect(repository.updatedArgs!['start'], DateTime(2026, 12, 1, 10));
    expect(repository.updatedArgs!['end'], DateTime(2026, 12, 1, 12));
    expect(repository.updatedArgs!['color'], 0xFFEF4444);
    expect(result.value, isTrue);
  });

  testWidgets('un 422 pinta el error en el campo', (tester) async {
    final repository = _FakeEventRepository()
      ..error =
          ValidationException(fieldErrors: {'title': 'El título ya existe'});
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('event-title-field')),
      'Repetido',
    );

    await _tapSave(tester);

    expect(find.text('El título ya existe'), findsOneWidget);
    expect(result.value, isNull);
  });
}
