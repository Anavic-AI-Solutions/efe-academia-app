import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_birthdays_section.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_calendar_section.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_documents_section.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_news_section.dart';
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
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination(data: items, hasMore: false);
}

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HomeCalendarSection(),
                  HomeBirthdaysSection(),
                  HomeNewsSection(),
                  HomeDocumentsSection(),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/events',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Events screen'))),
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

Future<void> _pumpHomeSections(
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

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('Aislamiento de secciones del home', () {
    testWidgets('sección en error no tumba el home', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpHomeSections(
        tester,
        router,
        calendar: (ref) async => const [
          EventModel(id: 'e1', title: 'Acto escolar'),
        ],
        birthdays: (ref) => Future<List<BirthdayModel>>.error(
          Exception('backend de cumpleaños caído'),
        ),
        news: [
          const NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
        documents: (ref) async => const [
          DocumentModel(id: 'd1', title: 'Reglamento'),
        ],
      );

      // Las otras 3 secciones siguen visibles con sus datos.
      expect(find.text('Acto escolar'), findsOneWidget);
      expect(find.text('Novedad 1'), findsOneWidget);
      expect(find.text('Reglamento'), findsOneWidget);
      // Cumpleaños cae a su fallback aislado, sin romper el home.
      expect(find.text('CUMPLEAÑOS'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cumpleaños no disponible muestra próximamente', (
      tester,
    ) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpHomeSections(
        tester,
        router,
        birthdaysAvailable: false,
        news: [
          const NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
      );

      expect(find.text('Disponible próximamente'), findsOneWidget);
      expect(find.text('Novedad 1'), findsOneWidget);
      expect(find.text('No hay próximos eventos'), findsOneWidget);
      expect(find.text('No hay documentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('orden de secciones del home', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpHomeSections(
        tester,
        router,
        calendar: (ref) async => const [
          EventModel(id: 'e1', title: 'Acto escolar'),
        ],
        birthdays: (ref) async => const [
          BirthdayModel(id: 'b1', name: 'Ana Ruiz', ageTurning: 8),
        ],
        news: [
          const NewsModel(id: 'n1', title: 'Novedad 1', content: 'Contenido 1'),
        ],
        documents: (ref) async => const [
          DocumentModel(id: 'd1', title: 'Reglamento'),
        ],
      );

      // Orden final: calendario → cumpleaños → novedades → documentos.
      expect(_top(tester, 'CALENDARIO'), lessThan(_top(tester, 'CUMPLEAÑOS')));
      expect(_top(tester, 'CUMPLEAÑOS'), lessThan(_top(tester, 'NOVEDADES')));
      expect(_top(tester, 'NOVEDADES'), lessThan(_top(tester, 'DOCUMENTOS')));
      expect(tester.takeException(), isNull);
    });
  });
}
