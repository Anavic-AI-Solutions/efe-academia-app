import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/management/screens/management_hub_screen.dart';
import 'package:efe_mobile/features/parents/data/parent_repository.dart';
import 'package:efe_mobile/features/parents/domain/parent_model.dart';
import 'package:efe_mobile/features/parents/providers/parent_provider.dart';
import 'package:efe_mobile/features/parents/screens/parent_detail_screen.dart';
import 'package:efe_mobile/features/parents/screens/parent_form_screen.dart';
import 'package:efe_mobile/features/parents/screens/parent_list_screen.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/localized_app.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.role);

  final String role;

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: role,
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

class _FakeParentRepository implements ParentRepository {
  _FakeParentRepository({
    this.parent = _lucia,
    this.total = 1,
  });

  ParentModel parent;
  int total;
  int get pageSize => 20;
  Object? listError;
  Object? detailError;
  bool failDetailAfterDelete = false;
  Duration listDelay = Duration.zero;
  ApiException? createError;
  ApiException? updateError;

  final List<Map<String, Object?>> listCalls = [];
  final List<Map<String, Object?>> createCalls = [];
  final List<Map<String, Object?>> updateCalls = [];
  final List<String> deleted = [];

  ParentModel _parentAt(int index) {
    return ParentModel(
      id: 'pa${index + 1}',
      fullname: 'Padre ${index + 1}',
      email: 'padre${index + 1}@example.com',
      status: 'approved',
      studentCount: 1,
    );
  }

  @override
  Future<CursorPagination<ParentModel>> getParents({
    String? search,
    String? cursor,
  }) async {
    listCalls.add({'search': search, 'cursor': cursor});
    if (listDelay > Duration.zero) {
      await Future.delayed(listDelay);
    }
    final error = listError;
    if (error != null) throw error;
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, total);
    final data = total == 1 && cursor == null
        ? [parent]
        : [for (var i = start; i < end; i++) _parentAt(i)];
    final nextCursor = end < total ? '$end' : null;
    return CursorPagination(
      data: data,
      nextCursor: nextCursor,
      hasMore: nextCursor != null,
      total: total,
    );
  }

  @override
  Future<ParentModel> getParent(String id) async {
    final error = detailError;
    if (error != null) throw error;
    return parent;
  }

  @override
  Future<ParentModel> createParent({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String status = 'pending',
  }) async {
    createCalls.add({
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_number': identityNumber,
      'status': status,
    });
    final error = createError;
    if (error != null) throw error;
    return ParentModel(
      id: 'new',
      fullname: fullname,
      email: email,
      phone: phone ?? '',
      address: address ?? '',
      identityNumber: identityNumber,
      status: status,
    );
  }

  @override
  Future<ParentModel> updateParent(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    required String status,
  }) async {
    updateCalls.add({
      'id': id,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_number': identityNumber,
      'status': status,
    });
    final error = updateError;
    if (error != null) throw error;
    return ParentModel(
      id: id,
      fullname: fullname,
      email: email,
      phone: phone ?? '',
      address: address ?? '',
      identityNumber: identityNumber,
      status: status,
    );
  }

  @override
  Future<void> deleteParent(String id) async {
    deleted.add(id);
    if (failDetailAfterDelete) {
      detailError = ApiException(message: 'gone', statusCode: 404);
    }
  }

  @override
  Future<List<StudentModel>> getParentStudents(String parentId) async => [];

  @override
  Future<void> linkStudent(String parentId, String studentId) async {}

  @override
  Future<void> unlinkStudent(String parentId, String studentId) async {}
}

const _lucia = ParentModel(
  id: 'pa1',
  fullname: 'Lucía Fernández',
  email: 'lucia@example.com',
  phone: '3415551234',
  address: 'Av. Siempre Viva 742',
  identityNumber: '27888999',
  status: 'approved',
  studentCount: 2,
);

