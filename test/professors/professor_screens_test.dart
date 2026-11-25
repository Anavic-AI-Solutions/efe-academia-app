import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/widgets/pill_button.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/management/screens/management_hub_screen.dart';
import 'package:efe_mobile/features/professors/data/professor_repository.dart';
import 'package:efe_mobile/features/professors/providers/professor_provider.dart';
import 'package:efe_mobile/features/professors/screens/professor_detail_screen.dart';
import 'package:efe_mobile/features/professors/screens/professor_form_screen.dart';
import 'package:efe_mobile/features/professors/screens/professor_list_screen.dart';
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

class _FakeProfessorRepository implements ProfessorRepository {
  _FakeProfessorRepository({
    this.professor = _ana,
    this.total = 1,
  });

  ProfessorModel professor;
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

  ProfessorModel _professorAt(int index) {
    return ProfessorModel(
      id: 'p${index + 1}',
      fullname: 'Profesor ${index + 1}',
      email: 'profesor${index + 1}@example.com',
      specialty: 'Matemática',
      classroomCount: 2,
    );
  }

  @override
  Future<CursorPagination<ProfessorModel>> getProfessors({
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
        ? [professor]
        : [for (var i = start; i < end; i++) _professorAt(i)];
    final nextCursor = end < total ? '$end' : null;
    return CursorPagination(
      data: data,
      nextCursor: nextCursor,
      hasMore: nextCursor != null,
      total: total,
    );
  }

  @override
  Future<ProfessorModel> getProfessor(String id) async {
    final error = detailError;
    if (error != null) throw error;
    return professor;
  }

  @override
  Future<ProfessorModel> createProfessor({
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) async {
    createCalls.add({
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_number': identityNumber,
      'bio': bio,
      'specialty': specialty,
    });
    final error = createError;
    if (error != null) throw error;
    return ProfessorModel(
      id: 'new',
      fullname: fullname,
      email: email,
      phone: phone ?? '',
      address: address ?? '',
      identityNumber: identityNumber,
      bio: bio ?? '',
      specialty: specialty ?? '',
    );
  }

  @override
  Future<ProfessorModel> updateProfessor(
    String id, {
    required String fullname,
    required String email,
    String? phone,
    String? address,
    required String identityNumber,
    String? bio,
    String? specialty,
  }) async {
    updateCalls.add({
      'id': id,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_number': identityNumber,
      'bio': bio,
      'specialty': specialty,
    });
    final error = updateError;
    if (error != null) throw error;
    return ProfessorModel(
      id: id,
      fullname: fullname,
      email: email,
      phone: phone ?? '',
      address: address ?? '',
      identityNumber: identityNumber,
      bio: bio ?? '',
      specialty: specialty ?? '',
    );
  }

  @override
  Future<void> deleteProfessor(String id) async {
    deleted.add(id);
    if (failDetailAfterDelete) {
      detailError = ApiException(message: 'gone', statusCode: 404);
    }
  }
}

const _ana = ProfessorModel(
  id: 'p1',
  fullname: 'Ana Pérez',
  email: 'ana@example.com',
  phone: '3411234567',
  address: 'Calle 1',
  identityNumber: '30111222',
  bio: 'Profesora de matemática',
  specialty: 'Matemática',
  classroomCount: 2,
);

Future<_FakeProfessorRepository> _pumpList(
  WidgetTester tester, {
  String role = 'admin',
  _FakeProfessorRepository? repository,
}) async {
  final repo = repository ?? _FakeProfessorRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        professorRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(home: const ProfessorListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<_FakeProfessorRepository> _pumpDetail(
  WidgetTester tester, {
  String role = 'admin',
  ProfessorModel professor = _ana,
}) async {
  final repo = _FakeProfessorRepository(professor: professor);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
        professorRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(
        home: ProfessorDetailScreen(professorId: professor.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

class _FormHarness extends StatelessWidget {
  const _FormHarness({
    required this.professor,
    required this.professorId,
    required this.onResult,
  });

  final ProfessorModel? professor;
  final String? professorId;
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
                builder: (_) => ProfessorFormScreen(
                  professor: professor,
                  professorId: professorId,
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

Future<_FakeProfessorRepository> _openForm(
  WidgetTester tester, {
  ProfessorModel? professor,
  String? professorId,
  _FakeProfessorRepository? repository,
  void Function(bool?)? onResult,
}) async {
  final repo =
      repository ?? _FakeProfessorRepository(professor: professor ?? _ana);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository('admin')),
        professorRepositoryProvider.overrideWithValue(repo),
      ],
      child: localizedApp(
        home: _FormHarness(
          professor: professor,
          professorId: professorId,
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
    find.byKey(const Key('professor-form-fullname')),
    'Ana Gómez',
  );
  await tester.enterText(
    find.byKey(const Key('professor-form-email')),
    'ana@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('professor-form-identity')),
    '30111222',
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

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('entity-form-save')));
  await tester.pumpAndSettle();
}

class _DetailHarness extends StatelessWidget {
  const _DetailHarness({required this.professorId});

  final String professorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('detail-harness'),
      body: Center(
        child: ElevatedButton(
          key: const Key('open-detail'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ProfessorDetailScreen(professorId: professorId),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  group('professor list', () {
    testWidgets('admin sees the create FAB and the professors', (tester) async {
      await _pumpList(tester, role: 'admin');

      expect(find.byKey(const Key('professor-list-fab')), findsOneWidget);
      expect(find.byTooltip('Crear'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text('Matemática'), findsOneWidget);
      expect(find.text('2 aulas'), findsOneWidget);
    });

    testWidgets('branch sees the list without the create FAB', (tester) async {
      await _pumpList(tester, role: 'branch');

      expect(find.byKey(const Key('professor-list-fab')), findsNothing);
      expect(find.byTooltip('Crear'), findsNothing);
      expect(find.text('Ana Pérez'), findsOneWidget);
    });

    testWidgets('debounces the search before reloading the list',
        (tester) async {
      final repo = await _pumpList(tester);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump(const Duration(milliseconds: 150));

      expect(repo.listCalls, hasLength(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(2));
      expect(repo.listCalls.last['search'], 'Ana');
      expect(repo.listCalls.last['cursor'], isNull);
    });

    testWidgets('loads the next cursor page when scrolled to the bottom',
        (tester) async {
      final repo = _FakeProfessorRepository(total: 30);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_FakeAuthRepository('admin')),
          professorRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localizedApp(home: const ProfessorListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(1));
      expect(container.read(professorListProvider).data, hasLength(20));

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        10000,
      );
      await tester.pumpAndSettle();

      expect(repo.listCalls, hasLength(2));
      expect(repo.listCalls.last['cursor'], '20');

      final state = container.read(professorListProvider);
      expect(state.data, hasLength(30));
      expect(state.data.last.fullname, 'Profesor 30');
      expect(state.hasMore, isFalse);
    });

    testWidgets('renders the empty state', (tester) async {
      await _pumpList(
        tester,
        repository: _FakeProfessorRepository(total: 0),
      );

      expect(find.text('No hay profesores'), findsOneWidget);
      expect(find.text('Probá con otra búsqueda'), findsOneWidget);
    });

    testWidgets('renders the load error with a retry', (tester) async {
      await _pumpList(
        tester,
        repository: _FakeProfessorRepository()
          ..listError = ApiException(message: 'boom'),
      );

      expect(
        find.text('No se pudieron cargar los profesores'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('professor detail', () {
    testWidgets('renders the header, contact and info rows', (tester) async {
      await _pumpDetail(tester);

      expect(find.text('Ana Pérez'), findsWidgets);
      expect(find.text('ana@example.com'), findsWidgets);
      expect(find.text('3411234567'), findsOneWidget);
      expect(find.text('Calle 1'), findsOneWidget);
      expect(find.text('30111222'), findsOneWidget);
      expect(find.text('Profesora de matemática'), findsOneWidget);
      expect(find.text('Matemática'), findsWidgets);
      expect(find.text('2 aulas'), findsOneWidget);
    });

    testWidgets('admin sees edit and delete actions', (tester) async {
      await _pumpDetail(tester, role: 'admin');

      expect(
        find.byKey(const Key('professor-detail-actions')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('professor-detail-actions')));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('branch sees no actions', (tester) async {
      await _pumpDetail(tester, role: 'branch');

      expect(
        find.byKey(const Key('professor-detail-actions')),
        findsNothing,
      );
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('deleting confirms, removes and pops the detail',
        (tester) async {
      final repo = _FakeProfessorRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository('admin')),
            professorRepositoryProvider.overrideWithValue(repo),
          ],
          child: localizedApp(
            home: const _DetailHarness(professorId: 'p1'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-detail')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('professor-detail-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar profesor'), findsOneWidget);

      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(repo.deleted, ['p1']);
      expect(find.byType(ProfessorDetailScreen), findsNothing);
      expect(find.byKey(const Key('detail-harness')), findsOneWidget);
    });

    testWidgets('deleting pops even when the detail refetch would 404',
        (tester) async {
      final repo = _FakeProfessorRepository()
        ..failDetailAfterDelete = true
        ..listDelay = const Duration(milliseconds: 500);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider
                .overrideWithValue(_FakeAuthRepository('admin')),
            professorRepositoryProvider.overrideWithValue(repo),
          ],
          child: localizedApp(
            home: const _DetailHarness(professorId: 'p1'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-detail')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('professor-detail-actions')));
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

      expect(repo.deleted, ['p1']);
      expect(find.byType(ProfessorDetailScreen), findsNothing);
      expect(find.byKey(const Key('detail-harness')), findsOneWidget);
      expect(find.text('No se pudieron cargar los profesores'), findsNothing);
    });
  });

  group('professor form', () {
    testWidgets('creates a professor and pops with true', (tester) async {
      bool? result;
      final repo = await _openForm(
        tester,
        onResult: (value) => result = value,
      );

      expect(find.text('Nuevo profesor'), findsOneWidget);

      await _fillRequiredFields(tester);
      await _enterField(
        tester,
        'professor-form-phone',
        '3411234567',
      );
      await _enterField(
        tester,
        'professor-form-address',
        'Calle 1',
      );
      await _enterField(
        tester,
        'professor-form-bio',
        'Bio',
      );
      await _enterField(
        tester,
        'professor-form-specialty',
        'Matemática',
      );
      await _save(tester);

      expect(repo.createCalls, hasLength(1));
      expect(repo.createCalls.single, {
        'fullname': 'Ana Gómez',
        'email': 'ana@example.com',
        'phone': '3411234567',
        'address': 'Calle 1',
        'identity_number': '30111222',
        'bio': 'Bio',
        'specialty': 'Matemática',
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
      expect(find.byType(ProfessorFormScreen), findsOneWidget);
    });

    testWidgets('rejects an invalid email', (tester) async {
      final repo = await _openForm(tester);
      await _fillRequiredFields(tester);
      await tester.enterText(
        find.byKey(const Key('professor-form-email')),
        'not-an-email',
      );

      await _save(tester);

      expect(repo.createCalls, isEmpty);
      expect(find.text('Correo electrónico inválido'), findsOneWidget);
    });

    testWidgets('edits an existing professor and clears optional fields',
        (tester) async {
      bool? result;
      final repo = await _openForm(
        tester,
        professor: _ana,
        onResult: (value) => result = value,
      );

      expect(find.text('Editar profesor'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('3411234567'), findsOneWidget);

      await _enterField(
        tester,
        'professor-form-phone',
        '',
      );
      await _enterField(
        tester,
        'professor-form-specialty',
        'Física',
      );
      await _save(tester);

      expect(repo.createCalls, isEmpty);
      expect(repo.updateCalls, hasLength(1));
      expect(repo.updateCalls.single['id'], 'p1');
      expect(repo.updateCalls.single['phone'], '');
      expect(repo.updateCalls.single['specialty'], 'Física');
      expect(result, isTrue);
    });

    testWidgets('loads the professor when only an id is provided',
        (tester) async {
      final repo = _FakeProfessorRepository();
      await _openForm(
        tester,
        professorId: 'p1',
        repository: repo,
      );

      expect(find.text('Editar profesor'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);

      await _save(tester);

      expect(repo.updateCalls.single['id'], 'p1');
    });

    testWidgets('disables save when the professor detail fails to load',
        (tester) async {
      final repo = _FakeProfessorRepository()
        ..detailError = ApiException(message: 'gone', statusCode: 404);
      await _openForm(
        tester,
        professorId: 'p1',
        repository: repo,
      );

      expect(find.text('No se pudieron cargar los profesores'), findsOneWidget);

      final save = tester.widget<PillButton>(
        find.byKey(const ValueKey('entity-form-save')),
      );
      expect(save.onPressed, isNull);
      expect(repo.updateCalls, isEmpty);
    });

    testWidgets('maps 422 field errors to the matching fields', (tester) async {
      bool? result;
      final repo = _FakeProfessorRepository()
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
      expect(find.byType(ProfessorFormScreen), findsOneWidget);
      expect(result, isNull);
    });
  });

  group('management hub', () {
    testWidgets('lists Profesores under Personas and navigates to it',
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
            path: '/professors',
            builder: (context, state) => const Scaffold(
              key: Key('professors-destination'),
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

      expect(find.text('Profesores'), findsOneWidget);

      await tester.tap(find.text('Profesores'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('professors-destination')), findsOneWidget);
    });
  });
}
