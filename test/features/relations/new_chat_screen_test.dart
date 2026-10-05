import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/widgets/app_card.dart';
import 'package:efe_mobile/core/widgets/avatar.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/features/chat/data/chat_api.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/features/relations/screens/new_chat_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/localized_app.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRelationsRepository implements RelationsRepository {
  _FakeRelationsRepository({
    this.relations = const [],
    this.never = false,
    this.failures = 0,
  });

  final List<RelationModel> relations;
  final bool never;
  int failures;
  int calls = 0;
  final List<String?> queries = [];

  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) {
    calls++;
    queries.add(query);
    if (never) return Completer<CursorPagination<RelationModel>>().future;
    if (failures > 0) {
      failures--;
      return Future.error(Exception('network down'));
    }
    final normalized = (query ?? '').trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? relations
        : relations
            .where((r) => r.fullname.toLowerCase().contains(normalized))
            .toList();
    return Future.value(
      CursorPagination<RelationModel>(data: filtered, hasMore: false),
    );
  }
}

class _FakeChatApi implements ChatApi {
  final List<int> createdWith = [];
  final Completer<Response> pending = Completer<Response>();

  @override
  Future<Response> createPrivateChat({required int withUserId}) {
    createdWith.add(withUserId);
    return pending.future;
  }

  @override
  Future<Response> getChats({String? cursor, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getMessages(
    String chatId, {
    String? cursor,
    int limit = 50,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

Response<dynamic> _createdChatResponse(String id) => Response(
      requestOptions: RequestOptions(path: '/chats'),
      statusCode: 201,
      data: {
        'data': {'id': id, 'type': 'chat'},
      },
    );

const _maria = RelationModel(
  id: '1',
  fullname: 'María Pérez',
  role: 'student',
  userId: 7,
);

const _juan = RelationModel(
  id: '2',
  fullname: 'Juan Gómez',
  role: 'professor',
  userId: 9,
);

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required RelationsRepository repository,
  ChatApi? chatApi,
}) async {
  final container = ProviderContainer(
    overrides: [
      relationsRepositoryProvider.overrideWithValue(repository),
      if (chatApi != null) chatApiProvider.overrideWithValue(chatApi),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const NewChatScreen()),
    ),
  );
  await tester.pump();
  return container;
}

Future<ProviderContainer> _pumpScreenWithRouter(
  WidgetTester tester, {
  required RelationsRepository repository,
  required ChatApi chatApi,
}) async {
  final router = GoRouter(
    initialLocation: '/chat/new',
    routes: [
      GoRoute(
        path: '/chat/new',
        builder: (_, __) => const NewChatScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => Scaffold(
          body: Text(
            'detalle ${state.pathParameters['id']} '
            '${state.uri.queryParameters['name'] ?? ''}',
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      relationsRepositoryProvider.overrideWithValue(repository),
      chatApiProvider.overrideWithValue(chatApi),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: testLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the shimmer while loading', (tester) async {
    await _pumpScreen(
      tester,
      repository: _FakeRelationsRepository(never: true),
    );

    expect(find.byType(ListShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the empty state when there are no linked people',
      (tester) async {
    await _pumpScreen(tester, repository: _FakeRelationsRepository());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Sin personas vinculadas'), findsOneWidget);
    expect(
      find.text('Todavía no tenés personas con las que chatear'),
      findsOneWidget,
    );
  });

  testWidgets('shows the error view with retry when the request fails',
      (tester) async {
    final repository = _FakeRelationsRepository(failures: 1);
    await _pumpScreen(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(repository.calls, greaterThanOrEqualTo(2));
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('lists linked people with name and role chip', (tester) async {
    await _pumpScreen(
      tester,
      repository: _FakeRelationsRepository(relations: const [_maria, _juan]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppCard), findsNWidgets(2));
    expect(find.byType(AppAvatar), findsNWidgets(2));
    expect(find.text('María Pérez'), findsOneWidget);
    expect(find.text('Alumno'), findsOneWidget);
    expect(find.text('Juan Gómez'), findsOneWidget);
    expect(find.text('Profesor'), findsOneWidget);
  });

  testWidgets('shows no results state when the query matches nothing',
      (tester) async {
    await _pumpScreen(
      tester,
      repository: _FakeRelationsRepository(relations: const [_maria]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Sin resultados para «zzz»'), findsOneWidget);
  });

  testWidgets(
      'tapping a person posts the chat once and navigates to the conversation',
      (tester) async {
    final chatApi = _FakeChatApi();
    await _pumpScreenWithRouter(
      tester,
      repository: _FakeRelationsRepository(relations: const [_maria]),
      chatApi: chatApi,
    );

    // Rapid double tap: the single-flight guard must keep a single POST.
    await tester.tap(find.text('María Pérez'));
    await tester.tap(find.text('María Pérez'));
    await tester.pump();

    expect(chatApi.createdWith, [7]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    chatApi.pending.complete(_createdChatResponse('c9'));
    await tester.pumpAndSettle();

    expect(find.textContaining('detalle c9'), findsOneWidget);
    expect(find.textContaining('María Pérez'), findsOneWidget);
  });
}
