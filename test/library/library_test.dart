import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/library/data/library_api.dart';
import 'package:efe_mobile/features/library/data/library_repository.dart';
import 'package:efe_mobile/features/library/providers/library_provider.dart';
import 'package:efe_mobile/features/library/screens/library_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/materials'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _materialJson(String id, {String url = ''}) => {
      'id': id,
      'attributes': {
        'name': 'Material $id',
        'description': 'Guía de estudio',
        'type': 'pdf',
        'public_url': url,
      },
    };

class _FakeLibraryApi implements LibraryApi {
  final List<Map<String, Object?>> calls = [];
  final List<Object?> payloads = [];

  @override
  Future<Response> getMaterials({
    String? search,
    String? nextCursor,
    int perPage = 20,
  }) async {
    calls.add({
      'search': search,
      'cursor': nextCursor,
      'perPage': perPage,
    });
    return _response(payloads.removeAt(0));
  }
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.pages);

  final List<CursorPagination<MaterialModel>> pages;
  int calls = 0;

  @override
  Future<CursorPagination<MaterialModel>> getMaterials({
    String? search,
    String? nextCursor,
  }) async {
    calls++;
    return pages.removeAt(0);
  }
}

class _DelayedLibraryRepository implements LibraryRepository {
  _DelayedLibraryRepository(this.future);

  final Future<CursorPagination<MaterialModel>> future;

  @override
  Future<CursorPagination<MaterialModel>> getMaterials({
    String? search,
    String? nextCursor,
  }) =>
      future;
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  LibraryRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(repository),
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
        home: const LibraryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('LibraryRepository', () {
    test('parses the cursor contract', () async {
      final api = _FakeLibraryApi()
        ..payloads.add({
          'data': [
            _materialJson('m1', url: 'https://example.com/a.pdf'),
            _materialJson('m2'),
          ],
          'meta': {'cursor': 'abc', 'has_more': true, 'total': 7},
        });
      final repository = LibraryRepository(api);

      final result = await repository.getMaterials(search: 'guía');

      expect(result.data, hasLength(2));
      expect(result.data.first.publicUrl, 'https://example.com/a.pdf');
      expect(result.nextCursor, 'abc');
      expect(result.hasMore, isTrue);
      expect(result.total, 7);
      expect(api.calls.single['search'], 'guía');
      expect(api.calls.single['cursor'], isNull);
    });

    test('missing meta falls back to an empty page', () async {
      final api = _FakeLibraryApi()..payloads.add({'data': []});
      final repository = LibraryRepository(api);

      final result = await repository.getMaterials();

      expect(result.data, isEmpty);
      expect(result.nextCursor, isNull);
      expect(result.hasMore, isFalse);
      expect(result.total, 0);
    });
  });

  group('LibraryListNotifier', () {
    test('load uses the first page and loadMore appends by cursor', () async {
      final repository = _FakeLibraryRepository([
        CursorPagination(
          data: const [MaterialModel(id: 'm1', name: 'Uno')],
          nextCursor: 'next',
          hasMore: true,
          total: 3,
        ),
        CursorPagination(
          data: const [
            MaterialModel(id: 'm2', name: 'Dos'),
            MaterialModel(id: 'm3', name: 'Tres'),
          ],
          hasMore: false,
          total: 3,
        ),
      ]);
      final notifier = LibraryListNotifier(repository);

      await notifier.load();
      expect(notifier.state.data.map((m) => m.id), ['m1']);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();
      expect(notifier.state.data.map((m) => m.id), ['m1', 'm2', 'm3']);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(repository.calls, 2);
    });

    test('loadMore does nothing without a cursor', () async {
      final repository = _FakeLibraryRepository([
        CursorPagination(
          data: const [MaterialModel(id: 'm1')],
          hasMore: false,
          total: 1,
        ),
      ]);
      final notifier = LibraryListNotifier(repository);

      await notifier.load();
      await notifier.loadMore();

      expect(repository.calls, 1);
    });

    test('disposing the provider during a request does not throw', () async {
      final completer = Completer<CursorPagination<MaterialModel>>();
      final container = ProviderContainer(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            _DelayedLibraryRepository(completer.future),
          ),
        ],
      );
      container.listen(libraryProvider, (_, __) {});

      final pending = container.read(libraryProvider.notifier).load();
      container.dispose();
      completer.complete(CursorPagination.empty());

      await pending;
    });
  });

  testWidgets('a material without public_url warns instead of opening a URL',
      (tester) async {
    final repository = _FakeLibraryRepository([
      CursorPagination(
        data: const [
          MaterialModel(id: 'm1', name: 'Sin enlace', publicUrl: ''),
        ],
        hasMore: false,
        total: 1,
      ),
    ]);

    await _pumpLibrary(tester, repository);

    await tester.tap(find.byIcon(PhosphorIconsRegular.link));
    await tester.pump();

    expect(
      find.text('Este material no tiene un enlace disponible'),
      findsOneWidget,
    );
  });
}
