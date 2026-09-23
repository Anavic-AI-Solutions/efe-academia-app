import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart';
import 'package:efe_mobile/features/students/data/absence_repository.dart';
import 'package:efe_mobile/features/students/data/student_repository.dart';
import 'package:efe_mobile/features/students/domain/absence_model.dart';
import 'package:efe_mobile/features/students/domain/student_model.dart';
import 'package:efe_mobile/features/students/providers/student_provider.dart';
import 'package:efe_mobile/features/students/screens/student_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.student, this.fails = false});

  final StudentModel? student;
  final bool fails;

  @override
  Future<StudentModel> getStudent(String id) async {
    if (fails) throw Exception('boom');
    return student!;
  }

  @override
  Future<PageResult<StudentModel>> getStudents({
    String? search,
    String? status,
    String? year,
    String? branch,
    int page = 1,
    int limit = 20,
  }) =>
      Future.error(UnimplementedError());
}

class _FakeQualificationRepository implements QualificationRepository {
  _FakeQualificationRepository({this.items = const []});

  final List<QualificationModel> items;

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
      );

  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) =>
      Future.error(UnimplementedError());
}

class _FakeAbsenceRepository implements AbsenceRepository {
  _FakeAbsenceRepository({this.items = const []});

  final List<AbsenceModel> items;

  @override
  Future<PageResult<AbsenceModel>> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
      );
}

class _FakeFeeRepository implements FeeRepository {
  _FakeFeeRepository({this.items = const []});

  final List<FeeModel> items;

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) async =>
      PageResult(
        data: items,
        page: page,
        perPage: limit,
        total: items.length,
      );

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<FeeModel> getFee(String id) => Future.error(UnimplementedError());
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  _FakeStudentRepository? students,
  _FakeQualificationRepository? qualifications,
  _FakeAbsenceRepository? absences,
  _FakeFeeRepository? fees,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider
            .overrideWithValue(students ?? _FakeStudentRepository()),
        qualificationRepositoryProvider
            .overrideWithValue(qualifications ?? _FakeQualificationRepository()),
        absenceRepositoryProvider
            .overrideWithValue(absences ?? _FakeAbsenceRepository()),
        feeRepositoryProvider
            .overrideWithValue(fees ?? _FakeFeeRepository()),
      ],
      child: localizedApp(
        home: const StudentDetailScreen(studentId: 's1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(TabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

const _student = StudentModel(
  id: 's1',
  fullname: 'Ana Gómez',
  email: 'ana@example.com',
  year: '2026',
  branch: 'Reconquista',
  identityNumber: '30111222',
  status: 'active',
  classroomCount: 3,
);

void main() {
  testWidgets('renders the hero header and the tabs', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Reconquista'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Inasistencias'), findsOneWidget);
    expect(find.text('Cuotas'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
  });

  testWidgets('shows the info tab with stats and sections', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    await _openTab(tester, 'Información');

    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Institucional'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('30111222'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
    expect(find.text('Reconquista'), findsWidgets);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('lists grades on the grades tab', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      qualifications: _FakeQualificationRepository(
        items: const [
          QualificationModel(
            id: 'q1',
            score: 8.5,
            type: 'Parcial',
            period: '1',
            description: 'Primer parcial',
            date: '12/03/2026',
          ),
        ],
      ),
    );

    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Parcial'), findsOneWidget);
    expect(find.text('Primer parcial'), findsOneWidget);
    expect(find.text('Período 1 · 12/03/2026'), findsOneWidget);
  });

  testWidgets('lists absences and fees', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
      absences: _FakeAbsenceRepository(
        items: const [
          AbsenceModel(
            id: 'a1',
            quantity: 2,
            period: '1',
            justified: 'si',
            description: 'Fiebre',
            date: '12/03/2026',
          ),
        ],
      ),
      fees: _FakeFeeRepository(
        items: const [
          FeeModel(
            id: 'f1',
            numberFee: 1,
            month: '3',
            year: '2026',
            total: 25000,
            status: 'pending',
          ),
        ],
      ),
    );

    await _openTab(tester, 'Inasistencias');
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Fiebre'), findsOneWidget);
    expect(find.text('Justificada'), findsOneWidget);

    await _openTab(tester, 'Cuotas');
    expect(find.text('Cuota #1 · 3 2026'), findsOneWidget);
    expect(find.textContaining('25.000'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
  });

  testWidgets('shows empty states for related tabs', (tester) async {
    await _pumpDetail(
      tester,
      students: _FakeStudentRepository(student: _student),
    );

    expect(find.text('No hay notas disponibles'), findsOneWidget);

    await _openTab(tester, 'Inasistencias');
    expect(find.text('No hay inasistencias registradas'), findsOneWidget);

    await _openTab(tester, 'Cuotas');
    expect(find.text('No hay cuotas disponibles'), findsOneWidget);
  });

  testWidgets('shows the error view when the student fails to load',
      (tester) async {
    await _pumpDetail(tester, students: _FakeStudentRepository(fails: true));

    expect(find.text('No se pudo cargar el estudiante'), findsOneWidget);
  });
}
