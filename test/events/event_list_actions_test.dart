import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/events/data/event_repository.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/events/screens/event_list_screen.dart';
import 'package:efe_mobile/features/events/screens/widgets/event_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void seed(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository(this.items);

  List<EventModel> items;
  String? deletedId;
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;
  int listCalls = 0;
  int calendarCalls = 0;

  @override
  Future<CursorPagination<EventModel>> getEvents({String? cursor}) async {
    listCalls++;
    return CursorPagination<EventModel>(data: items, hasMore: false);
  }

  @override
  Future<List<EventModel>> getCalendarEvents({
    required String startDate,
    required String endDate,
  }) async {
    calendarCalls++;
    return items;
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    String description = '',
    required DateTime start,
    required DateTime end,
    int color = 0xFF3B82F6,
  }) async {
    createdArgs = {
      'title': title,
      'description': description,
      'start': start,
      'end': end,
      'color': color,
    };
    return EventModel(
      id: 'new',
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
  Future<void> deleteEvent(String id) async {
    deletedId = id;
  }
}

List<EventModel> _items() => [
      EventModel(
        id: 'e1',
        title: 'Acto uno',
        start: DateTime(2026, 11, 20, 10),
        end: DateTime(2026, 11, 20, 12),
        createdBy: 1,
      ),
      EventModel(
        id: 'e2',
        title: 'Acto dos',
        start: DateTime(2026, 11, 21, 10),
        end: DateTime(2026, 11, 21, 12),
        createdBy: 2,
      ),
    ];

Future<_FakeEventRepository> _pumpList(
  WidgetTester tester, {
  required String role,
  List<EventModel>? items,
  _FakeEventRepository? repository,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? _FakeEventRepository(items ?? _items());
  final auth = _TestAuthNotifier()
    ..seed(UserModel(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      role: role,
    ));

  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => auth),
      eventRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  final subscriptions = [
    container.listen(homeCalendarProvider, (_, __) {}),
    container.listen(calendarMonthProvider(DateTime(2026, 11)), (_, __) {}),
  ];
  addTearDown(() {
    for (final subscription in subscriptions) {
      subscription.close();
    }
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const EventListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('admin ve acciones en todos los eventos y el FAB',
      (tester) async {
    await _pumpList(tester, role: 'admin');

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e1')), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e2')), findsOneWidget);
  });

  testWidgets('branch ve acciones en todos los eventos', (tester) async {
    await _pumpList(tester, role: 'branch');

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e1')), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e2')), findsOneWidget);
  });

  testWidgets('profesor ve acciones solo en sus propios eventos',
      (tester) async {
    await _pumpList(tester, role: 'professor');

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e1')), findsOneWidget);
    expect(find.byKey(const Key('event-menu-e2')), findsNothing);
  });

  for (final role in ['parent', 'student']) {
    testWidgets('$role no ve FAB ni acciones', (tester) async {
      await _pumpList(tester, role: role);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('event-menu-e1')), findsNothing);
      expect(find.byKey(const Key('event-menu-e2')), findsNothing);
    });
  }

  testWidgets('editar abre el formulario prellenado', (tester) async {
    await _pumpList(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('event-menu-e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.text('Editar evento'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(EventFormSheet),
        matching: find.text('Acto uno'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('eliminar pide confirmación e invalida los tres providers',
      (tester) async {
    final repo = await _pumpList(tester, role: 'admin');
    expect(repo.listCalls, 1);
    expect(repo.calendarCalls, 2);

    await tester.tap(find.byKey(const Key('event-menu-e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar evento'), findsOneWidget);
    expect(repo.deletedId, isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.deletedId, 'e1');
    expect(repo.listCalls, 2);
    expect(repo.calendarCalls, 4);
    expect(find.text('Evento eliminado'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repo = await _pumpList(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('event-menu-e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.deletedId, isNull);
    expect(repo.listCalls, 1);
  });

  testWidgets('crear desde la lista invalida los tres providers',
      (tester) async {
    final repo = await _pumpList(tester, role: 'professor');
    expect(repo.listCalls, 1);
    expect(repo.calendarCalls, 2);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo evento'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('event-title-field')),
      'Nuevo acto',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.createdArgs, isNotNull);
    expect(repo.createdArgs!['title'], 'Nuevo acto');
    expect(repo.listCalls, 2);
    expect(repo.calendarCalls, 4);
    expect(find.text('Evento creado'), findsOneWidget);
  });
}
