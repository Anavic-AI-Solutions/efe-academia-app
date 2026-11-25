import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/pagination/cursor_list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

CursorPagination<int> _page(
  List<int> data, {
  String? nextCursor,
}) =>
    CursorPagination<int>(
      data: data,
      nextCursor: nextCursor,
      hasMore: nextCursor != null,
    );

typedef _Call = ({String? cursor, String search});

/// Loader double: records every call and answers with the queued responses in
/// order, so tests can control the timing of each request.
class _Loader {
  final List<_Call> calls = [];
  final List<Future<CursorPagination<int>> Function()> _responses = [];

  void enqueue(CursorPagination<int> page) {
    _responses.add(() async => page);
  }

  void enqueueFuture(Future<CursorPagination<int>> Function() response) {
    _responses.add(response);
  }

  void enqueueError(Object error) {
    _responses.add(() => Future.error(error));
  }

  Future<CursorPagination<int>> call({String? cursor, String search = ''}) {
    calls.add((cursor: cursor, search: search));
    if (_responses.isEmpty) {
      return Future.error(StateError('unexpected request'));
    }
    return _responses.removeAt(0)();
  }
}

void main() {
  group('CursorListNotifier', () {
    test('loads the first page on creation', () async {
      final loader = _Loader()..enqueue(_page([1, 2], nextCursor: 'c2'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      expect(loader.calls, [(cursor: null, search: '')]);
      expect(notifier.state.pagination.data, [1, 2]);
      expect(notifier.state.pagination.nextCursor, 'c2');
      expect(notifier.state.search, '');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadMore appends the next page using the next cursor', () async {
      final loader = _Loader()
        ..enqueue(_page([1, 2], nextCursor: 'c2'))
        ..enqueue(_page([3, 4], nextCursor: 'c3'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      await notifier.loadMore();

      expect(loader.calls, [
        (cursor: null, search: ''),
        (cursor: 'c2', search: ''),
      ]);
      expect(notifier.state.pagination.data, [1, 2, 3, 4]);
      expect(notifier.state.pagination.nextCursor, 'c3');
      expect(notifier.state.pagination.hasMore, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadMore does nothing when there is no next page', () async {
      final loader = _Loader()..enqueue(_page([1, 2]));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      await notifier.loadMore();

      expect(loader.calls.length, 1);
      expect(notifier.state.pagination.data, [1, 2]);
    });

    test('loadMore ignores a second call while one is in flight', () async {
      final secondPage = Completer<CursorPagination<int>>();
      final loader = _Loader()
        ..enqueue(_page([1], nextCursor: 'c2'))
        ..enqueueFuture(() => secondPage.future);
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      final first = notifier.loadMore();
      final second = notifier.loadMore();
      secondPage.complete(_page([2], nextCursor: 'c3'));
      await Future.wait<void>([first, second]);

      expect(loader.calls.length, 2);
      expect(notifier.state.pagination.data, [1, 2]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('setSearch resets to the first page', () async {
      final loader = _Loader()
        ..enqueue(_page([1, 2], nextCursor: 'c2'))
        ..enqueue(_page([3], nextCursor: 'c3'))
        ..enqueue(_page([7], nextCursor: 'c7'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();
      await notifier.loadMore();

      await notifier.setSearch('ana');

      expect(loader.calls, [
        (cursor: null, search: ''),
        (cursor: 'c2', search: ''),
        (cursor: null, search: 'ana'),
      ]);
      expect(notifier.state.search, 'ana');
      expect(notifier.state.pagination.data, [7]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('setSearch trims the query and ignores an unchanged one', () async {
      final loader = _Loader()
        ..enqueue(_page([1]))
        ..enqueue(_page([2]));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      await notifier.setSearch('  ');
      expect(loader.calls.length, 1);
      expect(notifier.state.search, '');

      await notifier.setSearch('  anan  ');
      expect(loader.calls.last, (cursor: null, search: 'anan'));
      expect(loader.calls.length, 2);
      expect(notifier.state.search, 'anan');
    });

    test('setSearch clears the previous results while the page is loading',
        () async {
      final searchPage = Completer<CursorPagination<int>>();
      final loader = _Loader()
        ..enqueue(_page([1, 2], nextCursor: 'c2'))
        ..enqueueFuture(() => searchPage.future);
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      final searchFuture = notifier.setSearch('ana');

      expect(notifier.state.search, 'ana');
      expect(notifier.state.pagination.data, isEmpty);
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.error, isNull);

      searchPage.complete(_page([9]));
      await searchFuture;

      expect(notifier.state.pagination.data, [9]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('exposes the error when the first load fails', () async {
      final loader = _Loader()..enqueueError(StateError('boom'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('boom'));
      expect(notifier.state.pagination.data, isEmpty);
    });

    test('loadMore keeps the current results when it fails', () async {
      final loader = _Loader()
        ..enqueue(_page([1], nextCursor: 'c2'))
        ..enqueueError(StateError('more'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      await notifier.loadMore();

      expect(notifier.state.pagination.data, [1]);
      expect(notifier.state.error, contains('more'));
      expect(notifier.state.isLoading, isFalse);
    });

    test('refresh reloads the first page and keeps the active search',
        () async {
      final loader = _Loader()
        ..enqueue(_page([1], nextCursor: 'c2'))
        ..enqueue(_page([7], nextCursor: 'c7'))
        ..enqueue(_page([8], nextCursor: 'c8'));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();
      await notifier.setSearch('ana');

      await notifier.refresh();

      expect(loader.calls.last, (cursor: null, search: 'ana'));
      expect(notifier.state.search, 'ana');
      expect(notifier.state.pagination.data, [8]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('refresh recovers from an error and clears it', () async {
      final loader = _Loader()
        ..enqueueError(StateError('boom'))
        ..enqueue(_page([1]));
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      await notifier.refresh();

      expect(notifier.state.error, isNull);
      expect(notifier.state.pagination.data, [1]);
    });

    test('ignores a stale first page that resolves after a newer search',
        () async {
      final initial = Completer<CursorPagination<int>>();
      final search = Completer<CursorPagination<int>>();
      final loader = _Loader()
        ..enqueueFuture(() => initial.future)
        ..enqueueFuture(() => search.future);
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      final searchFuture = notifier.setSearch('ana');
      search.complete(_page([2]));
      await searchFuture;

      initial.complete(_page([1]));
      await pumpEventQueue();

      expect(notifier.state.search, 'ana');
      expect(notifier.state.pagination.data, [2]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('ignores a stale loadMore that resolves after a new search', () async {
      final more = Completer<CursorPagination<int>>();
      final search = Completer<CursorPagination<int>>();
      final loader = _Loader()
        ..enqueue(_page([1], nextCursor: 'c2'))
        ..enqueueFuture(() => more.future)
        ..enqueueFuture(() => search.future);
      final notifier = CursorListNotifier<int>(loader.call);
      await pumpEventQueue();

      final moreFuture = notifier.loadMore();
      final searchFuture = notifier.setSearch('ana');
      search.complete(_page([2]));
      await searchFuture;

      more.complete(_page([99], nextCursor: 'c9'));
      await moreFuture;
      await pumpEventQueue();

      expect(notifier.state.pagination.data, [2]);
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
