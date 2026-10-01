import 'dart:async';

import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/core/widgets/app_card.dart';
import 'package:efe_mobile/core/widgets/avatar.dart';
import 'package:efe_mobile/core/widgets/gradient_header.dart';
import 'package:efe_mobile/core/widgets/large_title_bar.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/core/widgets/section_header.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/chat/screens/chat_detail_screen.dart';
import 'package:efe_mobile/features/chat/screens/chat_list_screen.dart';
import 'package:efe_mobile/features/profile/screens/profile_screen.dart';
import 'package:efe_mobile/features/search/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> saveToken(String token) async => values['auth_token'] = token;

  @override
  Future<String?> getToken() async => values['auth_token'];

  @override
  Future<void> deleteToken() async => values.remove('auth_token');

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<void> saveThemeMode(String mode) async => values['theme_mode'] = mode;

  @override
  Future<String?> getThemeMode() async => values['theme_mode'];

  @override
  Future<void> saveLanguageCode(String code) async =>
      values['language_code'] = code;

  @override
  Future<String?> getLanguageCode() async => values['language_code'];
}

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

class _FakeChatRepository implements ChatRepository {
  final List<ChatModel> chats;
  final bool never;

  _FakeChatRepository({this.chats = const [], this.never = false});

  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) {
    if (never) return Completer<CursorPagination<ChatModel>>().future;
    return Future.value(
      CursorPagination(data: chats, hasMore: false),
    );
  }

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) {
    if (never) return Completer<CursorPagination<MessageModel>>().future;
    return Future.value(
      CursorPagination<MessageModel>(data: const [], hasMore: false),
    );
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

const _demoChats = [
  ChatModel(id: 'c1', name: 'Ada', lastMessage: 'Hola', unreadCount: 2),
];

// ---------------------------------------------------------------------------
// Chat list
// ---------------------------------------------------------------------------

Future<void> _pumpChatList(
  WidgetTester tester,
  ChatRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: localizedApp(home: const ChatListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpChatDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider
            .overrideWithValue(_FakeChatRepository(never: true)),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: localizedApp(
        home: const ChatDetailScreen(chatId: 'c1', chatName: 'Ada'),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester, {
  SearchState initial = const SearchState(),
}) async {
  dotenv.testLoad(fileInput: '');
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient(_FakeSecureStorage())),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const SearchScreen()),
    ),
  );
  container.read(searchProvider.notifier).state = initial;
  await tester.pump();
  return container;
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

Future<ProviderContainer> _pumpProfile(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedAppWithLocaleProvider(home: const ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
      'chat list uses gradient header, shimmer loading and app cards',
      (tester) async {
    await _pumpChatList(tester, _FakeChatRepository(chats: _demoChats));

    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.backgroundFor(false),
    );
    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('chat list shows shimmer instead of spinner while loading',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider
              .overrideWithValue(_FakeChatRepository(never: true)),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: localizedApp(home: const ChatListScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(ListShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('chat detail uses ScreenHeader instead of raw AppBar',
      (tester) async {
    await _pumpChatDetail(tester);

    expect(find.byType(ScreenHeader), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    // Input bar keeps working with the existing strings.
    expect(find.text('Escribí un mensaje...'), findsOneWidget);
    expect(find.byType(ListShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('search uses gradient header and app cards for results',
      (tester) async {
    await _pumpSearch(
      tester,
      initial: const SearchState(
        query: 'ana',
        results: [
          SearchResult(
            id: '1',
            title: 'Ana',
            subtitle: 'Alumna',
            type: 'student',
          ),
        ],
      ),
    );

    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.backgroundFor(false),
    );
    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('search loading uses shimmer instead of spinner',
      (tester) async {
    await _pumpSearch(
      tester,
      initial: const SearchState(query: 'ana', isLoading: true),
    );

    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(ListShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'profile uses gradient header, section headers, app cards and r13 error logout',
      (tester) async {
    await _pumpProfile(tester);

    expect(find.byType(LargeTitleBar), findsOneWidget);
    expect(find.byType(SectionHeader), findsWidgets);
    // Avatar keeps 80px + blue ring.
    final avatar = tester.widget<AppAvatar>(find.byType(AppAvatar));
    expect(avatar.size, 80);
    expect(avatar.showGradientRing, isTrue);
    // Scroll so the lazy list builds every settings group.
    await tester.scrollUntilVisible(
      find.widgetWithText(PillButton, 'Cerrar sesión'),
      300,
    );
    await tester.pump();
    expect(find.byType(AppCard), findsAtLeastNWidgets(3));
    // Logout is an r13/h46 error button.
    final logout =
        tester.widget<PillButton>(find.widgetWithText(PillButton, 'Cerrar sesión'));
    expect(logout.color, AppColors.error);
    expect(logout.height, 46);
  });

  testWidgets('profile theme selector still opens from settings',
      (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _pumpProfile(tester);

    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar tema'), findsOneWidget);
  });
}
