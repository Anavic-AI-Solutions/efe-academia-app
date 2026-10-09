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
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/features/news/data/news_repository.dart';
import 'package:efe_mobile/features/news/domain/news_model.dart';
import 'package:efe_mobile/features/news/providers/news_provider.dart';
import 'package:efe_mobile/features/relations/data/relations_repository.dart';
import 'package:efe_mobile/features/relations/domain/relation_model.dart';
import 'package:efe_mobile/features/relations/providers/relations_provider.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:efe_mobile/features/notifications/providers/notification_provider.dart';
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

Future<void> _pumpApp(WidgetTester tester, String role) async {
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

  testWidgets('bottom nav shows the 4 destinations with visible labels',
      (tester) async {
    await _pumpApp(tester, 'student');

    expect(navLabel('Inicio'), findsOneWidget);
    expect(navLabel('Aulas'), findsOneWidget);
    expect(navLabel('Chat'), findsOneWidget);
    expect(navLabel('Perfil'), findsOneWidget);

    // The old center search button is gone.
    expect(find.byIcon(PhosphorIconsFill.magnifyingGlass), findsNothing);
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
      expect((inactivePill.decoration as BoxDecoration).color,
          Colors.transparent,
          reason: 'role $role');
    });
  }
}
