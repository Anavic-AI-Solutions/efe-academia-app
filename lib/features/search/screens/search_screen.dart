import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Search State
// ---------------------------------------------------------------------------

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String route;

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.type = '',
    this.route = '',
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? json['description'] ?? '',
      type: json['type'] ?? '',
      route: json['route'] ?? '',
    );
  }
}

class SearchState {
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    String? query,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiClient _api;

  SearchNotifier(this._api) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], query: '');
      return;
    }

    state = state.copyWith(isLoading: true, query: query, clearError: true);
    try {
      final response = await _api.get('/search', queryParameters: {'q': query});
      final data = response.data;
      final items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : data as List<dynamic>? ?? [];
      final results = items
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Search Screen
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.searchTitle,
            bottom: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppSearchBar(
                controller: _controller,
                hintText: l10n.searchHint,
                onChanged: (value) {
                  if (value.isEmpty) {
                    ref.read(searchProvider.notifier).clear();
                  }
                },
                suffix: state.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const ListShimmer()
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.warningCircle,
                                size: 32,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.searchErrorTitle,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : state.query.isEmpty
                        ? EmptyState(
                            icon: PhosphorIconsRegular.magnifyingGlass,
                            title: l10n.searchTitle,
                            subtitle: l10n.searchEmptySubtitle,
                          )
                        : state.results.isEmpty
                            ? EmptyState(
                                icon: PhosphorIconsRegular.magnifyingGlass,
                                title: l10n.searchNoResultsTitle,
                                subtitle:
                                    l10n.searchNoResultsSubtitle(state.query),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                itemCount: state.results.length,
                                itemBuilder: (context, index) {
                                  final result = state.results[index];
                                  return _SearchTile(
                                    result: result,
                                    isDark: isDark,
                                    onTap: result.route.isNotEmpty
                                        ? () => Navigator.pushNamed(
                                            context, result.route)
                                        : null,
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  final VoidCallback? onTap;

  const _SearchTile({
    required this.result,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(),
              color: _getTypeColor(),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (result.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (result.route.isNotEmpty)
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (result.type) {
      case 'student':
        return const Color(0xFF3B82F6);
      case 'classroom':
        return const Color(0xFF10B981);
      case 'news':
        return const Color(0xFFF59E0B);
      case 'event':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (result.type) {
      case 'student':
        return PhosphorIconsRegular.student;
      case 'classroom':
        return PhosphorIconsRegular.chalkboardTeacher;
      case 'news':
        return PhosphorIconsRegular.article;
      case 'event':
        return PhosphorIconsRegular.calendar;
      default:
        return PhosphorIconsRegular.magnifyingGlass;
    }
  }
}
