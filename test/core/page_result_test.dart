import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageResult', () {
    test('computes total pages, bounds and item range', () {
      const page = PageResult<int>(
        data: [1, 2, 3],
        page: 2,
        perPage: 20,
        total: 57,
      );

      expect(page.totalPages, 3);
      expect(page.hasPrev, isTrue);
      expect(page.hasNext, isTrue);
      expect(page.firstItem, 21);
      expect(page.lastItem, 23);
    });

    test('empty result has a single page and no navigation', () {
      final page = PageResult<int>.empty();

      expect(page.totalPages, 1);
      expect(page.hasPrev, isFalse);
      expect(page.hasNext, isFalse);
      expect(page.firstItem, 0);
      expect(page.lastItem, 0);
      expect(page.data, isEmpty);
    });

    test('last page has no next and reports the final item', () {
      const page = PageResult<int>(
        data: [1],
        page: 3,
        perPage: 20,
        total: 41,
      );

      expect(page.hasNext, isFalse);
      expect(page.hasPrev, isTrue);
      expect(page.firstItem, 41);
      expect(page.lastItem, 41);
    });

    test('copyWith replaces only the provided fields', () {
      const page = PageResult<int>(
        data: [1],
        page: 1,
        perPage: 20,
        total: 41,
      );

      final copy = page.copyWith(page: 2, data: const [2]);

      expect(copy.page, 2);
      expect(copy.data, [2]);
      expect(copy.perPage, 20);
      expect(copy.total, 41);
    });
  });
}
