import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/chat/screens/chat_detail_screen.dart';
import 'package:efe_mobile/features/chat/screens/chat_list_screen.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/features/relations/screens/new_chat_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/localized_app.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() async => true;

  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'user-1',
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        role: 'admin',
      );

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

class _NeverChatRepository implements ChatRepository {
  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) =>
      Completer<CursorPagination<ChatModel>>().future;

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
    String? direction,
  }) =>
      Completer<CursorPagination<MessageModel>>().future;

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

class _ListChatRepository implements ChatRepository {
  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) async =>
      CursorPagination<ChatModel>(
        data: const [
          ChatModel(id: 'c1', name: 'Ada', lastMessage: 'Hola'),
        ],
        hasMore: false,
      );

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
    String? direction,
  }) async =>
      CursorPagination<MessageModel>(data: const [], hasMore: false);

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

class _EmptyRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination<RelationModel>(data: const [], hasMore: false);
}

// ---------------------------------------------------------------------------
// Router mirroring the /chat branch of lib/app/router.dart (new before :id)
// ---------------------------------------------------------------------------

GoRouter _chatRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/chat',
          builder: (_, __) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, __) => const NewChatScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => ChatDetailScreen(
                chatId: state.pathParameters['id']!,
                chatName: state.uri.queryParameters['name'],
              ),
            ),
          ],
        ),
      ],
    );

Future<ProviderContainer> _pumpRouter(
  WidgetTester tester,
  GoRouter router, {
  required ChatRepository chatRepository,
}) async {
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      chatRepositoryProvider.overrideWithValue(chatRepository),
      relationsRepositoryProvider
          .overrideWithValue(_EmptyRelationsRepository()),
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
  testWidgets('navigates to the new chat screen instead of a chat detail',
      (tester) async {
    await _pumpRouter(
      tester,
      _chatRouter('/chat/new'),
      chatRepository: _NeverChatRepository(),
    );

    expect(find.byType(NewChatScreen), findsOneWidget);
    expect(find.byType(ChatDetailScreen), findsNothing);
  });

  testWidgets('the + action of the chat list opens the new chat screen',
      (tester) async {
    await _pumpRouter(
      tester,
      _chatRouter('/chat'),
      chatRepository: _ListChatRepository(),
    );

    expect(find.byType(ChatListScreen), findsOneWidget);

    await tester.tap(find.byIcon(PhosphorIconsRegular.plus));
    await tester.pumpAndSettle();

    expect(find.byType(NewChatScreen), findsOneWidget);
    expect(find.byType(ChatDetailScreen), findsNothing);
  });
}
