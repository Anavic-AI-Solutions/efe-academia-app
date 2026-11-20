import 'package:dio/dio.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_api.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQualificationApi implements QualificationApi {
  Map<String, dynamic> summaryPayload;
  Map<String, dynamic>? createdPayload;

  _FakeQualificationApi(this.summaryPayload);

  @override
  Future<Response> getClassroomGradesSummary(String classroomId) async =>
      Response(
        requestOptions:
            RequestOptions(path: '/classrooms/$classroomId/grades-summary'),
        data: summaryPayload,
      );

  @override
  Future<Response> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) async {
    createdPayload = {
      'student_id': studentId,
      'classroom_id': classroomId,
      'score': score,
      'type': type,
      'period': period,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    return Response(
      requestOptions: RequestOptions(path: '/qualifications'),
      data: {
        'data': {'type': 'qualifications', 'id': 'q1', 'attributes': {}},
      },
    );
  }

  @override
  Future<Response> getQualification(String id) => throw UnimplementedError();

  @override
  Future<Response> updateQualification(
    String id,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<Response> deleteQualification(String id) => throw UnimplementedError();

  @override
  Future<Response> getBoletin(String studentId, String classroomId) =>
      throw UnimplementedError();

  @override
  Future<Response> getBoletinLink(String studentId, String classroomId) =>
      throw UnimplementedError();

  @override
  Future<Response> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
    int? page,
    int limit = 20,
  }) =>
      throw UnimplementedError();
}

const _summaryPayload = {
  'data': {
    'type': 'grade_summaries',
    'id': 'c1',
    'attributes': {
      'classroom_id': 'c1',
      'classroom_name': '3G X',
      'classroom_average': 7.5,
      'students_count': 2,
      'students': [
        {'student_id': 's1', 'fullname': 'Marega, Paola', 'average': 9.2},
        {'student_id': 's2', 'fullname': 'Díaz, Sol', 'average': null},
      ],
    },
  },
};

void main() {
  group('QualificationRepository', () {
    test('parses the classroom grades summary', () async {
      final repository =
          QualificationRepository(_FakeQualificationApi(_summaryPayload));

      final summary = await repository.getClassroomGradesSummary('c1');

      expect(summary.classroomName, '3G X');
      expect(summary.classroomAverage, 7.5);
      expect(summary.students, hasLength(2));
      expect(summary.students.first.average, 9.2);
      expect(summary.students.last.average, isNull);
    });

    test('sends the qualification payload', () async {
      final api = _FakeQualificationApi(_summaryPayload);
      final repository = QualificationRepository(api);

      await repository.createQualification(
        studentId: 's1',
        classroomId: 'c1',
        score: '8.5',
        type: 'Parcial',
        period: '2',
        description: 'Parcial de anatomía',
      );

      expect(api.createdPayload, {
        'student_id': 's1',
        'classroom_id': 'c1',
        'score': '8.5',
        'type': 'Parcial',
        'period': '2',
        'description': 'Parcial de anatomía',
      });
    });
  });

  group('classroomGradesProvider', () {
    test('exposes the summary from the repository', () async {
      final container = ProviderContainer(
        overrides: [
          qualificationRepositoryProvider.overrideWithValue(
            QualificationRepository(_FakeQualificationApi(_summaryPayload)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        classroomGradesProvider('c1'),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      final summary = container.read(classroomGradesProvider('c1')).value;
      expect(summary, isA<ClassroomGradesSummary>());
      expect(summary?.classroomAverage, 7.5);
    });
  });
}
