import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/home_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../relations/domain/relation_model.dart';
import '../../relations/providers/relations_provider.dart';
import '../domain/dashboard_data.dart';
import '../domain/parent_home_data.dart';
import '../providers/dashboard_provider.dart';
import '../../documents/providers/document_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../news/providers/news_provider.dart';
import 'widgets/parent_child_card.dart';
import 'widgets/parent_overdue_fees_card.dart';
import 'widgets/parent_quick_actions.dart';
import 'widgets/parent_summary_sections.dart';

/// Home del rol padre: alerta de mora, hijos con promedio/asistencia y
/// acciones rápidas (Cuotas, Boletín, Chat).
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    if (dashboardState.isLoading && dashboardState.data == null) {
      return _buildLoading(isDark);
    }

    if (dashboardState.error != null && dashboardState.data == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundFor(isDark),
        body: SafeArea(
          child: ErrorView(
            message: l10n.dashboardLoadError,
            detail: dashboardState.error,
            onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
        ),
      );
    }

    return _buildContent(context, ref, dashboardState.data, user, isDark);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DashboardData? data,
    UserModel? user,
    bool isDark,
  ) {
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final l10n = context.l10n;
    final parentHome = data?.parentHome ?? const ParentHomeData();
    final relationsState = ref.watch(relationsProvider);
    final children =
        relationsState.relations.where((r) => r.role == 'student').toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeDocumentsProvider);
          ref.invalidate(homeCalendarProvider);
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(),
            ref.read(relationsProvider.notifier).refresh(),
            ref.read(newsListProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            HomeHeader(
              name: user?.name ?? '',
              greeting: l10n.parentGreeting,
              title: _familyTitle(user?.name ?? '', l10n),
              avatarUrl: user?.avatarUrl,
              unreadCount: unreadCount,
              onNotifications: () => context.push('/notifications'),
              onSearch: null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parentHome.overdueFeesCount > 0) ...[
                    ParentOverdueFeesCard(
                      count: parentHome.overdueFeesCount,
                      total: parentHome.moraTotal,
                      onPay: () => context.go('/payments'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (relationsState.isLoading && children.isEmpty)
                    const Column(
                      children: [
                        LoadingShimmer(
                          width: double.infinity,
                          height: 108,
                          borderRadius: 16,
                        ),
                        SizedBox(height: 11),
                        LoadingShimmer(
                          width: double.infinity,
                          height: 108,
                          borderRadius: 16,
                        ),
                      ],
                    )
                  else if (relationsState.error != null && children.isEmpty)
                    ErrorView(
                      message: l10n.studentsLoadError,
                      detail: relationsState.error,
                      onRetry: () =>
                          ref.read(relationsProvider.notifier).refresh(),
                    )
                  else if (children.isEmpty)
                    EmptyState(
                      icon: PhosphorIconsRegular.users,
                      title: l10n.studentsEmptyTitle,
                    )
                  else
                    ...children.map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: ParentChildCard(
                          name: child.fullname,
                          summary: _summaryFor(
                            parentHome.children,
                            child.userId,
                          ),
                          onTap: () => context.push(
                            '/students/${_studentRouteId(child, parentHome)}',
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  ParentQuickActions(
                    onFees: () => context.go('/payments'),
                    onBoletin: () =>
                        _openBoletin(context, children, parentHome),
                    onChat: () => context.go('/chat'),
                  ),
                  const SizedBox(height: 8),
                  const ParentSummarySections(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: ListView(
        padding: EdgeInsets.zero,
        children: const [
          GradientHeader(
            child: Row(
              children: [
                LoadingShimmer(width: 48, height: 48, borderRadius: 24),
                SizedBox(width: 14),
                LoadingShimmer(width: 140, height: 16),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                LoadingShimmer(
                  width: double.infinity,
                  height: 60,
                  borderRadius: 14,
                ),
                SizedBox(height: 14),
                LoadingShimmer(
                  width: double.infinity,
                  height: 108,
                  borderRadius: 16,
                ),
                SizedBox(height: 11),
                LoadingShimmer(
                  width: double.infinity,
                  height: 108,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Título del header: "Familia <apellido>" para nombres compuestos.
  String _familyTitle(String name, AppLocalizations l10n) {
    final tokens = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return l10n.commonUser;
    if (tokens.length == 1) return tokens.first;
    return l10n.parentFamilyTitle(tokens.last);
  }

  ParentChildSummary? _summaryFor(
    List<ParentChildSummary> children,
    int userId,
  ) {
    for (final child in children) {
      if (child.userId == userId) return child;
    }
    return null;
  }

  /// `student_id` del resumen si está presente; si no, el `user_id`
  /// (degradación para backends viejos).
  String _studentRouteId(RelationModel child, ParentHomeData? parentHome) {
    final summary = _summaryFor(
      parentHome?.children ?? const [],
      child.userId,
    );
    final studentId = summary?.studentId ?? '';
    return studentId.isNotEmpty ? studentId : child.userId.toString();
  }

  Future<void> _openBoletin(
    BuildContext context,
    List<RelationModel> children,
    ParentHomeData parentHome,
  ) async {
    if (children.isEmpty) return;

    if (children.length == 1) {
      context.push(
        '/students/${_studentRouteId(children.first, parentHome)}/boletin',
      );
      return;
    }

    final selected = await showModalBottomSheet<RelationModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildPickerSheet(children: children),
    );
    if (selected == null || !context.mounted) return;
    context.push('/students/${_studentRouteId(selected, parentHome)}/boletin');
  }
}

/// Hoja de selección de hijo para abrir el boletín.
class _ChildPickerSheet extends StatelessWidget {
  final List<RelationModel> children;

  const _ChildPickerSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.parentChooseChild,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final child in children)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(child),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                AppAvatar(name: child.fullname, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    child.fullname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  PhosphorIconsRegular.caretRight,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
