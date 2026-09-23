import 'dart:async';

import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/pagination/paged_list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

PageResult<int> _page(
  List<int> data, {
  int page = 1,
  int perPage = 20,
  int? total,
}) =>
    PageResult(
      data: data,
      page: page,
      perPage: perPage,
      total: total ?? data.length,
    );

void main() {
  group('PagedListNotifier', () {
    test('loads the first page on creation', () async {
      final calls = <int>[];
      final notifier = PagedListNotifier<int>((page) async {
        calls.add(page);
        return _page([1, 2]);
      });
      await pumpEventQueue();

      expect(calls, [1]);
      expect(notifier.state.page.data, [1, 2]);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('goToPage fetches the requested page', () async {
      final calls = <int>[];
      final notifier = PagedListNotifier<int>((page) async {
        calls.add(page);
        return _page([page], page: page, total: 40);
      });
      await pumpEventQueue();

      await notifier.goToPage(2);

      expect(calls, [1, 2]);
      expect(notifier.state.page.page, 2);
      expect(notifier.state.page.data, [2]);
    });

    test('goToPage ignores the current page and out-of-range pages', () async {
      final calls = <int>[];
      final notifier = PagedListNotifier<int>((page) async {
        calls.add(page);
        return _page([1], total: 20);
      });
      await pumpEventQueue();

      await notifier.goToPage(1);
      await notifier.goToPage(0);
      await notifier.goToPage(5);

      expect(calls, [1]);
    });

    test('refresh reloads the current page', () async {
      final calls = <int>[];
      final notifier = PagedListNotifier<int>((page) async {
        calls.add(page);
        return _page([page], page: page, total: 40);
      });
      await pumpEventQueue();
      await notifier.goToPage(2);

      await notifier.refresh();

      expect(calls, [1, 2, 2]);
      expect(notifier.state.page.page, 2);
    });

    test('exposes the error when the fetch fails', () async {
      final notifier = PagedListNotifier<int>((page) async {
        throw Exception('boom');
      });
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('boom'));
    });

    test('falls back to page 1 when a page resolves empty', () async {
      final calls = <int>[];
      final notifier = PagedListNotifier<int>((page) async {
        calls.add(page);
        if (page == 2) {
          return _page(const [], page: 2, total: 40);
        }
        return _page([1, 2], total: 40);
      });
      await pumpEventQueue();

      await notifier.goToPage(2);

      expect(calls, [1, 2, 1]);
      expect(notifier.state.page.page, 1);
    });

    test('ignores a stale response that resolves after a newer request',
        () async {
      final first = Completer<PageResult<int>>();
      final responses = <Completer<PageResult<int>>>[first, Completer()];
      var call = 0;
      final notifier =
          PagedListNotifier<int>((page) => responses[call++].future);
      await pumpEventQueue();

      final refreshFuture = notifier.refresh();
      responses[1].complete(_page([2]));
      await refreshFuture;

      first.complete(_page([1]));
      await pumpEventQueue();

      expect(notifier.state.page.data, [2]);
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
