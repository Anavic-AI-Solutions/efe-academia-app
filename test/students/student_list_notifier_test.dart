import 'dart:async';

import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:flutter_test/flutter_test.dart';

StudentModel _student(
  String id, {
  String name = 'Student',
  String year = '',
  String branch = '',
}) =>
    StudentModel(id: id, fullname: name, year: year, branch: branch);

PageResult<StudentModel> _page(
  List<StudentModel> data, {
  int page = 1,
  int total = 0,
}) =>
    PageResult(
      data: data,
      page: page,
      perPage: 20,
      total: total == 0 ? data.length : total,
    );

class _FakeStudentRepository implements StudentRepository {
  final List<Map<String, Object?>> calls = [];
  final List<Future<PageResult<StudentModel>> Function()> _responses = [];

  void enqueue(PageResult<StudentModel> page) {
    _responses.add(() => Future.value(page));
  }

  void enqueueFuture(Future<PageResult<StudentModel>> Function() fn) {
    _responses.add(fn);
  }

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) {
    calls.add({
      'search': search,
      'status': status,
      'year': year,
      'branch': branch,
      'page': page,
    });
    if (_responses.isEmpty) {
      return Future.value(_page(const []));
    }
    return _responses.removeAt(0)();
  }

  @override
  Future<StudentModel> getStudent(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<List<ClassroomModel>> getClassrooms(String studentId) async =>
      const [];
}

void main() {
  group('StudentListNotifier', () {
    test('loads the first page on creation', () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page([_student('1')], total: 57));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      expect(repository.calls.single['page'], 1);
      expect(repository.calls.single['status'], 'active');
      expect(notifier.state.page.data.single.id, '1');
      expect(notifier.state.page.totalPages, 3);
      expect(notifier.state.isLoading, isFalse);
    });

    test('goToPage keeps the filters and fetches the requested page',
        () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page([_student('1')], total: 57));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page([_student('1')], total: 57));
      await notifier.setBranch('Reconquista');
      repository.enqueue(_page([_student('21')], page: 2, total: 57));
      await notifier.goToPage(2);

      expect(repository.calls.last['branch'], 'Reconquista');
      expect(repository.calls.last['page'], 2);
      expect(notifier.state.page.data.single.id, '21');
    });

    test('goToPage ignores out-of-range and current pages', () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page([_student('1')], total: 57));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      await notifier.goToPage(1);
      await notifier.goToPage(0);
      await notifier.goToPage(9);

      expect(repository.calls.length, 1);
    });

    test('search resets to page 1 and keeps the filters', () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page(const []));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page(const []));
      await notifier.setYear('2026');

      repository.enqueue(_page(const []));
      await notifier.search('Ana');

      expect(repository.calls.last['search'], 'Ana');
      expect(repository.calls.last['year'], '2026');
      expect(repository.calls.last['page'], 1);
    });

    test('setStatus maps all to a null status param', () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page(const []));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(_page(const []));
      await notifier.setStatus(StudentListState.statusAll);

      expect(repository.calls.last['status'], isNull);
      expect(notifier.state.status, StudentListState.statusAll);
    });

    test('accumulates filter options across pages', () async {
      final repository = _FakeStudentRepository();
      repository.enqueue(_page([_student('1', year: '2025', branch: 'Vera')],
          total: 57));
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(
        _page([_student('21', year: '2026', branch: 'Reconquista')],
            page: 2, total: 57),
      );
      await notifier.goToPage(2);

      expect(notifier.state.yearOptions, ['2025', '2026']);
      expect(notifier.state.branchOptions, ['Reconquista', 'Vera']);
    });

    test('ignores a stale response that resolves after newer filters',
        () async {
      final repository = _FakeStudentRepository();
      final initial = Completer<PageResult<StudentModel>>();
      repository.enqueueFuture(() => initial.future);
      final notifier = StudentListNotifier(repository);
      await pumpEventQueue();

      final filtered = Completer<PageResult<StudentModel>>();
      repository.enqueueFuture(() => filtered.future);
      final setFuture = notifier.setBranch('Vera');

      filtered.complete(_page([_student('filtered', name: 'Filtered')]));
      await setFuture;

      initial.complete(_page([_student('stale', name: 'Stale')]));
      await pumpEventQueue();

      expect(notifier.state.page.data.single.id, 'filtered');
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
