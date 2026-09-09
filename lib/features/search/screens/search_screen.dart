import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/empty_state.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          onSubmitted: (value) => ref.read(searchProvider.notifier).search(value),
          onChanged: (value) {
            if (value.isEmpty) {
              ref.read(searchProvider.notifier).clear();
            }
          },
        ),
        actions: [
          if (state.query.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                ref.read(searchProvider.notifier).clear();
              },
              icon: const Icon(PhosphorIconsRegular.x),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIconsRegular.warningCircle,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search failed',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : state.query.isEmpty
                  ? const EmptyState(
                      icon: PhosphorIconsRegular.magnifyingGlass,
                      title: 'Search',
                      subtitle: 'Search for students, classrooms, or news',
                    )
                  : state.results.isEmpty
                      ? EmptyState(
                          icon: PhosphorIconsRegular.magnifyingGlass,
                          title: 'No results',
                          subtitle: 'No results found for "${state.query}"',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.results.length,
                          itemBuilder: (context, index) {
                            final result = state.results[index];
                            return ListTile(
                              leading: _getTypeIcon(result.type),
                              title: Text(result.title),
                              subtitle: result.subtitle.isNotEmpty
                                  ? Text(
                                      result.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: result.route.isNotEmpty
                                  ? const Icon(PhosphorIconsRegular.caretRight, size: 16)
                                  : null,
                              onTap: result.route.isNotEmpty
                                  ? () => Navigator.pushNamed(context, result.route)
                                  : null,
                            );
                          },
                        ),
    );
  }

  Widget _getTypeIcon(String type) {
    IconData icon;
    Color? color;

    switch (type) {
      case 'student':
        icon = PhosphorIconsRegular.student;
        color = const Color(0xFF3B82F6);
        break;
      case 'classroom':
        icon = PhosphorIconsRegular.chalkboardTeacher;
        color = const Color(0xFF10B981);
        break;
      case 'news':
        icon = PhosphorIconsRegular.article;
        color = const Color(0xFFF59E0B);
        break;
      case 'event':
        icon = PhosphorIconsRegular.calendar;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = PhosphorIconsRegular.magnifyingGlass;
    }

    return CircleAvatar(
      backgroundColor: color?.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