Future<_FakeParentRepository> _pumpList(
  WidgetTester tester, {
  String role = 'admin',
  _FakeParentRepository? repository,
}) async {
  final repo = repository ?? _FakeParentRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        parentRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(home: const ParentListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<_FakeParentRepository> _pumpDetail(
  WidgetTester tester, {
  String role = 'admin',
  ParentModel parent = _lucia,
}) async {
  final repo = _FakeParentRepository(parent: parent);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        parentRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(
        home: ParentDetailScreen(parentId: parent.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

class _FormHarness extends StatelessWidget {
  const _FormHarness({
    required this.parent,
    required this.parentId,
    required this.onResult,
  });

  final ParentModel? parent;
  final String? parentId;
  final ValueChanged<bool?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open-form'),
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ParentFormScreen(
                  parent: parent,
                  parentId: parentId,
                ),
              ),
            );
            onResult(result);
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<_FakeParentRepository> _openForm(
  WidgetTester tester, {
  ParentModel? parent,
  String? parentId,
  _FakeParentRepository? repository,
  void Function(bool?)? onResult,
}) async {
  final repo = repository ?? _FakeParentRepository(parent: parent ?? _lucia);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository('admin')),
        parentRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(
        home: _FormHarness(
          parent: parent,
          parentId: parentId,
          onResult: onResult ?? (_) {},
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-form')));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('parent-form-fullname')),
    'Lucía Gómez',
  );
  await tester.enterText(
    find.byKey(const Key('parent-form-email')),
    'lucia@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('parent-form-identity')),
    '27888999',
  );
}

Future<void> _enterField(
  WidgetTester tester,
  String key,
  String value,
) async {
  final field = find.byKey(Key(key));
  if (field.evaluate().isEmpty) {
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('entity-form-fields')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(field, 120, scrollable: scrollable);
  }
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _selectStatus(WidgetTester tester, String label) async {
  final dropdown = find.byKey(const Key('parent-form-status'));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('entity-form-save')));
  await tester.pumpAndSettle();
}

class _DetailHarness extends StatelessWidget {
  const _DetailHarness({required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('detail-harness'),
      body: Center(
        child: ElevatedButton(
          key: const Key('open-detail'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ParentDetailScreen(parentId: parentId),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  group('parent list', () {
    testWidgets('admin sees the create FAB and the parents', (tester) async {
      await _pumpList(tester, role: 'admin');

      expect(find.byKey(const Key('parent-list-fab')), findsOneWidget);
      expect(find.byTooltip('Crear'), findsOneWidget);
      expect(find.text('Lucía Fernández'), findsOneWidget);
      expect(find.text('lucia@example.com'), findsOneWidget);
      expect(find.text('Aprobado'), findsOneWidget);
      expect(find.text('2 alumnos'), findsOneWidget);
    });

    testWidgets('branch sees the create FAB too', (tester) async {
      await _pumpList(tester, role: 'branch');

      expect(find.byKey(const Key('parent-list-fab')), findsOneWidget);
      expect(find.text('Lucía Fernández'), findsOneWidget);
    });

    for (final role in ['professor', 'student']) {
      testWidgets('$role sees the list without the FAB', (tester) async {
        await _pumpList(tester, role: role);

        expect(
          find.byKey(const Key('parent-list-fab')),
          findsNothing,
          reason: 'role $role must not create parents',
        );
        expect(find.byTooltip('Crear'), findsNothing);
        expect(find.text('Lucía Fernández'), findsOneWidget);
      });
    }

    testWidgets('debounces the search before reloading the list',
        (tester) async {
      final repo = await _pumpList(tester);

      await tester.enterText(find.byType(TextField), 'Lucía');
      await tester.pump(const Duration(milliseconds: 150));

      expect(repo.listCalls, hasLength(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(2));
      expect(repo.listCalls.last['search'], 'Lucía');
      expect(repo.listCalls.last['cursor'], isNull);
    });

    testWidgets('loads the next cursor page when scrolled to the bottom',
        (tester) async {
      final repo = _FakeParentRepository(total: 30);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_FakeAuthRepository('admin')),
          parentRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localizedApp(home: const ParentListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(1));
      expect(container.read(parentListProvider).data, hasLength(20));

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        10000,
      );
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(2));
      expect(repo.listCalls.last['cursor'], '20');

      final state = container.read(parentListProvider);
      expect(state.data, hasLength(30));
      expect(state.data.last.fullname, 'Padre 30');
      expect(state.hasMore, isFalse);
    });

    testWidgets('renders the empty state', (tester) async {
      await _pumpList(
        tester,
        repository: _FakeParentRepository(total: 0),
      );

      expect(find.text('No hay padres'), findsOneWidget);
      expect(find.text('Probá con otra búsqueda'), findsOneWidget);
    });

    testWidgets('renders the load error with a retry', (tester) async {
      await _pumpList(
        tester,
        repository: _FakeParentRepository()
          ..listError = ApiException(message: 'boom'),
      );

      expect(find.text('No se pudieron cargar los padres'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('parent detail', () {
    testWidgets('renders the header, contact data and status', (tester) async {
      await _pumpDetail(tester);

      expect(find.text('Lucía Fernández'), findsWidgets);
      expect(find.text('lucia@example.com'), findsWidgets);
      expect(find.text('3415551234'), findsOneWidget);
      expect(find.text('Av. Siempre Viva 742'), findsOneWidget);
      expect(find.text('27888999'), findsOneWidget);
      expect(find.text('Aprobado'), findsWidgets);
      expect(find.text('2 alumnos'), findsOneWidget);
    });

    for (final role in ['admin', 'branch']) {
      testWidgets('$role sees edit and delete actions', (tester) async {
        await _pumpDetail(tester, role: role);

        expect(
          find.byKey(const Key('parent-detail-actions')),
          findsOneWidget,
          reason: 'role $role must manage parents',
        );

        await tester.tap(find.byKey(const Key('parent-detail-actions')));
        await tester.pumpAndSettle();

        expect(find.text('Editar'), findsOneWidget);
        expect(find.text('Eliminar'), findsOneWidget);
      });
    }

    for (final role in ['professor', 'student']) {
      testWidgets('$role sees no actions', (tester) async {
        await _pumpDetail(tester, role: role);

        expect(
          find.byKey(const Key('parent-detail-actions')),
          findsNothing,
          reason: 'role $role must not manage parents',
        );
        expect(find.text('Editar'), findsNothing);
        expect(find.text('Eliminar'), findsNothing);
      });
    }

    testWidgets('deleting confirms, removes and pops the detail',
        (tester) async {
      final repo = _FakeParentRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository('admin')),
            parentRepositoryProvider.overrideWithValue(repo),
          ],
          child: localizedApp(
            home: const _DetailHarness(parentId: 'pa1'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-detail')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('parent-detail-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar padre'), findsOneWidget);

      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, ['pa1']);
      expect(find.byType(ParentDetailScreen), findsNothing);
      expect(find.byKey(const Key('detail-harness')), findsOneWidget);
    });

    testWidgets('deleting pops even when the detail refetch would 404',
        (tester) async {
      final repo = _FakeParentRepository()
        ..failDetailAfterDelete = true
        ..listDelay = const Duration(milliseconds: 500);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository('admin')),
            parentRepositoryProvider.overrideWithValue(repo),
          ],
          child: localizedApp(
            home: const _DetailHarness(parentId: 'pa1'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-detail')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('parent-detail-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pump();
      // A frame lands while the list refresh is still in flight; the deleted
      // detail must not re-fetch and replace itself with an error view.
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['pa1']);
      expect(find.byType(ParentDetailScreen), findsNothing);
      expect(find.byKey(const Key('detail-harness')), findsOneWidget);
      expect(find.text('No se pudieron cargar los padres'), findsNothing);
    });
  });

  group('parent form', () {
    testWidgets('creates a parent with the chosen status', (tester) async {
      bool? result;
      final repo = await _openForm(
        tester,
        onResult: (value) => result = value,
      );

      expect(find.text('Nuevo padre'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);

      await _fillRequiredFields(tester);
      await _enterField(tester, 'parent-form-phone', '3415551234');
      await _enterField(tester, 'parent-form-address', 'Av. Siempre Viva 742');
      await _selectStatus(tester, 'Aprobado');
      await _save(tester);

      expect(repo.createCalls, hasLength(1));
      expect(repo.createCalls.single, {
        'fullname': 'Lucía Gómez',
        'email': 'lucia@example.com',
        'phone': '3415551234',
        'address': 'Av. Siempre Viva 742',
        'identity_number': '27888999',
        'status': 'approved',
      });
      expect(repo.updateCalls, isEmpty);
      expect(result, isTrue);
    });

    testWidgets('requires fullname, email and identity before creating',
        (tester) async {
      final repo = await _openForm(tester);

      await _save(tester);

      expect(repo.createCalls, isEmpty);
      expect(find.text('Nombre completo es obligatorio'), findsOneWidget);
      expect(find.text('Correo electrónico es obligatorio'), findsOneWidget);
      expect(find.text('Documento es obligatorio'), findsOneWidget);
      expect(find.byType(ParentFormScreen), findsOneWidget);
    });

    testWidgets('rejects an invalid email', (tester) async {
      final repo = await _openForm(tester);
      await _fillRequiredFields(tester);
      await tester.enterText(
        find.byKey(const Key('parent-form-email')),
        'not-an-email',
      );

      await _save(tester);

      expect(repo.createCalls, isEmpty);
      expect(find.text('Correo electrónico inválido'), findsOneWidget);
    });

    testWidgets('edits a parent, updates the status and clears optionals',
        (tester) async {
      bool? result;
      final repo = await _openForm(
        tester,
        parent: _lucia,
        onResult: (value) => result = value,
      );

      expect(find.text('Editar padre'), findsOneWidget);
      expect(find.text('Lucía Fernández'), findsOneWidget);
      expect(find.text('Aprobado'), findsOneWidget);

      await _enterField(tester, 'parent-form-phone', '');
      await _selectStatus(tester, 'Rechazado');
      await _save(tester);

      expect(repo.createCalls, isEmpty);
      expect(repo.updateCalls, hasLength(1));
      expect(repo.updateCalls.single['id'], 'pa1');
      expect(repo.updateCalls.single['phone'], '');
      expect(repo.updateCalls.single['status'], 'rejected');
      expect(result, isTrue);
    });

    testWidgets('loads the parent when only an id is provided', (tester) async {
      final repo = _FakeParentRepository();
      await _openForm(
        tester,
        parentId: 'pa1',
        repository: repo,
      );

      expect(find.text('Editar padre'), findsOneWidget);
      expect(find.text('Lucía Fernández'), findsOneWidget);

      await _save(tester);

      expect(repo.updateCalls.single['id'], 'pa1');
      expect(repo.updateCalls.single['status'], 'approved');
    });

    testWidgets('disables save when the parent detail fails to load',
        (tester) async {
      final repo = _FakeParentRepository()
        ..detailError = ApiException(message: 'gone', statusCode: 404);
      await _openForm(
        tester,
        parentId: 'pa1',
        repository: repo,
      );

      expect(find.text('No se pudieron cargar los padres'), findsOneWidget);

      final save = tester.widget<PillButton>(
        find.byKey(const ValueKey('entity-form-save')),
      );
      expect(save.onPressed, isNull);
      expect(repo.updateCalls, isEmpty);
    });

    testWidgets('maps 422 field errors to the matching fields', (tester) async {
      bool? result;
      final repo = _FakeParentRepository()
        ..createError = ValidationException(
          fieldErrors: {
            'email': 'El correo ya está registrado',
            'identity_number': 'El documento ya existe',
          },
        );
      await _openForm(
        tester,
        repository: repo,
        onResult: (value) => result = value,
      );

      await _fillRequiredFields(tester);
      await _save(tester);

      expect(repo.createCalls, hasLength(1));
      expect(find.text('El correo ya está registrado'), findsOneWidget);
      expect(find.text('El documento ya existe'), findsOneWidget);
      expect(find.byType(ParentFormScreen), findsOneWidget);
      expect(result, isNull);
    });
  });

  group('management hub', () {
    testWidgets('lists Padres under Personas and navigates to it',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/management',
        routes: [
          GoRoute(
            path: '/management',
            builder: (context, state) => const ManagementHubScreen(),
          ),
          GoRoute(
            path: '/parents',
            builder: (context, state) => const Scaffold(
              key: Key('parents-destination'),
              body: SizedBox.shrink(),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository('admin')),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: testLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Padres'), findsOneWidget);

      await tester.tap(find.text('Padres'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parents-destination')), findsOneWidget);
    });
  });
}
