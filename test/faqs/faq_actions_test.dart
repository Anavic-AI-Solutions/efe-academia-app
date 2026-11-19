import 'dart:async';

import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/pagination_bar.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/faqs/data/faq_repository.dart';
import 'package:efe_mobile/features/faqs/domain/faq_model.dart';
import 'package:efe_mobile/features/faqs/providers/faq_provider.dart';
import 'package:efe_mobile/features/faqs/screens/faq_screen.dart';
import 'package:efe_mobile/features/faqs/screens/widgets/faq_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeFaqRepository implements FaqRepository {
  _FakeFaqRepository(this.items, {int? total}) : total = total ?? items.length;

  final List<FaqModel> items;
  final int total;

  int listCalls = 0;
  String? deletedId;
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;

  @override
  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    listCalls++;
    return PageResult(
      data: items,
      page: 1,
      perPage: perPage,
      total: total,
    );
  }

  @override
  Future<FaqModel> createFaq({
    required String question,
    required String answer,
  }) async {
    createdArgs = {'question': question, 'answer': answer};
    return FaqModel(id: 'new', question: question, answer: answer);
  }

  @override
  Future<FaqModel> updateFaq(
    String id, {
    required String question,
    required String answer,
  }) async {
    updatedId = id;
    updatedArgs = {'question': question, 'answer': answer};
    return FaqModel(id: id, question: question, answer: answer);
  }

  @override
  Future<void> deleteFaq(String id) async {
    deletedId = id;
  }
}

List<FaqModel> _items() => [
      FaqModel(
        id: 'f1',
        question: '¿Cómo pago?',
        answer: 'Desde la sección Cuotas',
      ),
      FaqModel(
        id: 'f2',
        question: '¿Dónde veo las notas?',
        answer: 'En la sección Calificaciones',
      ),
    ];

Future<_FakeFaqRepository> _pumpScreen(
  WidgetTester tester, {
  required String role,
  List<FaqModel>? items,
  int? total,
  _FakeFaqRepository? repository,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final repo =
      repository ?? _FakeFaqRepository(items ?? _items(), total: total);
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
      faqRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(home: const FaqScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('admin ve el FAB y el menú en cada pregunta', (tester) async {
    await _pumpScreen(tester, role: 'admin');

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('faq-menu-f1')), findsOneWidget);
    expect(find.byKey(const Key('faq-menu-f2')), findsOneWidget);
  });

  for (final role in ['branch', 'professor', 'parent', 'student']) {
    testWidgets('$role no ve FAB ni menús', (tester) async {
      await _pumpScreen(tester, role: role);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('faq-menu-f1')), findsNothing);
      expect(find.byKey(const Key('faq-menu-f2')), findsNothing);
    });
  }

  testWidgets('tocar la pregunta sigue expandiendo la respuesta',
      (tester) async {
    await _pumpScreen(tester, role: 'admin');

    AnimatedCrossFade crossFade() =>
        tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade).first);

    expect(crossFade().crossFadeState, CrossFadeState.showFirst);

    await tester.tap(find.text('¿Cómo pago?'));
    await tester.pumpAndSettle();

    expect(crossFade().crossFadeState, CrossFadeState.showSecond);
  });

  testWidgets('editar abre el formulario prellenado', (tester) async {
    await _pumpScreen(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('faq-menu-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.byType(FaqFormSheet), findsOneWidget);
    expect(find.text('Editar pregunta'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FaqFormSheet),
        matching: find.text('¿Cómo pago?'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(FaqFormSheet),
        matching: find.text('Desde la sección Cuotas'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('eliminar pide confirmación, recarga la lista y avisa',
      (tester) async {
    final repo = await _pumpScreen(tester, role: 'admin');
    expect(repo.listCalls, 1);

    await tester.tap(find.byKey(const Key('faq-menu-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar pregunta'), findsOneWidget);
    expect(repo.deletedId, isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.deletedId, 'f1');
    expect(repo.listCalls, 2);
    expect(find.text('Pregunta eliminada'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación no elimina', (tester) async {
    final repo = await _pumpScreen(tester, role: 'admin');

    await tester.tap(find.byKey(const Key('faq-menu-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.deletedId, isNull);
    expect(repo.listCalls, 1);
  });

  testWidgets('crear desde el FAB recarga la lista y avisa', (tester) async {
    final repo = await _pumpScreen(tester, role: 'admin');
    expect(repo.listCalls, 1);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nueva pregunta'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      '¿Nueva pregunta?',
    );
    await tester.enterText(
      find.byKey(const Key('faq-answer-field')),
      'Nueva respuesta',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.createdArgs, {
      'question': '¿Nueva pregunta?',
      'answer': 'Nueva respuesta',
    });
    expect(repo.listCalls, 2);
    expect(find.text('Pregunta creada'), findsOneWidget);
  });

  testWidgets('editar desde el menú recarga la lista y avisa', (tester) async {
    final repo = await _pumpScreen(tester, role: 'admin');
    expect(repo.listCalls, 1);

    await tester.tap(find.byKey(const Key('faq-menu-f1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      '¿Cómo pago ahora?',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.updatedId, 'f1');
    expect(repo.updatedArgs, {
      'question': '¿Cómo pago ahora?',
      'answer': 'Desde la sección Cuotas',
    });
    expect(repo.listCalls, 2);
    expect(find.text('Pregunta actualizada'), findsOneWidget);
  });

  testWidgets('el FAB no se superpone con la barra de paginación',
      (tester) async {
    await _pumpScreen(tester, role: 'admin', total: 24);

    final fab = tester.getRect(find.byType(FloatingActionButton));
    final pagination = tester.getRect(find.byType(PaginationBar));

    expect(find.byType(PaginationBar), findsOneWidget);
    expect(fab.overlaps(pagination), isFalse);
  });
}
