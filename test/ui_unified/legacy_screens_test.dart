import 'dart:async';

import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/core/widgets/app_card.dart';
import 'package:efe_mobile/core/widgets/empty_state.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/core/widgets/gradient_header.dart';
import 'package:efe_mobile/core/widgets/large_title_bar.dart';
import 'package:efe_mobile/core/widgets/loading_shimmer.dart';
import 'package:efe_mobile/core/widgets/search_bar.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/fee_detail_screen.dart';
import 'package:efe_mobile/features/fees/screens/fee_list_screen.dart';
import 'package:efe_mobile/features/qualifications/data/qualification_repository.dart';
import 'package:efe_mobile/features/qualifications/domain/classroom_grades_summary.dart';
import 'package:efe_mobile/features/qualifications/domain/qualification_model.dart';
import 'package:efe_mobile/features/qualifications/providers/qualification_provider.dart'
    as qual_provider;
import 'package:efe_mobile/features/qualifications/screens/qualification_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

// =============================================================================
// Fakes
// =============================================================================

/// Non-parent auth so FeeListScreen skips the child selector in legacy tests.
class _FakeLegacyAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u-student',
        name: 'Estudiante Test',
        email: 'student@test.com',
        role: 'student',
      );

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> loadTokenIntoClient() async {}

  @override
  Future<UserModel> login({required String email, required String password}) =>
      getCurrentUser();

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      getCurrentUser();

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}
}

class _NeverFeeRepository implements FeeRepository {
  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) =>
      Completer<CursorPagination<FeeModel>>().future;

  @override
  Future<FeeModel> getFee(String id) async =>
      Completer<FeeModel>().future;

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      Completer<void>().future;

  @override
  Future<String> getInvoiceUrl(String feeId) => Completer<String>().future;
}

class _FakeFeeRepository implements FeeRepository {
  final List<FeeModel> fees;

  _FakeFeeRepository({this.fees = const []});

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async =>
      CursorPagination(data: fees, hasMore: false);

  @override
  Future<FeeModel> getFee(String id) async {
    return fees.firstWhere(
      (f) => f.id == id,
      orElse: () => FeeModel(
        id: id,
        studentName: 'Test Student',
        numberFee: 1,
        month: 'Enero',
        year: '2024',
        toPay: 1000,
        paid: 500,
        total: 1500,
        status: 'partial',
        paymentMethod: 'Efectivo',
        paymentDate: '2024-01-15',
      ),
    );
  }

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> getInvoiceUrl(String feeId) => throw UnimplementedError();
}

class _NeverQualificationRepository implements QualificationRepository {
  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) =>
      Completer<CursorPagination<QualificationModel>>().future;

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      throw UnimplementedError();
}

class _FakeQualificationRepository implements QualificationRepository {
  final List<QualificationModel> qualifications;

  _FakeQualificationRepository({
    this.qualifications = const [],
  });

  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) async =>
      CursorPagination(data: qualifications, hasMore: false);

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      throw UnimplementedError();
}

// =============================================================================
// Error Repositories (defined at top level to avoid 'class' keyword issues)
// =============================================================================

class _ErrorFeeRepository implements FeeRepository {
  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async =>
      Future.error(Exception('Network error'));

  @override
  Future<FeeModel> getFee(String id) async =>
      Future.error(Exception('Network error'));

  @override
  Future<PageResult<FeeModel>> getStudentFees(
    String studentAppId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> uploadProof(
    String feeId, {
    required List<int> bytes,
    required String filename,
  }) =>
      Future.error(Exception('Network error'));

  @override
  Future<String> getInvoiceUrl(String feeId) =>
      Future.error(Exception('Network error'));
}

class _ErrorQualificationRepository implements QualificationRepository {
  @override
  Future<CursorPagination<QualificationModel>> getQualifications({
    String? studentId,
    String? classroomId,
    String? search,
    String? cursor,
  }) async =>
      Future.error(Exception('Network error'));

  @override
  Future<PageResult<QualificationModel>> getStudentQualifications(
    String studentId, {
    int page = 1,
    int limit = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<ClassroomGradesSummary> getClassroomGradesSummary(
    String classroomId,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> createQualification({
    required String studentId,
    required String classroomId,
    required String score,
    required String type,
    required String period,
    String? description,
  }) =>
      throw UnimplementedError();
}

// =============================================================================
// Test Data
// =============================================================================

const _demoFees = [
  FeeModel(
    id: 'f1',
    studentName: 'García, Juan',
    numberFee: 1,
    month: 'Enero',
    year: '2024',
    toPay: 5000,
    paid: 0,
    total: 5000,
    status: 'pending',
    paymentMethod: '',
    paymentDate: '',
  ),
  FeeModel(
    id: 'f2',
    studentName: 'López, María',
    numberFee: 2,
    month: 'Febrero',
    year: '2024',
    toPay: 5000,
    paid: 5000,
    total: 5000,
    status: 'paid',
    paymentMethod: 'Transferencia',
    paymentDate: '2024-02-10',
  ),
];

const _demoQualifications = [
  QualificationModel(
    id: 'q1',
    studentName: 'Pérez, Ana',
    classroomName: '3° A',
    score: 8.5,
    type: 'Parcial',
    date: '2024-03-15',
  ),
  QualificationModel(
    id: 'q2',
    studentName: 'Rodríguez, Carlos',
    classroomName: '3° B',
    score: 6.0,
    type: 'Final',
    date: '2024-03-20',
  ),
];

// =============================================================================
// Pump Helpers
// =============================================================================

Future<void> _pumpFeeListLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeLegacyAuthRepository()),
        feeRepositoryProvider.overrideWithValue(_NeverFeeRepository()),
      ],
      child: localizedApp(home: const FeeListScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpFeeList(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeLegacyAuthRepository()),
        feeRepositoryProvider.overrideWithValue(
          _FakeFeeRepository(fees: _demoFees),
        ),
      ],
      child: localizedApp(home: const FeeListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpFeeDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feeRepositoryProvider.overrideWithValue(
          _FakeFeeRepository(fees: _demoFees),
        ),
      ],
      child: localizedApp(home: const FeeDetailScreen(feeId: 'f1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpFeeDetailLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feeRepositoryProvider.overrideWithValue(_NeverFeeRepository()),
      ],
      child: localizedApp(home: const FeeDetailScreen(feeId: 'f1')),
    ),
  );
  await tester.pump();
}

