import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/fee_detail_screen.dart';
import 'package:efe_mobile/features/fees/screens/fee_list_screen.dart';
import 'package:efe_mobile/features/fees/screens/widgets/fee_card.dart';
import 'package:efe_mobile/core/widgets/error_view.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/features/relations/providers/selected_child_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeParentAuthRepository implements AuthRepository {
  @override
  Future<UserModel> getCurrentUser() async => const UserModel(
        id: 'u-parent',
        name: 'María López',
        email: 'maria@test.com',
        role: 'parent',
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

const _ana = RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11);
const _bruno = RelationModel(id: 'r2', fullname: 'Bruno Pérez', role: 'student', userId: 12);

class _FakeRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination(
        data: const [_ana, _bruno],
        nextCursor: null,
        hasMore: false,
        total: 2,
      );
}

FeeModel _fee(String id, String studentId) => FeeModel(
      id: id,
      studentId: studentId,
      studentName: 'Ana Pérez',
      numberFee: 1,
      status: 'pending',
    );

class _FakeFeeRepository implements FeeRepository {
  final List<String?> scopeCalls = [];

  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    scopeCalls.add(studentId);
    if (studentId == null) {
      return CursorPagination.empty();
    }
    return CursorPagination(
      data: [_fee('f-$studentId', studentId)],
      nextCursor: null,
      hasMore: false,
      total: 1,
    );
  }

  @override
  Future<FeeModel> getFee(String id) => throw UnimplementedError();

  @override
  Future<PageResult<FeeModel>> getStudentFees(String studentAppId,
          {int page = 1, int limit = 20}) =>
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

class _ThrowingFeeRepository implements FeeRepository {
  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async {
    throw Exception('network error');
  }

  @override
  Future<FeeModel> getFee(String id) async => throw Exception('network error');

  @override
  Future<PageResult<FeeModel>> getStudentFees(String studentAppId,
          {int page = 1, int limit = 20}) =>
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

Future<ProviderContainer> _pumpFeeList(
  WidgetTester tester, {
  String? selected,
  _FakeFeeRepository? repository,
}) async {
  final repo = repository ?? _FakeFeeRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
      relationsRepositoryProvider.overrideWithValue(_FakeRelationsRepository()),
      feeRepositoryProvider.overrideWithValue(repo),
      if (selected != null)
        parentSelectedStudentProvider.overrideWith((ref) => selected),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('es', 'AR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeeListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('parent without selected child sees empty, not global fees',
      (tester) async {
    final repo = _FakeFeeRepository();
    await _pumpFeeList(tester, repository: repo);

    expect(find.byType(FeeCard), findsNothing);
    expect(find.text('No se encontraron cuotas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent with selected child sees only that child fees',
      (tester) async {
    final repo = _FakeFeeRepository();
    await _pumpFeeList(tester, selected: '11', repository: repo);

    expect(find.byType(FeeCard), findsOneWidget);
    expect(repo.scopeCalls.last, '11');
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching child reloads scoped fees', (tester) async {
    final repo = _FakeFeeRepository();
    await _pumpFeeList(tester, selected: '11', repository: repo);
    expect(repo.scopeCalls.last, '11');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Pérez').last);
    await tester.pumpAndSettle();

    expect(repo.scopeCalls.last, '12');
    expect(find.byType(FeeCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline fees show error with retry', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository()),
        relationsRepositoryProvider
            .overrideWithValue(_FakeRelationsRepository()),
        feeRepositoryProvider.overrideWithValue(_ThrowingFeeRepository()),
        parentSelectedStudentProvider.overrideWith((ref) => '11'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeeListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid fee id shows detail error with retry', (tester) async {
    final container = ProviderContainer(
      overrides: [
        feeRepositoryProvider.overrideWithValue(_ThrowingFeeRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeeDetailScreen(feeId: 'missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
