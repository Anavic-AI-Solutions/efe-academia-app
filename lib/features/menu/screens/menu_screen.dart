import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../features/menu/domain/menu_entry.dart';
import '../../../l10n/l10n.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _selectedIndex = 0;
  late final List<MenuEntry> _entries;
  late final Map<String, Widget Function(BuildContext)> _routeBuilders;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    final role = ref.watch(authProvider).user?.role ?? 'student';
    _entries = MenuEntry.forRole(role);
    _routeBuilders = {
      '/menu': _buildMenuPage,
      '/history': _buildHistoryPage,
      '/library': _buildLibraryPage,
      '/faqs': _buildFaqPage,
      '/statistics': _buildStatisticsPage,
    };
  }

  Widget _buildMenuPage(BuildContext context) {
    return _MenuPage(
      entries: _entries.where((e) => e.route == '/menu').toList(),
      onSelect: (entry) => context.pop(),
    );
  }

  Widget _buildHistoryPage(BuildContext context) {
    return _MenuPage(
      entries: _entries.where((e) => e.route == '/history').toList(),
      onSelect: (entry) => context.pop(),
    );
  }

  Widget _buildLibraryPage(BuildContext context) {
    return _MenuPage(
      entries: _entries.where((e) => e.route == '/library').toList(),
      onSelect: (entry) => context.pop(),
    );
  }

  Widget _buildFaqPage(BuildContext context) {
    return _MenuPage(
      entries: _entries.where((e) => e.route == '/faqs').toList(),
      onSelect: (entry) => context.pop(),
    );
  }

  Widget _buildStatisticsPage(BuildContext context) {
    return _MenuPage(
      entries: _entries.where((e) => e.route == '/statistics').toList(),
      onSelect: (entry) => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldWithNav(
      navigationShell: StateNavigationShell(
        branches: [
          // Home branch (dashboard) - index 0
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Classes branch - index 1 (parent sees Pagos instead of Aulas)
          StatefulShellBranch(
            initialLocation: _navIndex == 1 ? 1 : null,
            routes: [
              GoRoute(
                path: '/classrooms',
                builder: (context, state) => const ClassroomListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ClassroomDetailScreen(
                      classroomId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'attendance',
                        builder: (context, state) => AttendanceScreen(
                          classroomId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'grades',
                        builder: (context, state) => ClassroomGradesScreen(
                          classroomId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/payments',
                builder: (context, state) => const ParentFeesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ParentFeeDetailScreen(
                      feeId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'invoice',
                        builder: (context, state) => InvoiceViewerScreen(
                          feeId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Chat branch - index 2
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const NewChatScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ChatDetailScreen(
                      chatId: state.pathParameters['id']!,
                      chatName: state.uri.queryParameters['name'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Profile branch - index 3
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          // Menu branch - index 4 (new fifth item)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                builder: (context, state) => const MenuScreen(),
                routes: const [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => HistoryScreen(),
                  ),
                  GoRoute(
                    path: 'library',
                    builder: (context, state) => LibraryScreen(),
                  ),
                  GoRoute(
                    path: 'faqs',
                    builder: (context, state) => FaqScreen(),
                  ),
                  GoRoute(
                    path: 'statistics',
                    builder: (context, state) => StatisticsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
        selectedIndex: _navIndex,
        onDestinationSelected: (index) {
          setState(() => _navIndex = index);
        },
      ),
    );
  }
}

class _MenuPage extends ConsumerWidget {
  final List<MenuEntry> entries;
  final VoidCallback onSelect;

  const _MenuPage({
    required this.entries,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (entries.isEmpty) {
      return EmptyState(
        icon: PhosphorIconsRegular.grid,
        title: l10n.noData,
        subtitle: l10n.noDataSubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _MenuTile(entry: entry);
      },
    );
  }
}

class _MenuTile extends ConsumerWidget {
  final MenuEntry entry;

  const _MenuTile({
    required this.entry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkText : AppColors.lightText;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate based on route
          if (entry.route != '/menu' &&
              entry.route != '/history' &&
              entry.route != '/library' &&
              entry.route != '/faqs' &&
              entry.route != '/statistics') {
            context.push(entry.route);
          } else {
            context.pop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.3)
                      : AppColors.lightSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  entry.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                PhosphorIconsRegular.chevronRight,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}