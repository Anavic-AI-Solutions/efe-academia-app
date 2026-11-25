import 'dart:async';

import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PageResult<ClassroomModel> _page(List<ClassroomModel> data) => PageResult(
      data: data,
      page: 1,
      perPage: 20,
      total: data.length,
    );

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Map<String, Object?>> calls = [];

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
  }) async {
    calls.add({
      'search': search,
      'page': page,
      'branch': branch,
      'level': level,
      'year': year,
      'status': status,
      'studentId': studentId,
    });
    return _page(const []);
  }

  @override
  Future<ClassroomModel> getClassroom(String id) => throw UnimplementedError();

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() async => const ClassroomFilters();

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
  @override
  Future<ClassroomModel> setArchived(String id, bool isArchived) =>
      Future.error(UnimplementedError());
}

class _DelayedClassroomRepository implements ClassroomRepository {
  _DelayedClassroomRepository(this.future);

  final Future<PageResult<ClassroomModel>> future;

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
  }) =>
      future;

  @override
  Future<ClassroomModel> getClassroom(String id) => throw UnimplementedError();

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomFilters> getFilters() async => const ClassroomFilters();

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
  @override
  Future<ClassroomModel> setArchived(String id, bool isArchived) =>
      Future.error(UnimplementedError());
}

void main() {
  group('ClassroomListNotifier history mode', () {
    test('initialStatus archived is the first request and state', () async {
      final repository = _FakeClassroomRepository();
      final notifier =
          ClassroomListNotifier(repository, initialStatus: 'archived');
      await pumpEventQueue();

      expect(notifier.state.status, 'archived');
      expect(repository.calls, isNotEmpty);
      expect(repository.calls.first['status'], 'archived');
      expect(repository.calls.first['studentId'], isNull);
    });

    test('setStudent keeps the archived scope for parent history', () async {
      final repository = _FakeClassroomRepository();
      final notifier =
          ClassroomListNotifier(repository, initialStatus: 'archived');
      await pumpEventQueue();

      await notifier.setStudent('42');

      expect(repository.calls.last['studentId'], '42');
      expect(repository.calls.last['status'], 'archived');
      expect(notifier.state.studentId, '42');
      expect(notifier.state.status, 'archived');
    });

    test('search keeps archived status and the selected child', () async {
      final repository = _FakeClassroomRepository();
      final notifier =
          ClassroomListNotifier(repository, initialStatus: 'archived');
      await pumpEventQueue();

      await notifier.setStudent('42');
      await notifier.search('mate');

      final last = repository.calls.last;
      expect(last['search'], 'mate');
      expect(last['studentId'], '42');
      expect(last['status'], 'archived');
      expect(notifier.state.search, 'mate');
      expect(notifier.state.studentId, '42');
      expect(notifier.state.status, 'archived');
    });

    test('disposing the provider during a request does not throw', () async {
      final completer = Completer<PageResult<ClassroomModel>>();
      final container = ProviderContainer(
        overrides: [
          classroomRepositoryProvider.overrideWithValue(
            _DelayedClassroomRepository(completer.future),
          ),
        ],
      );
      container.listen(classroomHistoryProvider, (_, __) {});

      final pending = container.read(classroomHistoryProvider.notifier).load();
      container.dispose();
      completer.complete(_page(const []));

      await pending;
    });
  });
}
