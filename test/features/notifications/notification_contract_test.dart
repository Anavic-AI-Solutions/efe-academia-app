import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/notifications/data/notification_api.dart';
import 'package:efe_mobile/features/notifications/data/notification_repository.dart';
import 'package:efe_mobile/features/notifications/domain/notification_model.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Transporte que devuelve el JSON ya decodificado, sin salir a la red.
class _StubApiClient extends ApiClient {
  _StubApiClient(this.payload) : super(_FakeSecureStorage());

  Object? payload;

  @override
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: payload,
    );
  }
}

NotificationRepository _repositoryWith(Object? payload) {
  return NotificationRepository(NotificationApi(_StubApiClient(payload)));
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({required this.unreadCount});

  int unreadCount;
  int unreadCountCalls = 0;
  int markAllReadCalls = 0;
  final List<String> markedRead = <String>[];

  @override
  Future<CursorPagination<NotificationModel>> getNotifications({
    String? cursor,
  }) async {
    return CursorPagination<NotificationModel>(
      data: [
        NotificationModel(
          id: 'n1',
          title: 'Cuota pendiente',
          body: 'Tenés una cuota por vencer',
          createdAt: DateTime(2026, 10, 19, 12),
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    unreadCountCalls++;
    return unreadCount;
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalls++;
    unreadCount = 0;
  }

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    if (unreadCount > 0) unreadCount--;
  }
}

void main() {
  test('notification model reads the backend is_read attribute', () {
    final model = NotificationModel.fromJson({
      'type': 'app_notification',
      'id': 'n1',
      'attributes': {
        'type': 'fee',
        'title': 'Cuota pendiente',
        'body': 'Tenés una cuota por vencer',
        'is_read': true,
        'created_at': '2026-10-19T12:00:00.000000Z',
      },
    });

    expect(model.read, isTrue);
    expect(model.title, 'Cuota pendiente');
    expect(model.id, 'n1');
  });

  test('notification unread count parses the data.count envelope', () async {
    dotenv.testLoad(fileInput: '');
    final repository = _repositoryWith({
      'data': {'count': 4},
    });

    expect(await repository.getUnreadCount(), 4);
  });

  test('marking all notifications read invalidates the unread badge', () async {
    final repository = _FakeNotificationRepository(unreadCount: 2);
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(unreadCountProvider.future), 2);

    await container.read(notificationListProvider.notifier).markAllRead();

    expect(repository.markAllReadCalls, 1);
    expect(await container.read(unreadCountProvider.future), 0);
  });

  test('marking one notification read invalidates the unread badge', () async {
    final repository = _FakeNotificationRepository(unreadCount: 2);
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(unreadCountProvider.future), 2);

    await container.read(notificationListProvider.notifier).markRead('n1');

    expect(repository.markedRead, ['n1']);
    expect(await container.read(unreadCountProvider.future), 1);
  });
}
