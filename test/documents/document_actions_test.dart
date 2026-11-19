import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/documents/data/document_repository.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/documents/screens/document_detail_screen.dart';
import 'package:efe_mobile/features/documents/screens/document_list_screen.dart';
import 'package:efe_mobile/features/documents/screens/widgets/document_form_sheet.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _NeverAuthRepository implements AuthRepository {
  @override
  Future<bool> hasToken() => Completer<bool>().future;

  @override
  Future<UserModel> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> loadTokenIntoClient() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_NeverAuthRepository());

  void seed(UserModel user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(this.items);

  List<DocumentModel> items;
  String? deletedId;
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;

  @override
  Future<CursorPagination<DocumentModel>> getDocuments(
          {String? cursor}) async =>
      CursorPagination<DocumentModel>(data: items, hasMore: false);

  @override
  Future<DocumentModel> getDocument(String id) async =>
      items.firstWhere((document) => document.id == id);

  @override
  String downloadUrl(String id) => 'https://example.com/documents/$id/download';

  @override
  Future<DocumentModel> createDocument({
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    createdArgs = {
      'title': title,
      'description': description,
      'file': file,
    };
    return DocumentModel(id: 'd3', title: title, description: description);
  }

  @override
  Future<DocumentModel> updateDocument(
    String id, {
    required String title,
    String description = '',
    UploadFile? file,
  }) async {
    updatedId = id;
    updatedArgs = {
      'title': title,
      'description': description,
      'file': file,
    };
    return DocumentModel(id: id, title: title, description: description);
  }

  @override
  Future<void> deleteDocument(String id) async {
    deletedId = id;
    items = items.where((document) => document.id != id).toList();
  }
}

List<DocumentModel> _documents() => const [
      DocumentModel(
        id: 'd1',
        title: 'Reglamento',
        description: 'Reglamento interno',
        fileUrl: 'https://example.com/documents/reglamento.pdf',
      ),
      DocumentModel(
        id: 'd2',
        title: 'Calendario',
        description: 'Calendario escolar',
        fileUrl: 'https://example.com/documents/calendario.pdf',
      ),
    ];

GoRouter _router() => GoRouter(
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

Future<_FakeDocumentRepository> _pumpDocuments(
  WidgetTester tester, {
  required String role,
  List<DocumentModel>? items,
  _FakeDocumentRepository? repository,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? _FakeDocumentRepository(items ?? _documents());
  final auth = _TestAuthNotifier()
    ..seed(UserModel(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      role: role,
    ));

  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => auth),
      documentRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  final router = _router();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _openFirstDetail(WidgetTester tester) async {
  await tester.tap(find.text('Reglamento'));
  await tester.pumpAndSettle();
}

void main() {
  for (final role in ['admin', 'branch']) {
    testWidgets('$role ve el FAB de creación', (tester) async {
      await _pumpDocuments(tester, role: role);

      expect(find.byKey(const Key('document-fab')), findsOneWidget);
    });
  }

  for (final role in ['professor', 'parent', 'student']) {
    testWidgets('$role no ve FAB ni acciones', (tester) async {
      await _pumpDocuments(tester, role: role);

      expect(find.byKey(const Key('document-fab')), findsNothing);

      await _openFirstDetail(tester);

      expect(find.byType(DocumentDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('document-menu')), findsNothing);
    });
  }

  testWidgets('admin abre el formulario desde el FAB', (tester) async {
    await _pumpDocuments(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('document-fab')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentFormSheet), findsOneWidget);
    expect(find.text('Nuevo documento'), findsOneWidget);
  });

  testWidgets('crear desde la lista muestra el snackbar de creado',
      (tester) async {
    final repo = await _pumpDocuments(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('document-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('document-title-field')),
      'Nuevo documento',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.createdArgs, isNotNull);
    expect(find.text('Documento creado'), findsOneWidget);
  });

  testWidgets('staff ve el menú de acciones en el detalle', (tester) async {
    await _pumpDocuments(tester, role: 'admin');

    await _openFirstDetail(tester);

    expect(find.byKey(const Key('document-menu')), findsOneWidget);
  });

  testWidgets('editar desde el detalle abre el formulario prellenado',
      (tester) async {
    await _pumpDocuments(tester, role: 'admin');

    await _openFirstDetail(tester);
    await tester.tap(find.byKey(const Key('document-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentFormSheet), findsOneWidget);
    expect(find.text('Editar documento'), findsOneWidget);
    expect(find.text('Reglamento interno'), findsWidgets);
  });

  testWidgets('eliminar desde el detalle pide confirmación, invalida y vuelve',
      (tester) async {
    final repo = await _pumpDocuments(tester, role: 'admin');

    await _openFirstDetail(tester);
    await tester.tap(find.byKey(const Key('document-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar documento'), findsOneWidget);
    expect(repo.deletedId, isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.deletedId, 'd1');
    expect(find.byType(DocumentDetailScreen), findsNothing);
    expect(find.byType(DocumentListScreen), findsOneWidget);
    expect(find.text('Documento eliminado'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repo = await _pumpDocuments(tester, role: 'admin');

    await _openFirstDetail(tester);
    await tester.tap(find.byKey(const Key('document-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.deletedId, isNull);
    expect(find.byType(DocumentDetailScreen), findsOneWidget);
  });
}
