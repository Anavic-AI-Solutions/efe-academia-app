import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeeRepository implements FeeRepository {
  Map<String, dynamic>? lastQuery;

  CursorPagination<FeeModel> _empty() => CursorPagination.empty();

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    lastQuery = {'studentId': studentId, 'search': search, 'cursor': cursor};
    return _empty();
  }

  @override
  Future<FeeModel> getFee(String id) => throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(String studentAppId,
      {int page = 1, int limit = 20}) {
    throw UnimplementedError();
  }
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
  });
}
