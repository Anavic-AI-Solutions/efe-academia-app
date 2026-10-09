import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_summary_grid.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeNewsRepository implements NewsRepository {
  final List<NewsModel> items;

  _FakeNewsRepository(this.items);

  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async {
    return CursorPagination(data: items, hasMore: false);
  }
}

/// Router con las 4 vistas destino del grid para asertar navegación.
GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: HomeSummaryGrid()),
        ),
        GoRoute(
          path: '/calendar',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Calendar screen'))),
        ),
        GoRoute(
          path: '/birthdays',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Birthdays screen'))),
        ),
        GoRoute(
          path: '/news',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('News screen'))),
        ),
        GoRoute(
          path: '/documents',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Documents screen'))),
        ),
      ],
    );

Future<void> _pumpGrid(
  WidgetTester tester,
  GoRouter router, {
  Future<List<EventModel>> Function(Ref ref)? calendar,
  Future<List<BirthdayModel>> Function(Ref ref)? birthdays,
  bool birthdaysAvailable = true,
  List<NewsModel> news = const [],
  Future<List<DocumentModel>> Function(Ref ref)? documents,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeCalendarProvider.overrideWith(
          calendar ?? (ref) async => <EventModel>[],
        ),
        todayBirthdaysProvider.overrideWith(
          birthdays ?? (ref) async => <BirthdayModel>[],
        ),
        birthdaysAvailableProvider.overrideWith((ref) => birthdaysAvailable),
        newsListProvider
            .overrideWith((ref) => NewsListNotifier(_FakeNewsRepository(news))),
        homeDocumentsProvider.overrideWith(
          documents ?? (ref) async => <DocumentModel>[],
        ),
      ],
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
  group('HomeSummaryGrid', () {
    testWidgets('renderiza 4 tarjetas con sus resúmenes', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpGrid(
        tester,
        router,
        calendar: (ref) async => [
          EventModel(
            id: 'e1',
            title: 'Acto escolar',
            start: DateTime(2026, 10, 15, 10),
          ),
        ],
        birthdays: (ref) async => const [
          BirthdayModel(id: 'b1', name: 'Ana Ruiz', ageTurning: 8),
        ],
        news: const [
          NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
        documents: (ref) async => const [
          DocumentModel(id: 'd1', title: 'Reglamento'),
          DocumentModel(id: 'd2', title: 'Protocolo'),
        ],
      );

      expect(find.textContaining('Acto escolar'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Novedad 1'), findsOneWidget);
      expect(find.text('2 documentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap en cada tarjeta navega a su vista', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpGrid(
        tester,
        router,
        calendar: (ref) async => const [
          EventModel(id: 'e1', title: 'Acto escolar'),
        ],
        birthdays: (ref) async => const [
          BirthdayModel(id: 'b1', name: 'Ana Ruiz', ageTurning: 8),
        ],
        news: const [
          NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
        documents: (ref) async => const [
          DocumentModel(id: 'd1', title: 'Reglamento'),
        ],
      );

      await tester.tap(find.textContaining('Acto escolar'));
      await tester.pumpAndSettle();
      expect(find.text('Calendar screen'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana Ruiz'));
      await tester.pumpAndSettle();
      expect(find.text('Birthdays screen'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novedad 1'));
      await tester.pumpAndSettle();
      expect(find.text('News screen'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 documento'));
      await tester.pumpAndSettle();
      expect(find.text('Documents screen'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('una fuente en error no rompe el grid', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpGrid(
        tester,
        router,
        calendar: (ref) => Future<List<EventModel>>.error(
          Exception('calendario caído'),
        ),
        birthdays: (ref) async => const [
          BirthdayModel(id: 'b1', name: 'Ana Ruiz', ageTurning: 8),
        ],
        news: const [
          NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
        documents: (ref) async => const [
          DocumentModel(id: 'd1', title: 'Reglamento'),
        ],
      );

      // Las otras 3 tarjetas siguen visibles con sus datos.
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Novedad 1'), findsOneWidget);
      expect(find.text('1 documento'), findsOneWidget);
      // La tarjeta de calendario cae a su fallback compacto.
      expect(find.text('CALENDARIO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cumpleaños no disponible muestra próximamente', (
      tester,
    ) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpGrid(tester, router, birthdaysAvailable: false);

      expect(find.text('Disponible próximamente'), findsOneWidget);
      expect(find.text('No hay próximos eventos'), findsOneWidget);
      expect(find.text('No hay novedades'), findsOneWidget);
      expect(find.text('No hay documentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
