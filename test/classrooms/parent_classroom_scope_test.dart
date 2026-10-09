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

PageResult<ClassroomModel> _page(List<ClassroomModel> data) => PageResult(
      data: data,
      page: 1,
      perPage: 20,
      total: data.length,
    );

class _FakeScopedRepository implements ClassroomRepository {
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
  }) {
    calls.add({'studentId': studentId, 'page': page, 'search': search});
    return Future.value(_page(const []));
  }

  @override
  Future<ClassroomModel> getClassroom(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<StudentModel>> getClassroomStudents(String id,
          {int page = 1, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<ProfessorModel>> getClassroomProfessors(String id,
          {int page = 1, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<PageResult<MaterialModel>> getClassroomMaterials(String id,
          {int page = 1, int limit = 20}) =>
      Future.error(UnimplementedError());

  @override
  Future<ClassroomFilters> getFilters() =>
      Future.value(const ClassroomFilters());
}

void main() {
  test('parent scope forwards student_id and filters to child classrooms',
      () async {
    final repository = _FakeScopedRepository();
    final notifier = ClassroomListNotifier(repository);
    await pumpEventQueue();

    await notifier.setStudent('stu-11');

    expect(repository.calls.last['studentId'], 'stu-11');
    expect(notifier.state.studentId, 'stu-11');
  });

  test('clearing student removes scope', () async {
    final repository = _FakeScopedRepository();
    final notifier = ClassroomListNotifier(repository);
    await pumpEventQueue();

    await notifier.setStudent('stu-11');
    await notifier.setStudent(null);

    expect(repository.calls.last['studentId'], isNull);
    expect(notifier.state.studentId, isNull);
  });
}
