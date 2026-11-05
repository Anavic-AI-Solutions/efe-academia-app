import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/features/statistics/data/statistics_api.dart';
import 'package:efe_mobile/features/statistics/data/statistics_repository.dart';
import 'package:efe_mobile/features/statistics/domain/statistics_model.dart';
import 'package:efe_mobile/features/statistics/providers/statistics_provider.dart';
import 'package:efe_mobile/features/statistics/screens/statistics_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/statistics/dashboard'),
      statusCode: 200,
      data: data,
    );

class _FakeStatisticsApi implements StatisticsApi {
  _FakeStatisticsApi(this.payload);

  final Object? payload;

  @override
  Future<Response> getDashboard() async => _response(payload);
}

class _FakeStatisticsRepository implements StatisticsRepository {
  _FakeStatisticsRepository(this.data);

  final StatisticsModel data;

  @override
  Future<StatisticsModel> getDashboard() async => data;
}

class _DelayedStatisticsRepository implements StatisticsRepository {
  _DelayedStatisticsRepository(this.future);

  final Future<StatisticsModel> future;

  @override
  Future<StatisticsModel> getDashboard() => future;
}

Future<void> _pumpStatistics(
  WidgetTester tester,
  StatisticsRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      statisticsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StatisticsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StatisticsModel', () {
    test('missing metrics and details become empty maps', () {
      final model = StatisticsModel.fromJson(const {});

      expect(model.metrics, isEmpty);
      expect(model.details, isEmpty);
      expect(model.role, '');
      expect(model.isEmpty, isTrue);
    });

    test('empty PHP arrays (lists) become empty maps', () {
      final model = StatisticsModel.fromJson(const {
        'role': 'student',
        'metrics': [],
        'details': [],
      });

      expect(model.metrics, isEmpty);
      expect(model.details, isEmpty);
      expect(model.isEmpty, isTrue);
    });

    test('keeps populated metrics and details', () {
      final model = StatisticsModel.fromJson(const {
        'role': 'admin',
        'metrics': {'total_students': 42, 'fees_overdue': 3},
        'details': {
          'myGradesBySubject': <Object>[],
          'children': [
            {'child_name': 'Ana', 'total_absences': 2},
          ],
        },
      });

      expect(model.metrics['total_students'], 42);
      expect(model.details['children'], isA<List<dynamic>>());
    });
  });

  group('StatisticsRepository', () {
    test('unwraps the data envelope', () async {
      final repository = StatisticsRepository(
        _FakeStatisticsApi(const {
          'data': {
            'role': 'parent',
            'metrics': {'children_count': 2},
            'details': [],
          },
        }),
      );

      final model = await repository.getDashboard();

      expect(model.role, 'parent');
      expect(model.metrics['children_count'], 2);
      expect(model.details, isEmpty);
    });

    test('accepts a missing details key', () async {
      final repository = StatisticsRepository(
        _FakeStatisticsApi(const {
          'data': {
            'role': 'professor',
            'metrics': [],
          },
        }),
      );

      final model = await repository.getDashboard();

      expect(model.metrics, isEmpty);
      expect(model.details, isEmpty);
      expect(model.isEmpty, isTrue);
    });
  });

  group('StatisticsListNotifier', () {
    test('load marks hasLoaded even when the dashboard is empty', () async {
      final notifier = StatisticsListNotifier(
        _FakeStatisticsRepository(StatisticsModel.empty()),
      );

      await notifier.load();

      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.data.isEmpty, isTrue);
    });

    test('disposing the provider during a request does not throw', () async {
      final completer = Completer<StatisticsModel>();
      final container = ProviderContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWithValue(
            _DelayedStatisticsRepository(completer.future),
          ),
        ],
      );
      container.listen(statisticsDashboardProvider, (_, __) {});

      final pending =
          container.read(statisticsDashboardProvider.notifier).load();
      container.dispose();
      completer.complete(StatisticsModel.empty());

      await pending;
    });
  });

  testWidgets('empty metrics and details render the empty state',
      (tester) async {
    await _pumpStatistics(
        tester, _FakeStatisticsRepository(StatisticsModel.empty()));

    expect(find.text('Sin estadísticas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty detail lists do not crash the screen', (tester) async {
    await _pumpStatistics(
      tester,
      _FakeStatisticsRepository(
        StatisticsModel(
          role: 'student',
          metrics: const {'total_students': 12},
          details: const {
            'filters': <String, dynamic>{},
            'myGradesBySubject': <dynamic>[],
            'myAbsenceRate': {'total': 0, 'rate': 0},
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Resumen de KPIs'), findsOneWidget);
  });
}
