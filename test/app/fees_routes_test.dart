import 'dart:async';

import 'package:efe_mobile/app/router.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_api.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/screens/fee_detail_screen.dart';
import 'package:efe_mobile/features/fees/screens/fee_list_screen.dart';
import 'package:efe_mobile/features/fees/screens/invoice_viewer_screen.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u-parent',
        name: 'María López',
        email: 'maria@test.com',
        role: 'parent',
      );

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
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

class _FakeNewsRepository implements NewsRepository {
  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination.empty();
}

class _FakeFeeApi implements FeeApi {
  @override
  Future<Response> getFees({
    String? studentId,
    String? studentAppId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) async {
    return Response(
      requestOptions: RequestOptions(path: '/fees'),
      statusCode: 200,
      data: {
        'data': [],
        'meta': {'cursor': null, 'has_more': false, 'total': 0},
      },
    );
  }

  @override
  Future<Response> getFee(String id) async {
    return Response(
      requestOptions: RequestOptions(path: '/fees/$id'),
      statusCode: 200,
      data: {
        'type': 'system_collections_fees',
        'id': id,
        'attributes': {
          'number_fee': 1,
          'month': 'Marzo',
          'year': '2026',
          'total': 25000,
          'status': 'pending',
          'student_name': 'Ana Pérez',
        },
      },
    );
  }

  @override
  Future<Response> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) async {
    return Response(
      requestOptions: RequestOptions(path: '/fees/$feeId/upload-proof'),
      statusCode: 200,
      data: {
        'data': {'id': feeId},
      },
    );
  }

  @override
  Future<Response> getInvoiceLink(String feeId) async {
    return Response(
      requestOptions: RequestOptions(path: '/fees/$feeId/invoice-link'),
      statusCode: 200,
      data: {
        'data': {'url': 'https://x/fees/$feeId/invoice-file?signature=abc'},
      },
    );
  }

  @override
  Future<Response<List<int>>> getInvoiceBytes(String url) {
    // Nunca completa: el visor queda en loading y no intenta cargar PDFium
    // nativo en el entorno de tests.
    return Completer<Response<List<int>>>().future;
  }
}

List<String> collectRoutePaths(GoRouter router) {
  final paths = <String>[];
  void walk(List<RouteBase> routes, String prefix) {
    for (final r in routes) {
      if (r is GoRoute) {
        final full = r.path.startsWith('/')
            ? r.path
            : (prefix.endsWith('/') ? '$prefix${r.path}' : '$prefix/${r.path}');
        final normalized = full.replaceAll('//', '/');
        paths.add(normalized);
        walk(r.routes, normalized);
      } else if (r is StatefulShellRoute) {
        for (final branch in r.branches) {
          walk(branch.routes, prefix);
        }
      }
    }
  }

  walk(router.configuration.routes, '');
  return paths;
}

class _FakeEmptyRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination.empty();
}

Future<ProviderContainer> _pumpFeesApp(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      relationsRepositoryProvider
          .overrideWithValue(_FakeEmptyRelationsRepository()),
      homeCalendarProvider.overrideWith((ref) async => <EventModel>[]),
      homeDocumentsProvider.overrideWith((ref) async => <DocumentModel>[]),
      todayBirthdaysProvider.overrideWith((ref) async => <BirthdayModel>[]),
      newsListProvider
          .overrideWith((ref) => NewsListNotifier(_FakeNewsRepository())),
      unreadCountProvider.overrideWith((ref) async => 0),
      feeRepositoryProvider.overrideWithValue(FeeRepository(_FakeFeeApi())),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(routerProvider),
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('router exposes /fees and /fees/:id', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    final paths = collectRoutePaths(router);
    expect(paths, contains('/fees'));
    expect(paths, contains('/fees/:id'));
    expect(paths, contains('/payments'));
    expect(paths, contains('/payments/:id'));
    expect(paths, contains('/payments/:id/invoice'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  testWidgets('navigating to /fees shows FeeListScreen', (tester) async {
    final container = await _pumpFeesApp(tester);
    final router = container.read(routerProvider);
    router.go('/fees');
    await tester.pumpAndSettle();
    expect(find.byType(FeeListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigating to /fees/f1 shows FeeDetailScreen', (tester) async {
    final container = await _pumpFeesApp(tester);
    final router = container.read(routerProvider);
    router.go('/fees/f1');
    await tester.pumpAndSettle();
    expect(find.byType(FeeDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigating to /payments/f1/invoice shows InvoiceViewerScreen',
      (tester) async {
    final container = await _pumpFeesApp(tester);
    final router = container.read(routerProvider);
    router.go('/payments/f1/invoice');
    // El visor queda en loading (spinner animado): no usar pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(InvoiceViewerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('FeeModel parses detail payload', () {
    final fee = FeeModel.fromJson({
      'id': 'f1',
      'attributes': {'number_fee': 1, 'status': 'pending', 'total': 25000},
    });
    expect(fee.id, 'f1');
    expect(fee.numberFee, 1);
  });
}
