import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/documents/data/document_api.dart';
import 'package:efe_mobile/features/documents/data/document_repository.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/documents/screens/document_detail_screen.dart';
import 'package:efe_mobile/features/documents/screens/document_list_screen.dart';
import 'package:efe_mobile/features/documents/screens/widgets/document_tile.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeDocumentApi implements DocumentApi {
  @override
  Future<Response> getDocument(String id) => throw UnimplementedError();

  @override
  Future<Response> getDocuments({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<Response> createDocument(FormData data) => throw UnimplementedError();

  @override
  Future<Response> updateDocument(String id, FormData data) =>
      throw UnimplementedError();

  @override
  Future<Response> deleteDocument(String id) => throw UnimplementedError();

  @override
  String downloadUrl(String id) => 'https://example.com/documents/$id/download';
}

class _FakeDocumentRepository extends DocumentRepository {
  _FakeDocumentRepository(this.docs) : super(_FakeDocumentApi());

  final List<DocumentModel> docs;

  @override
  Future<CursorPagination<DocumentModel>> getDocuments(
          {String? cursor}) async =>
      CursorPagination<DocumentModel>(data: docs, hasMore: false);

  @override
  Future<DocumentModel> getDocument(String id) async =>
      docs.firstWhere((doc) => doc.id == id);
}

List<DocumentModel> _docs() => const [
      DocumentModel(
        id: 'd1',
        title: 'Reglamento',
        description: 'Reglamento interno',
        fileUrl: 'https://example.com/r.pdf',
      ),
      DocumentModel(
        id: 'd2',
        title: 'Calendario',
        description: 'Calendario escolar',
        fileUrl: 'https://example.com/c.pdf',
      ),
    ];

GoRouter _router(List<DocumentModel> docs) => GoRouter(
      initialLocation: '/documents',
      routes: [
        GoRoute(
          path: '/documents',
          builder: (_, __) => const DocumentListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => DocumentDetailScreen(
                documentId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );

Future<void> _pumpDocuments(
  WidgetTester tester,
  GoRouter router,
  List<DocumentModel> docs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          _FakeDocumentRepository(docs),
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
  group('DocumentTile', () {
    testWidgets('documento sin archivo no rompe', (tester) async {
      const doc = DocumentModel(
        id: 'd1',
        title: 'Sin archivo',
        mediaUrls: [],
        fileUrl: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DocumentTile(document: doc, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El tile se renderiza y no hay botón de apertura.
      expect(find.text('Sin archivo'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });
  });

  group('DocumentListScreen', () {
    testWidgets('lista muestra documentos y navega al detalle', (tester) async {
      final router = _router(_docs());
      addTearDown(router.dispose);

      await _pumpDocuments(tester, router, _docs());

      expect(find.text('Reglamento'), findsOneWidget);
      expect(find.text('Calendario'), findsOneWidget);

      await tester.tap(find.text('Reglamento'));
      await tester.pumpAndSettle();

      // Navega a DocumentDetailScreen.
      expect(find.byType(DocumentDetailScreen), findsOneWidget);
      expect(find.text('Reglamento interno'), findsOneWidget);
    });
  });
}
