import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/utils/upload_file.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/news/screens/news_list_screen.dart';
import 'package:efe_mobile/features/news/screens/widgets/news_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../helpers/localized_app.dart';

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

class _FakeNewsRepository implements NewsRepository {
  _FakeNewsRepository(this.items);

  List<NewsModel> items;
  String? deletedId;
  Map<String, Object?>? createdArgs;

  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination<NewsModel>(data: items, hasMore: false);

  @override
  Future<NewsModel> createNews({
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async {
    createdArgs = {'title': title, 'content': content};
    return NewsModel(id: 'n2', title: title, content: content);
  }

  @override
  Future<NewsModel> updateNews(
    String id, {
    required String title,
    required String description,
    required String content,
    DateTime? eventDate,
    UploadFile? image,
  }) async =>
      NewsModel(id: id, title: title, content: content);

  @override
  Future<void> deleteNews(String id) async {
    deletedId = id;
  }
}

List<NewsModel> _items() => const [
      NewsModel(id: 'n1', title: 'Primera noticia', content: 'Cuerpo uno'),
      NewsModel(id: 'n2', title: 'Segunda noticia', content: 'Cuerpo dos'),
    ];

Future<_FakeNewsRepository> _pumpList(
  WidgetTester tester, {
  required String role,
  List<NewsModel>? items,
  _FakeNewsRepository? repository,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? _FakeNewsRepository(items ?? _items());
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
      newsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const NewsListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('admin ve el FAB de creación', (tester) async {
    await _pumpList(tester, role: 'admin');

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('news-menu-n1')), findsOneWidget);
  });

  testWidgets('branch ve el FAB de creación', (tester) async {
    await _pumpList(tester, role: 'branch');

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  for (final role in ['parent', 'student', 'professor']) {
    testWidgets('$role no ve FAB ni acciones', (tester) async {
      await _pumpList(tester, role: role);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('news-menu-n1')), findsNothing);
      expect(find.byKey(const Key('news-menu-n2')), findsNothing);
    });
  }

  testWidgets('admin abre el formulario desde el FAB', (tester) async {
    await _pumpList(tester, role: 'admin');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(NewsFormSheet), findsOneWidget);
    expect(find.text('Nueva noticia'), findsOneWidget);
  });

  testWidgets('crear desde la lista muestra el snackbar de creado',
      (tester) async {
    final repo = await _pumpList(tester, role: 'admin');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('news-title-field')), 'Nueva');
    await tester.enterText(
      find.byKey(const Key('news-content-field')),
      'Cuerpo',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.createdArgs, isNotNull);
    expect(find.text('Noticia creada'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación y llama al repositorio',
      (tester) async {
    final repo = await _pumpList(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('news-menu-n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar noticia'), findsOneWidget);
    expect(repo.deletedId, isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.deletedId, 'n1');
    expect(find.text('Noticia eliminada'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repo = await _pumpList(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('news-menu-n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.deletedId, isNull);
  });

  testWidgets('sin mediaUrls la card usa el placeholder', (tester) async {
    await _pumpList(tester, role: 'parent');

    expect(find.byIcon(PhosphorIconsRegular.newspaper), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('con mediaUrls la card muestra la imagen', (tester) async {
    await _pumpList(
      tester,
      role: 'parent',
      items: const [
        NewsModel(
          id: 'n1',
          title: 'Con foto',
          content: 'Cuerpo',
          mediaUrls: ['https://cdn.example.com/news/foto.png'],
        ),
      ],
    );

    expect(find.byKey(const Key('news-image-n1')), findsOneWidget);
  });
}