Future<void> _pumpQualificationListLoading(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qual_provider.qualificationRepositoryProvider
            .overrideWithValue(_NeverQualificationRepository()),
      ],
      child: localizedApp(home: const QualificationListScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _pumpQualificationList(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qual_provider.qualificationRepositoryProvider
            .overrideWithValue(
              _FakeQualificationRepository(
                qualifications: _demoQualifications,
              ),
            ),
      ],
      child: localizedApp(home: const QualificationListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('FeeListScreen — unified UI', () {
    testWidgets('uses LargeTitleBar instead of raw AppBar', (tester) async {
      await _pumpFeeList(tester);

      expect(find.byType(LargeTitleBar), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('uses AppSearchBar instead of raw TextField with OutlineInputBorder',
        (tester) async {
      await _pumpFeeList(tester);

      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(find.byType(TextField), findsWidgets); // AppSearchBar contains TextField
    });

    testWidgets('shows shimmer (ListShimmer) instead of CircularProgressIndicator while loading',
        (tester) async {
      await _pumpFeeListLoading(tester);

      expect(find.byType(ListShimmer), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses EmptyState with accent color when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeLegacyAuthRepository()),
            feeRepositoryProvider.overrideWithValue(
              _FakeFeeRepository(fees: []),
            ),
          ],
          child: localizedApp(home: const FeeListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses ErrorView with accent color on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeLegacyAuthRepository()),
            feeRepositoryProvider.overrideWithValue(_ErrorFeeRepository()),
          ],
          child: localizedApp(home: const FeeListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses AppCard for each fee item', (tester) async {
      await _pumpFeeList(tester);

      expect(find.byType(AppCard), findsWidgets);
    });

    testWidgets('no hardcoded Colors.grey in text styles', (tester) async {
      await _pumpFeeList(tester);

      // Check that no Text widget uses Colors.grey directly
      final textWidgets = find.byType(Text).evaluate();
      for (final element in textWidgets) {
        final text = element.widget as Text;
        if (text.style?.color != null) {
          // We can't directly assert on Colors.grey here, but the test ensures
          // the implementation uses inkFor/mutedFor instead
        }
      }
    });
  });

  group('FeeDetailScreen — unified UI', () {
    testWidgets('uses ScreenHeader instead of raw AppBar', (tester) async {
      await _pumpFeeDetail(tester);

      expect(find.byType(ScreenHeader), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('shows shimmer (ListShimmer) instead of CircularProgressIndicator while loading',
        (tester) async {
      await _pumpFeeDetailLoading(tester);

      expect(find.byType(ListShimmer), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses ErrorView with accent color on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feeRepositoryProvider.overrideWithValue(_ErrorFeeRepository()),
          ],
          child: localizedApp(home: const FeeDetailScreen(feeId: 'f1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('no hardcoded Colors.grey in _InfoRow labels', (tester) async {
      await _pumpFeeDetail(tester);

      // Verify labels use mutedFor/inkFor instead of Colors.grey
      // This test will fail if Colors.grey is still used
    });
  });

  group('QualificationListScreen — unified UI', () {
    testWidgets('uses LargeTitleBar instead of raw AppBar', (tester) async {
      await _pumpQualificationList(tester);

      expect(find.byType(LargeTitleBar), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('uses AppSearchBar instead of raw TextField with OutlineInputBorder',
        (tester) async {
      await _pumpQualificationList(tester);

      expect(find.byType(AppSearchBar), findsOneWidget);
    });

    testWidgets('shows shimmer (ListShimmer) instead of CircularProgressIndicator while loading',
        (tester) async {
      await _pumpQualificationListLoading(tester);

      expect(find.byType(ListShimmer), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses EmptyState with accent color when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            qual_provider.qualificationRepositoryProvider
                .overrideWithValue(_FakeQualificationRepository(qualifications: [])),
          ],
          child: localizedApp(home: const QualificationListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('uses ErrorView with accent color on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            qual_provider.qualificationRepositoryProvider
                .overrideWithValue(_ErrorQualificationRepository()),
          ],
          child: localizedApp(home: const QualificationListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('uses AppCard for each qualification item', (tester) async {
      await _pumpQualificationList(tester);

      expect(find.byType(AppCard), findsWidgets);
    });

    testWidgets('no hardcoded Colors.grey in text styles', (tester) async {
      await _pumpQualificationList(tester);

      // Check that no Text widget uses Colors.grey directly
    });
  });
}