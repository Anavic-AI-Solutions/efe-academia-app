import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/classrooms/data/classroom_repository.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_filters.dart';
import 'package:efe_mobile/features/classrooms/domain/classroom_model.dart';
import 'package:efe_mobile/features/classrooms/domain/material_model.dart';
import 'package:efe_mobile/features/classrooms/domain/professor_model.dart';
import 'package:efe_mobile/features/classrooms/providers/classroom_provider.dart';
import 'package:efe_mobile/features/classrooms/screens/parent_courses_screen.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
      'status': status,
      'studentId': studentId,
    });
    return PageResult(
      data: const [
        ClassroomModel(id: 'c1', name: 'Curso de Ana'),
        ClassroomModel(id: 'c2', name: 'Curso de Bruno'),
      ],
      page: page,
      perPage: limit,
      total: 2,
    );
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
}

void main() {
  testWidgets('parent courses list every child course without a selector',
      (tester) async {
    final repository = _FakeClassroomRepository();
    final container = ProviderContainer(
      overrides: [
        classroomRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ParentCoursesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cursos'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Curso de Ana'), findsOneWidget);
    expect(find.text('Curso de Bruno'), findsOneWidget);
    expect(repository.calls, hasLength(1));
    expect(repository.calls.single['studentId'], isNull);
  });
}
