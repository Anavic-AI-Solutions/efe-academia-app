import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/requests/data/request_repository.dart';
import 'package:efe_mobile/features/requests/domain/request_model.dart';
import 'package:efe_mobile/features/requests/providers/request_provider.dart';
import 'package:efe_mobile/features/requests/screens/request_detail_screen.dart';
import 'package:efe_mobile/features/requests/screens/request_list_screen.dart';
import 'package:efe_mobile/features/requests/screens/widgets/classroom_picker_sheet.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({
    required this.details,
    this.pages = const [],
    this.approveResult = true,
  });

  final List<RequestModel> details;
  final List<PageResult<RequestModel>> pages;
  final bool approveResult;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<RequestModel>> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add({'method': 'getRequests', 'page': page});
    return pages.removeAt(0);
  }

  @override
  Future<RequestModel> getRequest(RequestKind kind, String id) async {
    calls.add({'method': 'getRequest', 'kind': kind, 'id': id});
    if (details.length > 1) return details.removeAt(0);
    return details.first;
  }

  @override
  Future<bool> approve(RequestModel request, {String? classroomId}) async {
    calls.add({
      'method': 'approve',
      'id': request.id,
      'classroomId': classroomId,
    });
    return approveResult;
  }

  @override
  Future<bool> reject(RequestModel request) async {
    calls.add({'method': 'reject', 'id': request.id});
    return true;
  }
}

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<ClassroomModel>> getClassrooms({
    String? search,
    int page = 1,
    int limit = 20,
    String? branch,
    String? level,
    String? year,
    String? status,
    String? studentId,
  }) async {
    calls.add({'search': search, 'page': page, 'limit': limit});
    return PageResult(
      data: const [ClassroomModel(id: 'c1', name: 'Inglés 1')],
      page: page,
      perPage: limit,
      total: 1,
    );
  }

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomModel> getClassroom(String id) => throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() => throw UnimplementedError();

  @override
  Future<ClassroomModel> createClassroom({
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomModel> updateClassroom(
    String id, {
    required String name,
    String description = '',
    String status = 'active',
    String shift = '',
    String day = '',
    String hour = '',
    String room = '',
    String year = '',
    String branch = '',
    String level = '',
    String grade = '',
    String book = '',
    String commission = '',
    String courseDays = '',
    String period1Days = '',
    String period2Days = '',
    String period3Days = '',
    bool isArchived = false,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteClassroom(String id) => Future.error(UnimplementedError());
}

RequestModel _student({
  String id = 's1',
  String status = 'pending',
  String fullname = 'Ana',
}) =>
    RequestModel(
      id: id,
      kind: RequestKind.student,
      fullname: fullname,
      email: 'ana@test.com',
      identityNumber: '12345678',
      status: status,
    );

RequestModel _parent({
  String id = 'p1',
  String status = 'pending',
  List<RequestChild> children = const [],
}) =>
    RequestModel(
      id: id,
      kind: RequestKind.parent,
      fullname: 'María',
      email: 'maria@test.com',
      phone: '1234',
      address: 'Calle 1',
      status: status,
      childrenCount: children.length,
      children: children,
    );

Future<void> _pumpDetail(
  WidgetTester tester,
  _FakeRequestRepository repository, {
  RequestKind kind = RequestKind.student,
  String id = 's1',
  _FakeClassroomRepository? classrooms,
}) async {
  final container = ProviderContainer(
    overrides: [
      requestRepositoryProvider.overrideWithValue(repository),
      if (classrooms != null)
        classroomRepositoryProvider.overrideWithValue(classrooms),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RequestDetailScreen(kind: kind, id: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a request in the list opens its detail', (tester) async {
    final repository = _FakeRequestRepository(
      details: [_student()],
      pages: [
        PageResult(
          data: [_student()],
          page: 1,
          perPage: 20,
          total: 1,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/requests',
      routes: [
        GoRoute(
          path: '/requests',
          builder: (_, __) => const RequestListScreen(),
          routes: [
            GoRoute(
              path: ':kind/:id',
              builder: (_, state) => RequestDetailScreen(
                kind: RequestKind.fromValue(state.pathParameters['kind']),
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

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

    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestDetailScreen), findsOneWidget);
    expect(find.text('ana@test.com'), findsOneWidget);
  });

  testWidgets('pending student shows approve and reject', (tester) async {
    await _pumpDetail(
      tester,
      _FakeRequestRepository(details: [_student()]),
    );

    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  testWidgets('approved student hides actions', (tester) async {
    await _pumpDetail(
      tester,
      _FakeRequestRepository(details: [_student(status: 'approved')]),
    );

    expect(find.text('Aceptar'), findsNothing);
    expect(find.text('Rechazar'), findsNothing);
    expect(find.text('Aprobado'), findsOneWidget);
  });

  testWidgets('approve student opens the classroom picker and sends the course',
      (tester) async {
    final repository = _FakeRequestRepository(details: [_student()]);
    final classrooms = _FakeClassroomRepository();

    await _pumpDetail(
      tester,
      repository,
      classrooms: classrooms,
    );

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir curso'), findsOneWidget);
    await tester.tap(find.text('Inglés 1'));
    await tester.pumpAndSettle();

    expect(find.text('Aprobar solicitud'), findsOneWidget);
    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();

    final approveCall = repository.calls.lastWhere(
      (call) => call['method'] == 'approve',
    );
    expect(approveCall['classroomId'], 'c1');
    expect(find.text('Solicitud aprobada'), findsOneWidget);
  });

  testWidgets('approving a resolved request shows the no-change message',
      (tester) async {
    final repository = _FakeRequestRepository(
      details: [_student()],
      approveResult: false,
    );
    final classrooms = _FakeClassroomRepository();

    await _pumpDetail(tester, repository, classrooms: classrooms);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglés 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();

    expect(find.text('La solicitud ya estaba resuelta'), findsOneWidget);
  });

  testWidgets('reopening a resolved request hides actions', (tester) async {
    final repository = _FakeRequestRepository(
      details: [_student(), _student(status: 'approved')],
      pages: [
        PageResult(
          data: [_student()],
          page: 1,
          perPage: 20,
          total: 1,
        ),
        PageResult(
          data: [_student(status: 'approved')],
          page: 1,
          perPage: 20,
          total: 1,
        ),
      ],
    );
    final classrooms = _FakeClassroomRepository();
    final router = GoRouter(
      initialLocation: '/requests',
      routes: [
        GoRoute(
          path: '/requests',
          builder: (_, __) => const RequestListScreen(),
          routes: [
            GoRoute(
              path: ':kind/:id',
              builder: (_, state) => RequestDetailScreen(
                kind: RequestKind.fromValue(state.pathParameters['kind']),
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(repository),
        classroomRepositoryProvider.overrideWithValue(classrooms),
      ],
    );
    addTearDown(container.dispose);

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

    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglés 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestListScreen), findsOneWidget);

    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.text('Aceptar'), findsNothing);
    expect(find.text('Aprobado'), findsOneWidget);
  });

  testWidgets('reject asks for confirmation and calls the repository',
      (tester) async {
    final repository = _FakeRequestRepository(details: [_student()]);

    await _pumpDetail(tester, repository);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(find.text('Rechazar solicitud'), findsOneWidget);

    await tester.tap(find.text('Rechazar').last);
    await tester.pumpAndSettle();

    expect(
      repository.calls.where((call) => call['method'] == 'reject'),
      hasLength(1),
    );
    expect(find.text('Solicitud rechazada'), findsOneWidget);
  });

  testWidgets('parent detail lists children and opens the child with parentId',
      (tester) async {
    const child = RequestChild(
      id: 's1',
      fullname: 'Ana',
      identityNumber: '1',
      status: 'pending',
    );
    final repository = _FakeRequestRepository(
      details: [
        _parent(children: [child])
      ],
    );
    final router = GoRouter(
      initialLocation: '/requests/parent/p1',
      routes: [
        GoRoute(
          path: '/requests/:kind/:id',
          builder: (_, state) {
            if (state.pathParameters['kind'] == 'parent') {
              return RequestDetailScreen(
                kind: RequestKind.parent,
                id: state.pathParameters['id']!,
              );
            }
            return Scaffold(
              body: Text(
                'child ${state.pathParameters['id']} '
                'parent ${state.uri.queryParameters['parentId']}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

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

    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();

    expect(find.text('child s1 parent p1'), findsOneWidget);
  });

  testWidgets('parent detail refreshes after a child action', (tester) async {
    const child = RequestChild(
      id: 's1',
      fullname: 'Ana',
      identityNumber: '1',
      status: 'pending',
    );
    final repository = _FakeRequestRepository(
      details: [
        _parent(children: [child]),
        _parent(status: 'approved', children: [child]),
      ],
    );
    final router = GoRouter(
      initialLocation: '/requests/parent/p1',
      routes: [
        GoRoute(
          path: '/requests/:kind/:id',
          builder: (context, state) {
            if (state.pathParameters['kind'] == 'parent') {
              return RequestDetailScreen(
                kind: RequestKind.parent,
                id: state.pathParameters['id']!,
              );
            }
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => context.pop(true),
                child: const Text('done'),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        requestRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

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

    expect(find.text('Aceptar'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('done'));
    await tester.pumpAndSettle();

    expect(find.text('Aceptar'), findsNothing);
    expect(find.text('Aprobado'), findsOneWidget);
  });

  testWidgets(
      'classroom picker keeps the list below the header with keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestClassroomOptionsProvider.overrideWith(
            (ref, search) async => const [
              ClassroomModel(id: 'c1', name: 'Inglés 1'),
              ClassroomModel(id: 'c2', name: 'Inglés 2'),
            ],
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 700),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: const MaterialApp(
            locale: Locale('es', 'AR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ClassroomPickerSheet()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final search = tester.getRect(find.byType(TextField));
    final firstCourse = tester.getRect(find.text('Inglés 1'));
    final sheetSize = tester.getSize(find.byType(ClassroomPickerSheet));

    expect(firstCourse.top, greaterThanOrEqualTo(search.bottom));
    expect(sheetSize.height, lessThanOrEqualTo(660));
  });

  testWidgets('classroom picker searches on the server', (tester) async {
    final classrooms = _FakeClassroomRepository();
    final container = ProviderContainer(
      overrides: [
        classroomRepositoryProvider.overrideWithValue(classrooms),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ClassroomPickerSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'inglés');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(classrooms.calls.last['search'], 'inglés');
    expect(classrooms.calls.last['page'], 1);
    expect(classrooms.calls.last['limit'], 50);
  });
}
