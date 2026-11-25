import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/status_badge.dart';
import 'package:efe_mobile/features/requests/data/request_repository.dart';
import 'package:efe_mobile/features/requests/domain/request_model.dart';
import 'package:efe_mobile/features/requests/providers/request_provider.dart';
import 'package:efe_mobile/features/requests/screens/request_list_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({this.pages = const [], this.error});

  final List<PageResult<RequestModel>> pages;
  final Object? error;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<PageResult<RequestModel>> getRequests({
    String? search,
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add({
      'search': search,
      'status': status,
      'type': type,
      'page': page,
      'perPage': perPage,
    });
    if (error != null) throw error!;
    return pages.removeAt(0);
  }

  @override
  Future<RequestModel> getRequest(RequestKind kind, String id) =>
      throw UnimplementedError();

  @override
  Future<bool> approve(RequestModel request, {String? classroomId}) =>
      throw UnimplementedError();

  @override
  Future<bool> reject(RequestModel request) => throw UnimplementedError();
}

PageResult<RequestModel> _page(
  List<RequestModel> data, {
  int page = 1,
  int total = 2,
}) =>
    PageResult(
      data: data,
      page: page,
      perPage: 20,
      total: total,
    );

Future<void> _pumpList(
  WidgetTester tester,
  RequestRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      requestRepositoryProvider.overrideWithValue(repository),
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
        home: RequestListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows student and parent requests', (tester) async {
    final repository = _FakeRequestRepository(
      pages: [
        _page(const [
          RequestModel(
            id: 's1',
            kind: RequestKind.student,
            fullname: 'Ana',
            email: 'ana@test.com',
            status: 'pending',
          ),
          RequestModel(
            id: 'p1',
            kind: RequestKind.parent,
            fullname: 'María',
            email: 'maria@test.com',
            status: 'pending',
            childrenCount: 2,
          ),
        ]),
      ],
    );

    await _pumpList(tester, repository);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('Alumno · ana@test.com'), findsOneWidget);
    expect(find.text('Padre/Tutor · maria@test.com'), findsOneWidget);
    expect(find.byType(StatusBadge), findsNWidgets(2));
    expect(find.text('2 hijos'), findsOneWidget);
  });

  testWidgets(
      'filtering by parent requests asks the repository for type parent',
      (tester) async {
    final repository = _FakeRequestRepository(
      pages: [
        _page(const [
          RequestModel(id: 's1', fullname: 'Ana'),
        ]),
        _page(const [
          RequestModel(
            id: 'p1',
            kind: RequestKind.parent,
            fullname: 'María',
          ),
        ]),
      ],
    );

    await _pumpList(tester, repository);
    await tester.tap(find.text('Padres/Tutores'));
    await tester.pumpAndSettle();

    expect(repository.calls.last['type'], 'parent');
    expect(repository.calls.last['page'], 1);
    expect(find.text('María'), findsOneWidget);
  });

  testWidgets('empty state when there are no requests', (tester) async {
    final repository = _FakeRequestRepository(
      pages: [
        _page(const []),
      ],
    );

    await _pumpList(tester, repository);

    expect(find.text('No hay solicitudes'), findsOneWidget);
    expect(find.text('No hay solicitudes para estos filtros'), findsOneWidget);
  });

  testWidgets('error state offers retry', (tester) async {
    final repository = _FakeRequestRepository(
      error: Exception('boom'),
    );

    await _pumpList(tester, repository);

    expect(find.text('No se pudieron cargar las solicitudes'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
