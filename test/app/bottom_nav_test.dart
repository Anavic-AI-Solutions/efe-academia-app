import 'package:efe_mobile/app/router.dart';
import 'package:efe_mobile/app/theme/app_colors.dart';
import 'package:efe_mobile/features/auth/data/auth_repository.dart';
import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:efe_mobile/features/auth/providers/auth_provider.dart';
import 'package:efe_mobile/features/birthdays/domain/birthday_model.dart';
import 'package:efe_mobile/features/birthdays/providers/birthday_provider.dart';
import 'package:efe_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:efe_mobile/features/dashboard/domain/dashboard_data.dart';
import 'package:efe_mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:efe_mobile/features/documents/domain/document_model.dart';
import 'package:efe_mobile/features/documents/providers/document_provider.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:efe_mobile/features/events/providers/event_provider.dart';
import 'package:efe_mobile/features/fees/data/fee_repository.dart';
import 'package:efe_mobile/features/fees/domain/fee_model.dart';
import 'package:efe_mobile/features/fees/providers/fee_provider.dart';
import 'package:efe_mobile/features/fees/screens/parent_fee_detail_screen.dart';
import 'package:efe_mobile/features/fees/screens/parent_fees_screen.dart';
import 'package:efe_mobile/features/fees/screens/widgets/parent_fee_card.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
import 'package:efe_mobile/features/menu/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  final String role;

  _FakeAuthRepository(this.role);

  @override
  Future<UserModel> getCurrentUser() async => UserModel(
        id: '1',
        name: 'Profe Test',
        email: 'profe@test.com',
        role: role,
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

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboard() async => const DashboardData();
}

/// Keeps the professor home news section off the real API in tests.
class _FakeNewsRepository implements NewsRepository {
  @override
  Future<CursorPagination<NewsModel>> getNews({String? cursor}) async =>
      CursorPagination.empty();
}

/// Keeps the parent home children section off the real API in tests.
class _FakeEmptyRelationsRepository implements RelationsRepository {
  @override
  Future<CursorPagination<RelationModel>> getRelations({
    String? query,
    String? cursor,
  }) async =>
      CursorPagination.empty();
}

/// Cuota de prueba que devuelven la lista y el detalle falsos.
const _testFee = FeeModel(
  id: 'f1',
  studentName: 'Ana Pérez',
  month: '7',
  year: '2026',
  toPay: 25000,
  total: 25000,
  status: 'pending',
);

/// Keeps the fee list tab off the real API in tests.
class _FakeFeeRepository implements FeeRepository {
  @override
  Future<CursorPagination<FeeModel>> getFees({
    String? studentId,
    String? search,
    String? cursor,
  }) async =>
      CursorPagination(data: [_testFee], hasMore: false, total: 1);

  @override
  Future<FeeModel> getFee(String id) async => _testFee;

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

  @override
  Future<Never> getInvoiceFile(String feeId) => throw UnimplementedError();
}

Future<void> _pumpApp(WidgetTester tester, String role) async {
  final feeRepository = _FakeFeeRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(role)),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      relationsRepositoryProvider
          .overrideWithValue(_FakeEmptyRelationsRepository()),
      // El calendario y los documentos del home no tocan red en estos tests.
      homeCalendarProvider.overrideWith((ref) async => <EventModel>[]),
      homeDocumentsProvider.overrideWith((ref) async => <DocumentModel>[]),
      todayBirthdaysProvider.overrideWith((ref) async => <BirthdayModel>[]),
      newsListProvider
          .overrideWith((ref) => NewsListNotifier(_FakeNewsRepository())),
      unreadCountProvider.overrideWith((ref) async => 0),
      // La pestaña Pagos (lista y detalle) no toca red en estos tests.
      feeRepositoryProvider.overrideWithValue(feeRepository),
      feeListProvider.overrideWith((ref) => FeeListNotifier(feeRepository)),
      parentFeesProvider.overrideWith((ref) => FeeListNotifier(feeRepository)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(routerProvider),
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  Finder navLabel(String text) => find.descendant(
        of: find.byType(CustomBottomNav),
        matching: find.text(text),
      );

  testWidgets('bottom nav shows the 5 destinations with visible labels',
      (tester) async {
    await _pumpApp(tester, 'student');

    expect(navLabel('Inicio'), findsOneWidget);
    expect(navLabel('Aulas'), findsOneWidget);
    expect(navLabel('Chat'), findsOneWidget);
    expect(navLabel('Perfil'), findsOneWidget);
    expect(navLabel('Menú'), findsOneWidget);

    // The old center search button is gone.
    expect(find.byIcon(PhosphorIconsFill.magnifyingGlass), findsNothing);
  });

  testWidgets('menu destination opens the menu screen', (tester) async {
    await _pumpApp(tester, 'student');

    await tester.tap(navLabel('Menú'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Académico'), findsOneWidget);
    expect(find.text('Calendario'), findsOneWidget);
  });

  testWidgets('parent nav shows Pagos and opens the parent fees screen',
      (tester) async {
    await _pumpApp(tester, 'parent');
    expect(navLabel('Pagos'), findsOneWidget);
    expect(navLabel('Aulas'), findsNothing);
    await tester.tap(navLabel('Pagos'));
    await tester.pumpAndSettle();
    expect(find.byType(ParentFeesScreen), findsOneWidget);
  });

  testWidgets('parent home Cuotas action switches to the Pagos tab',
      (tester) async {
    await _pumpApp(tester, 'parent');

    await tester.tap(find.text('Cuotas'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentFeesScreen), findsOneWidget);

    final activePill = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: navLabel('Pagos'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = activePill.decoration as BoxDecoration;
    expect(decoration.color, AppColors.primary,
        reason:
            'la accion Cuotas debe cambiar de pestana, no apilar la pagina');
  });

  testWidgets('parent opens fee detail from Pagos and keeps the tab',
      (tester) async {
    await _pumpApp(tester, 'parent');
    await tester.tap(navLabel('Pagos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ParentFeeCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ParentFeeDetailScreen), findsOneWidget);
    // el pill activo sigue en 'Pagos'
    final pill = tester.widget<AnimatedContainer>(find.ancestor(
        of: navLabel('Pagos'), matching: find.byType(AnimatedContainer)));
    expect((pill.decoration as BoxDecoration).color, AppColors.primary);
  });

  testWidgets('professor nav keeps Aulas', (tester) async {
    await _pumpApp(tester, 'professor');
    expect(navLabel('Aulas'), findsOneWidget);
    expect(navLabel('Pagos'), findsNothing);
  });

  for (final role in ['parent', 'professor']) {
    testWidgets('active destination uses the accent pill ($role)',
        (tester) async {
      await _pumpApp(tester, role);

      final activePill = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: navLabel('Inicio'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = activePill.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary, reason: 'role $role');

      final inactivePill = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: navLabel('Chat'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
          (inactivePill.decoration as BoxDecoration).color, Colors.transparent,
          reason: 'role $role');
    });
  }
}
