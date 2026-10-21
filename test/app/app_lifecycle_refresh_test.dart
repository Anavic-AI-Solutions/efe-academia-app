import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/app/app.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/realtime/realtime_providers.dart';
import 'package:efe_mobile/core/realtime/realtime_service.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/chat/data/chat_api.dart';
import 'package:efe_mobile/features/chat/data/chat_repository.dart';
import 'package:efe_mobile/features/chat/domain/chat_model.dart';
import 'package:efe_mobile/features/chat/domain/message_model.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

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
        id: '1',
        name: 'Alumna Test',
        email: 'alumna@test.com',
        role: 'student',
      );

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      getCurrentUser();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      getCurrentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboard() async => const DashboardData();
}

/// Records every badge read so the test can prove the resume invalidated it.
class _FakeChatApi implements ChatApi {
  int unreadCalls = 0;

  @override
  Future<int> getUnreadCount() async {
    unreadCalls++;
    return 0;
  }

  @override
  Future<void> markRead(String chatId) async {}

  @override
  Future<Response> getChats({String? cursor, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> getMessages(String chatId,
          {String? cursor, int limit = 50}) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());

  @override
  Future<Response> createPrivateChat({required int withUserId}) =>
      Future.error(UnimplementedError());
}

/// Records the cursor of every chat-list request: the resume refresh must be a
/// first page (cursor == null).
class _FakeChatRepository implements ChatRepository {
  final List<String?> cursors = <String?>[];

  @override
  Future<CursorPagination<ChatModel>> getChats({String? cursor}) async {
    cursors.add(cursor);
    return CursorPagination<ChatModel>(data: const [], hasMore: false);
  }

  @override
  Future<CursorPagination<MessageModel>> getMessages(
    String chatId, {
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<MessageModel> sendMessage(String chatId, String body) =>
      Future.error(UnimplementedError());
}

class _FakeSubscription implements Subscription {
  @override
  void cancel() {}

  @override
  Subscription listen(String event, ReverbEventCallback callback) => this;

  @override
  Subscription listenForWhisper(String event, ReverbEventCallback callback) =>
      this;

  @override
  Subscription listenAll(ReverbWildcardCallback callback) => this;
}

class _FakeRealtimeService implements RealtimeService {
  @override
  bool get isConnected => false;

  @override
  Stream<ReverbState> get states => const Stream<ReverbState>.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect({bool forget = false}) async {}

  @override
  Subscription watchChat({
    required String chatId,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onRead,
    required void Function(Map<String, dynamic> data) onTyping,
  }) =>
      _FakeSubscription();

  @override
  Subscription watchNotifications({
    required String userId,
    required void Function() onNotification,
  }) =>
      _FakeSubscription();

  @override
  VoidCallback addReconnectListener(void Function() listener) => () {};

  @override
  void sendTyping({
    required String chatId,
    required bool typing,
    required String userId,
  }) {}
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _Harness {
  _Harness(this.api, this.repository, this.notificationUnreadCalls);

  final _FakeChatApi api;
  final _FakeChatRepository repository;
  final List<int> notificationUnreadCalls;
}

Future<_Harness> _pumpApp(WidgetTester tester) async {
  final api = _FakeChatApi();
  final repository = _FakeChatRepository();
  final notificationUnreadCalls = <int>[];
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      unreadCountProvider.overrideWith((ref) async {
        notificationUnreadCalls.add(1);
        return 0;
      }),
      chatApiProvider.overrideWithValue(api),
      chatRepositoryProvider.overrideWithValue(repository),
      realtimeServiceProvider.overrideWithValue(_FakeRealtimeService()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const EfeApp(),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(api, repository, notificationUnreadCalls);
}

void main() {
  testWidgets('resuming the app refreshes the unread badge and the chat list',
      (tester) async {
    final harness = await _pumpApp(tester);

    // The nav mounted and asked for the counter once; the chat tab was never
    // opened, so its list has not been fetched yet.
    expect(harness.api.unreadCalls, 1);
    expect(harness.repository.cursors, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // The badge was invalidated (read again)...
    expect(harness.api.unreadCalls, 2);
    // ...and the list was refreshed from its first page.
    expect(harness.repository.cursors, [null, null]);
  });

  testWidgets('resuming the app refreshes the notification badge',
      (tester) async {
    final harness = await _pumpApp(tester);

    expect(harness.notificationUnreadCalls, hasLength(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(harness.notificationUnreadCalls, hasLength(2));
  });
}
