import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/parent_summary_sections.dart';
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

class _ThrowingNewsRepository implements NewsRepository {
  int calls = 0;

  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async {
    calls++;
    throw Exception('network error');
  }
}

Future<void> _pumpSections(
  WidgetTester tester,
  GoRouter router, {
  Future<List<DocumentModel>> Function(Ref ref)? documents,
  Future<List<EventModel>> Function(Ref ref)? calendar,
  NewsRepository? newsRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeDocumentsProvider.overrideWith(
          documents ?? (ref) async => const [],
        ),
        homeCalendarProvider.overrideWith(
          calendar ?? (ref) async => const [],
        ),
        newsListProvider.overrideWith(
          (ref) => NewsListNotifier(
            newsRepository ?? _FakeNewsRepository(const []),
          ),
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

const _doc = DocumentModel(id: 'd1', title: 'Contrato 2026');

List<EventModel> _events() => [
      EventModel(
        id: 'e1',
        title: 'Reunión de padres',
        start: DateTime(2026, 11, 3, 18, 30),
      ),
    ];

List<NewsModel> _news() => const [
      NewsModel(
        id: 'n1',
        title: 'Nueva noticia',
        content: 'Contenido de la noticia',
      ),
    ];
GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: ParentSummarySections()),
          ),
        ),
        GoRoute(
          path: '/documents',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Documents screen'))),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, s) => Scaffold(
                body: Center(child: Text('document:${s.pathParameters['id']}')),
              ),
            ),
          ],
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
      ],
    );

void main() {
  testWidgets('muestra 1 doc, 1 evento, 1 news con Ver-todo', (tester) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDocumentsProvider.overrideWith(
            (ref) async => const [
              DocumentModel(id: 'd1', title: 'Contrato 2026'),
            ],
          ),
          homeCalendarProvider.overrideWith(
            (ref) async => [
              EventModel(
                id: 'e1',
                title: 'Reunión de padres',
                start: DateTime(2026, 11, 3, 18, 30),
              ),
            ],
          ),
          newsListProvider.overrideWith(
            (ref) => NewsListNotifier(_FakeNewsRepository(const [
              NewsModel(
                id: 'n1',
                title: 'Nueva noticia',
                content: 'Contenido de la noticia',
              ),
            ])),
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

    // SectionHeader renderiza el título en mayúsculas.
    expect(find.text('DOCUMENTOS'), findsOneWidget);
    expect(find.text('CALENDARIO'), findsOneWidget);
    expect(find.text('NOVEDADES'), findsOneWidget);
    expect(find.text('Ver todo'), findsNWidgets(3));
    expect(find.text('Contrato 2026'), findsOneWidget);
    expect(find.text('Reunión de padres'), findsOneWidget);
    expect(find.text('Nueva noticia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secciones vacías muestran fallback sin crashear',
      (tester) async {
    final router = _router();
    addTearDown(router.dispose);

    await _pumpSections(tester, router);

    expect(find.text('No hay documentos'), findsOneWidget);
    expect(find.text('No hay próximos eventos'), findsOneWidget);
    expect(find.text('No hay novedades'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error en documentos muestra retry y reintenta', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    var calls = 0;

    await _pumpSections(
      tester,
      router,
      documents: (ref) async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return const [_doc];
      },
      calendar: (ref) async => _events(),
      newsRepository: _FakeNewsRepository(_news()),
    );

    expect(find.text('Documentos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Contrato 2026'), findsNothing);
    expect(find.text('Reunión de padres'), findsOneWidget);
    expect(find.text('Nueva noticia'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Contrato 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error en eventos muestra título y retry sin tumbar resto',
      (tester) async {
    final router = _router();
    addTearDown(router.dispose);

    await _pumpSections(
      tester,
      router,
      documents: (ref) async => const [_doc],
      calendar: (ref) async => throw Exception('boom'),
      newsRepository: _FakeNewsRepository(_news()),
    );

    expect(find.text('No se pudieron cargar los eventos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Contrato 2026'), findsOneWidget);
    expect(find.text('Nueva noticia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error en novedades muestra retry sin tumbar resto',
      (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    final newsRepo = _ThrowingNewsRepository();

    await _pumpSections(
      tester,
      router,
      documents: (ref) async => const [_doc],
      calendar: (ref) async => _events(),
      newsRepository: newsRepo,
    );

    expect(find.text('No se pudieron cargar las noticias'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Contrato 2026'), findsOneWidget);
    expect(find.text('Reunión de padres'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(newsRepo.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap en documento abre el detalle', (tester) async {
    final router = _router();
    addTearDown(router.dispose);

    await _pumpSections(
      tester,
      router,
      documents: (ref) async => const [_doc],
      calendar: (ref) async => _events(),
      newsRepository: _FakeNewsRepository(_news()),
    );

    await tester.tap(find.text('Contrato 2026'));
    await tester.pumpAndSettle();

    expect(find.text('document:d1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
