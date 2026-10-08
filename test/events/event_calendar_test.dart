import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/events/data/event_api.dart';
import 'package:efe_mobile/features/events/data/event_repository.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

/// Stub transport so the real [EventApi] envelope parsing is exercised.
class _StubApiClient extends ApiClient {
  _StubApiClient(this.data) : super(_FakeSecureStorage());

  Object? data;
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );
  }
}

class _FakeEventApi implements EventApi {
  _FakeEventApi(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<Response> getEvents({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<Response> getCalendar({
    required String startDate,
    required String endDate,
  }) async =>
      Response(
        requestOptions: RequestOptions(path: '/events/calendar'),
        statusCode: 200,
        data: payload,
      );
}

void main() {
  group('EventApi.getCalendar', () {
    test('pide /events/calendar con start_date y end_date', () async {
      dotenv.testLoad(fileInput: '');
      final client = _StubApiClient({'data': []});
      final api = EventApi(client);

      await api.getCalendar(startDate: '2026-10-08', endDate: '2026-11-07');

      expect(client.lastPath, '/events/calendar');
      expect(client.lastQueryParameters?['start_date'], '2026-10-08');
      expect(client.lastQueryParameters?['end_date'], '2026-11-07');
    });
  });

  group('EventRepository.getCalendarEvents', () {
    test('parsea start_date del calendario', () async {
      final repository = EventRepository(
        _FakeEventApi({
          'data': [
            {
              'id': 'e1',
              'attributes': {
                'title': 'Acto',
                'start_date': '2026-10-10T09:00:00',
                'color': '#FF0000',
              },
            },
          ],
        }),
      );

      final events = await repository.getCalendarEvents(
        startDate: '2026-10-08',
        endDate: '2026-11-07',
      );

      expect(events, hasLength(1));
      expect(events.single.title, 'Acto');
      expect(events.single.start, DateTime(2026, 10, 10, 9));
    });

    test('mantiene compatibilidad con start/end', () {
      final event = EventModel.fromJson({
        'id': 'e2',
        'attributes': {
          'title': 'Viejo',
          'start': '2026-09-01T10:00:00',
          'end': '2026-09-01T12:00:00',
        },
      });

      expect(event.start, DateTime(2026, 9, 1, 10));
      expect(event.end, DateTime(2026, 9, 1, 12));
    });
  });
}
