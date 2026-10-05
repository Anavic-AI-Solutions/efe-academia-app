import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/chat/data/chat_api.dart';
import 'package:efe_mobile/features/chat/providers/chat_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Records reads/writes of the unread counter and flips it to zero when a
/// chat is opened, the same way the backend does.
class _FakeChatApi implements ChatApi {
  _FakeChatApi(this.unreadCount);

  int unreadCount;
  final List<String> markedRead = <String>[];

  @override
  Future<int> getUnreadCount() async => unreadCount;

  @override
  Future<void> markRead(String chatId) async {
    markedRead.add(chatId);
    unreadCount = 0;
  }

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

/// Stub transport so the real [ChatApi] envelope parsing is exercised.
class _StubApiClient extends ApiClient {
  _StubApiClient(this.data) : super(_FakeSecureStorage());

  Object? data;
  final List<String> getPaths = <String>[];
  final List<String> postPaths = <String>[];

  @override
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    getPaths.add(path);
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    postPaths.add(path);
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: this.data,
    );
  }
}

ProviderContainer _containerWith(ChatApi api) {
  final container = ProviderContainer(
    overrides: [chatApiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('unread badge refreshes when a chat is opened', () async {
    final api = _FakeChatApi(3);
    final container = _containerWith(api);

    expect(await container.read(chatUnreadCountProvider.future), 3);

    await container.read(chatUnreadCountControllerProvider).markRead('c1');

    expect(api.markedRead, ['c1']);
    expect(await container.read(chatUnreadCountProvider.future), 0);
  });

  test('unread badge refreshes on resume without realtime', () async {
    final api = _FakeChatApi(5);
    final container = _containerWith(api);

    expect(await container.read(chatUnreadCountProvider.future), 5);

    // The server changed the counter; no WebSocket event ever arrived.
    api.unreadCount = 1;
    container.read(chatUnreadCountControllerProvider).refresh();

    expect(await container.read(chatUnreadCountProvider.future), 1);
  });

  test('unread count parses the data.count envelope', () async {
    dotenv.testLoad(fileInput: '');
    final client = _StubApiClient({
      'data': {'count': 4},
    });
    final api = ChatApi(client);

    expect(await api.getUnreadCount(), 4);
    expect(client.getPaths, ['/chats/unread-count']);

    client.data = {'data': <String, dynamic>{}};
    expect(await ChatApi(client).getUnreadCount(), 0);

    client.data = null;
    expect(await ChatApi(client).getUnreadCount(), 0);
  });

  test('markRead posts to /chats/{id}/read', () async {
    dotenv.testLoad(fileInput: '');
    final client = _StubApiClient(null);

    await ChatApi(client).markRead('c9');

    expect(client.postPaths, ['/chats/c9/read']);
  });
}
