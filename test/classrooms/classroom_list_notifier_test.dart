import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ClassroomModel _classroom(String id, {String name = 'Room'}) =>
    ClassroomModel(id: id, name: name);

CursorPagination<ClassroomModel> _page(
  List<ClassroomModel> data, {
  bool hasMore = false,
  String? nextCursor,
}) =>
    CursorPagination(
      data: data,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];
  final List<Future<CursorPagination<ClassroomModel>> Function()> _responses =
      [];

  void enqueue(CursorPagination<ClassroomModel> page) {
    _responses.add(() => Future.value(page));
  }

  void enqueueFuture(Future<CursorPagination<ClassroomModel>> Function() fn) {
    _responses.add(fn);
  }

  @override
  Future<CursorPagination<ClassroomModel>> getClassrooms({
    String? search,
    String? cursor,
    String? branch,
    String? level,
    String? year,
    String? status,
  }) {
    calls.add({
      'search': search,
      'cursor': cursor,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
    });
    if (_responses.isEmpty) {
      return Future.value(_page(const []));
    }
    return _responses.removeAt(0)();
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

void main() {
  group('ClassroomListNotifier', () {
    test('applyFilters forwards filters, clears the cursor and reloads',
        () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page([_classroom('1')]));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page([_classroom('2', name: 'Vera Room')]));
      await notifier.applyFilters(branch: 'Vera', level: 'A2', year: '2026');

      expect(repository.calls.last['branch'], 'Vera');
      expect(repository.calls.last['level'], 'A2');
      expect(repository.calls.last['year'], '2026');
      expect(repository.calls.last['cursor'], isNull);
      expect(notifier.state.branch, 'Vera');
      expect(notifier.state.pagination.data.single.name, 'Vera Room');
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('loadMore keeps filters and cursor, and appends the page', () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page([_classroom('1')]));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(
        _page([_classroom('2')], hasMore: true, nextCursor: 'cursor-2'),
      );
      await notifier.applyFilters(branch: 'Vera');

      repository.enqueue(_page([_classroom('3')]));
      await notifier.loadMore();

      expect(repository.calls.last['branch'], 'Vera');
      expect(repository.calls.last['cursor'], 'cursor-2');
      expect(
        notifier.state.pagination.data.map((c) => c.id).toList(),
        ['2', '3'],
      );
    });

    test('search keeps the active filters', () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page(const []));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page(const []));
      await notifier.applyFilters(branch: 'Vera');

      repository.enqueue(_page(const []));
      await notifier.search('A2');

      expect(repository.calls.last['search'], 'A2');
      expect(repository.calls.last['branch'], 'Vera');
      expect(repository.calls.last['cursor'], isNull);
    });

    test('clearFilters resets the active filters and reloads', () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page(const []));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page(const []));
      await notifier.applyFilters(branch: 'Vera', status: 'archived');

      repository.enqueue(_page(const []));
      await notifier.clearFilters();

      expect(repository.calls.last['branch'], isNull);
      expect(repository.calls.last['status'], isNull);
      expect(notifier.state.hasActiveFilters, isFalse);
    });

    test('ignores a stale response that resolves after newer filters', () async {
      final repository = _FakeClassroomRepository();
      final initial = Completer<CursorPagination<ClassroomModel>>();
      repository.enqueueFuture(() => initial.future);
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      final filtered = Completer<CursorPagination<ClassroomModel>>();
      repository.enqueueFuture(() => filtered.future);
      final applyFuture = notifier.applyFilters(branch: 'Vera');

      filtered.complete(_page([_classroom('filtered', name: 'Filtered')]));
      await applyFuture;

      initial.complete(_page([_classroom('stale', name: 'Stale')]));
      await pumpEventQueue();

      expect(
        notifier.state.pagination.data.map((c) => c.id).toList(),
        ['filtered'],
      );
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
