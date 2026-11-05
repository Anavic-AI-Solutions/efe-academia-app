import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/pagination/async_list_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../classrooms/domain/material_model.dart';
import '../../classrooms/screens/widgets/material_tile.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(libraryProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;
    final state = ref.read(libraryProvider);
    if (state.error != null) return;
    ref.read(libraryProvider.notifier).loadMore(search: _search);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _search = value;
      ref.read(libraryProvider.notifier).load(search: value);
      _scrollToTop();
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _openMaterial(MaterialModel material) async {
    final l10n = context.l10n;
    final url = material.publicUrl.trim();

    if (url.isEmpty) {
      _showMessage(l10n.libraryNoLink);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _showMessage(l10n.libraryOpenError);
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _showMessage(l10n.libraryOpenError);
    } catch (_) {
      _showMessage(l10n.libraryOpenError);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(l10n.libraryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.librarySearchHint,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody(state, l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(
      AsyncListState<MaterialModel> state, AppLocalizations l10n) {
    if (state.isLoading && state.data.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && state.data.isEmpty) {
      return ErrorView(
        message: l10n.libraryLoadError,
        detail: state.error,
        onRetry: () => ref
            .read(libraryProvider.notifier)
            .retry(search: _searchController.text),
      );
    }

    if (state.data.isEmpty) {
      final searching = _search.trim().isNotEmpty;
      return EmptyState(
        icon: PhosphorIconsRegular.bookOpen,
        title: l10n.libraryEmptyTitle,
        subtitle:
            searching ? l10n.libraryEmptySearch : l10n.libraryEmptySubtitle,
      );
    }

    final showFooter = state.isLoading || state.error != null;
    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).load(search: _search),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.data.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.data.length) {
            return _buildFooter(state, l10n);
          }
          final material = state.data[index];
          return MaterialTile(
            material: material,
            onOpenUrl: () => _openMaterial(material),
          );
        },
      ),
    );
  }

  Widget _buildFooter(
    AsyncListState<MaterialModel> state,
    AppLocalizations l10n,
  ) {
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(libraryProvider.notifier).retry(search: _search),
            icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
            label: Text(l10n.commonRetry),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(l10n.libraryLoadingMore),
        ],
      ),
    );
  }
}
