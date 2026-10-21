import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/dashboard/screens/widgets/home_news_section.dart';
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

List<NewsModel> _news(int count) => List<NewsModel>.generate(
      count,
      (i) => NewsModel(
        id: 'n$i',
        title: 'Novedad $i',
        content: 'Contenido de la novedad $i con texto suficiente.',
        createdAt: DateTime(2026, 10, 1 + i),
      ),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: HomeNewsSection()),
          ),
        ),
        GoRoute(
          path: '/news',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('News screen'))),
        ),
      ],
    );

Future<void> _pumpSection(
  WidgetTester tester,
  GoRouter router,
  List<NewsModel> items,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        newsListProvider.overrideWith(
            (ref) => NewsListNotifier(_FakeNewsRepository(items))),
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
  group('HomeNewsSection', () {
    testWidgets('muestra hasta 3 novedades con ver todo', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(tester, router, _news(5));

      expect(find.text('NOVEDADES'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(find.text('Novedad $i'), findsOneWidget);
      }
      expect(find.text('Novedad 3'), findsNothing);
      expect(find.text('Novedad 4'), findsNothing);

      await tester.tap(find.text('Ver todo'));
      await tester.pumpAndSettle();

      expect(find.text('News screen'), findsOneWidget);
    });

    testWidgets('sin novedades muestra vacío', (tester) async {
      final router = _router();
      addTearDown(router.dispose);

      await _pumpSection(tester, router, const []);

      expect(find.text('NOVEDADES'), findsOneWidget);
      expect(find.text('No hay novedades'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
