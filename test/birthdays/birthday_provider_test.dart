import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_client.dart';
import 'package:efe_mobile/core/api/api_provider.dart';
import 'package:efe_mobile/core/storage/secure_storage.dart';
import 'package:efe_mobile/features/birthdays/data/birthday_api.dart';
import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_birthdays_section.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<String?> getFcmToken() async => null;

  @override
  Future<void> deleteFcmToken() async {}

  @override
  Future<String> getOrCreateDeviceId() async => 'test-device';

  @override
  Future<bool> hasSeenPushPrimer() async => false;

  @override
  Future<void> savePushPrimerSeen() async {}
}

/// Stub del transporte HTTP: devuelve [data] o lanza [error].
class _StubApiClient extends ApiClient {
  _StubApiClient({this.data, this.error}) : super(_FakeSecureStorage());

  Object? data;
  Object? error;
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastQueryParameters = queryParameters;
    if (error != null) throw error!;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );
  }
}

DioException _httpError(int statusCode) => DioException(
      requestOptions: RequestOptions(path: '/birthdays'),
      response: Response(
        requestOptions: RequestOptions(path: '/birthdays'),
        statusCode: statusCode,
        data: {'errors': []},
      ),
      type: DioExceptionType.badResponse,
    );

Map<String, dynamic> _birthdayJson({
  String id = 'b1',
  String name = 'Ana Ruiz',
  int ageTurning = 8,
  String? studentAppId = 's1',
  String? birthDate = '2018-10-08',
  int daysUntil = 0,
}) =>
    {
      'id': id,
      'name': name,
      'age_turning': ageTurning,
      if (studentAppId != null) 'student_app_id': studentAppId,
      if (birthDate != null) 'birth_date': birthDate,
      'days_until': daysUntil,
    };

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: HomeBirthdaysSection()),
          ),
        ),
        GoRoute(
          path: '/students/:id',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('Student ${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );

Future<void> _pumpSection(
  WidgetTester tester,
  GoRouter router,
  _StubApiClient client,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('BirthdayApi.getTodayBirthdays', () {
    test('pide /birthdays con scope=today', () async {
      final client = _StubApiClient(data: {'data': []});
      final api = BirthdayApi(client);

      await api.getTodayBirthdays();

      expect(client.lastPath, '/birthdays');
      expect(client.lastQueryParameters?['scope'], 'today');
    });
  });

  group('todayBirthdaysProvider', () {
    test('404 de cumpleaños devuelve lista vacía disponible=false', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _StubApiClient(error: _httpError(404)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final birthdays = await container.read(todayBirthdaysProvider.future);

      expect(birthdays, isEmpty);
      expect(container.read(birthdaysAvailableProvider), isFalse);
    });

    test('501 también cae al fallback sin error rojo', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _StubApiClient(error: _httpError(501)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final birthdays = await container.read(todayBirthdaysProvider.future);

      expect(birthdays, isEmpty);
      expect(container.read(birthdaysAvailableProvider), isFalse);
    });

    test('respuesta exitosa parsea cumpleaños y marca disponible', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _StubApiClient(
              data: {
                'data': [_birthdayJson()],
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final birthdays = await container.read(todayBirthdaysProvider.future);

      expect(birthdays, hasLength(1));
      expect(birthdays.single.name, 'Ana Ruiz');
      expect(birthdays.single.ageTurning, 8);
      expect(birthdays.single.studentAppId, 's1');
      expect(container.read(birthdaysAvailableProvider), isTrue);
    });

    test('otro error (500) sí se propaga a la sección', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _StubApiClient(error: _httpError(500)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(todayBirthdaysProvider.future),
        throwsA(isA<DioException>()),
      );
    });

    test('nombre no-string no lanza TypeError', () {
      final model = BirthdayModel.fromJson({
        'id': 'b9',
        'attributes': {'name': 123, 'age_turning': 8},
      });

      expect(model.name, '123');
    });
  });

  group('HomeBirthdaysSection', () {
    testWidgets('404 muestra "próximamente" sin error rojo', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(
        tester,
        router,
        _StubApiClient(error: _httpError(404)),
      );

      expect(find.text('CUMPLEAÑOS'), findsOneWidget);
      expect(find.text('Disponible próximamente'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin cumpleaños muestra vacío normal', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(tester, router, _StubApiClient(data: {'data': []}));

      expect(find.text('CUMPLEAÑOS'), findsOneWidget);
      expect(find.text('No hay cumpleaños hoy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap en cumpleaños navega al detalle del alumno',
        (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(
        tester,
        router,
        _StubApiClient(
          data: {
            'data': [_birthdayJson()],
          },
        ),
      );

      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      await tester.tap(find.text('Ana Ruiz'));
      await tester.pumpAndSettle();

      expect(find.text('Student s1'), findsOneWidget);
    });
  });
}
