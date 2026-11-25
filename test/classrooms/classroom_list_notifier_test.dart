import 'dart:async';

import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter_test/flutter_test.dart';

ClassroomModel _classroom(String id, {String name = 'Room'}) =>
    ClassroomModel(id: id, name: name);

PageResult<ClassroomModel> _page(
  List<ClassroomModel> data, {
  int page = 1,
  int total = 0,
}) =>
    PageResult(
      data: data,
      page: page,
      perPage: 20,
      total: total == 0 ? data.length : total,
    );

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];
  final List<Future<PageResult<ClassroomModel>> Function()> _responses = [];

  void enqueue(PageResult<ClassroomModel> page) {
    _responses.add(() => Future.value(page));
  }

  void enqueueFuture(Future<PageResult<ClassroomModel>> Function() fn) {
    _responses.add(fn);
  }

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
  }) {
    calls.add({
      'search': search,
      'page': page,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
      'studentId': studentId,
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
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());

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

void main() {
  group('ClassroomListNotifier', () {
    test('applyFilters forwards filters, resets to page 1 and reloads',
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
      expect(repository.calls.last['page'], 1);
      expect(notifier.state.branch, 'Vera');
      expect(notifier.state.page.data.single.name, 'Vera Room');
      expect(notifier.state.hasActiveFilters, isTrue);
    });

    test('goToPage keeps filters and fetches the requested page', () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page([_classroom('1')], total: 57));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      repository.enqueue(
        _page([_classroom('1')], page: 1, total: 57),
      );
      await notifier.applyFilters(branch: 'Vera');
      repository.enqueue(_page([_classroom('21')], page: 2, total: 57));
      await notifier.goToPage(2);

      expect(repository.calls.last['branch'], 'Vera');
      expect(repository.calls.last['page'], 2);
      expect(notifier.state.page.page, 2);
      expect(notifier.state.page.data.single.id, '21');
      expect(notifier.state.page.totalPages, 3);
    });

    test('goToPage ignores out-of-range and current pages', () async {
      final repository = _FakeClassroomRepository();
      repository.enqueue(_page([_classroom('1')], total: 57));
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      await notifier.goToPage(1);
      await notifier.goToPage(0);
      await notifier.goToPage(9);

      expect(repository.calls.length, 1);
    });

    test('search keeps the active filters and resets the page', () async {
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
      expect(repository.calls.last['page'], 1);
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

    test('ignores a stale response that resolves after newer filters',
        () async {
      final repository = _FakeClassroomRepository();
      final initial = Completer<PageResult<ClassroomModel>>();
      repository.enqueueFuture(() => initial.future);
      final notifier = ClassroomListNotifier(repository);
      await pumpEventQueue();

      final filtered = Completer<PageResult<ClassroomModel>>();
      repository.enqueueFuture(() => filtered.future);
      final applyFuture = notifier.applyFilters(branch: 'Vera');

      filtered.complete(_page([_classroom('filtered', name: 'Filtered')]));
      await applyFuture;

      initial.complete(_page([_classroom('stale', name: 'Stale')]));
      await pumpEventQueue();

      expect(
        notifier.state.page.data.map((c) => c.id).toList(),
        ['filtered'],
      );
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
