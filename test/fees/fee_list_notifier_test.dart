import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:flutter_test/flutter_test.dart';

FeeModel _fee(String id, String student) => FeeModel(
      id: id,
      studentId: student,
      studentName: student,
      numberFee: 1,
      status: 'pending',
    );

CursorPagination<FeeModel> _page(List<FeeModel> data) => CursorPagination(
      data: data,
      nextCursor: null,
      hasMore: false,
      total: data.length,
    );

class _FakeFeeRepository implements FeeRepository {
  Map<String, dynamic>? lastQuery;
  final List<Future<CursorPagination<FeeModel>> Function()> _queued = [];

  CursorPagination<FeeModel> _empty() => CursorPagination.empty();

  void enqueue(CursorPagination<FeeModel> page) {
    _queued.add(() => Future.value(page));
  }

  void enqueueFuture(Future<CursorPagination<FeeModel>> Function() fn) {
    _queued.add(fn);
  }

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    lastQuery = {'studentId': studentId, 'search': search, 'cursor': cursor};
    if (_queued.isNotEmpty) return _queued.removeAt(0)();
    return _empty();
  }

  @override
  Future<FeeModel> getFee(String id) => throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(String studentAppId,
      {int page = 1, int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> getInvoiceUrl(String feeId) => throw UnimplementedError();

  @override
  Future<Never> getInvoiceFile(String feeId) => throw UnimplementedError();
}

void main() {
  group('FeeListNotifier student scope', () {
    test('load forwards selected studentId to repository and search keeps it',
        () async {
      final repository = _FakeFeeRepository();
      final notifier = FeeListNotifier(repository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.setStudent('stu-11');
      expect(repository.lastQuery?['studentId'], 'stu-11');

      await notifier.search('marzo');
      expect(repository.lastQuery?['studentId'], 'stu-11');
      expect(notifier.state.studentId, 'stu-11');
    });

    test('clearing student reloads without scope', () async {
      final repository = _FakeFeeRepository();
      final notifier = FeeListNotifier(repository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.setStudent('stu-11');
      await notifier.setStudent(null);
      expect(repository.lastQuery?['studentId'], isNull);
      expect(notifier.state.studentId, isNull);
    });

    test('ignores a stale response that resolves after switching child',
        () async {
      final repository = _FakeFeeRepository();
      final notifier = FeeListNotifier(repository);
      await pumpEventQueue();

      final slowA = Completer<CursorPagination<FeeModel>>();
      repository.enqueueFuture(() => slowA.future);
      final first = notifier.setStudent('stu-A');

      final fastB = Completer<CursorPagination<FeeModel>>();
      repository.enqueueFuture(() => fastB.future);
      final second = notifier.setStudent('stu-B');

      fastB.complete(_page([_fee('f-b', 'stu-B')]));
      await second;

      slowA.complete(_page([_fee('f-a', 'stu-A')]));
      await first;
      await pumpEventQueue();

      expect(notifier.state.studentId, 'stu-B');
      expect(
        notifier.state.pagination.data.map((f) => f.id).toList(),
        ['f-b'],
      );
    });
  });
}
