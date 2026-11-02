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
}
