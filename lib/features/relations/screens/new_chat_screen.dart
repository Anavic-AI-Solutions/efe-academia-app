import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../chat/providers/chat_provider.dart';
import '../domain/relation_model.dart';
import '../providers/relations_provider.dart';

/// New chat screen: lists linked people and starts a private conversation.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  static const _debounceDuration = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounce;
  int? _creatingUserId;
  String? _createError;
  bool _createFailed = false;
  RelationModel? _lastTapped;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      ref.read(relationsProvider.notifier).setQuery(value.trim());
    });
  }

  Future<void> _startChat(RelationModel relation) async {
    // Single-flight: ignore taps while a POST is already resolving.
    if (_creatingUserId != null) return;
    setState(() {
      _creatingUserId = relation.userId;
      _lastTapped = relation;
      _createError = null;
      _createFailed = false;
    });
    try {
      final response = await ref
          .read(chatApiProvider)
          .createPrivateChat(withUserId: relation.userId);
      final chatId = _chatIdFrom(response);
      if (!mounted) return;
      setState(() => _creatingUserId = null);
      if (chatId.isEmpty) {
        setState(() => _createFailed = true);
        return;
      }
      context.push(
        '/chat/$chatId?name=${Uri.encodeComponent(relation.fullname)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingUserId = null;
        _createError = e.toString();
      });
    }
  }

  String _chatIdFrom(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic> && nested['id'] != null) {
        return nested['id'].toString();
      }
      if (data['id'] != null) return data['id'].toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(relationsProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.chatNewTitle,
            onBack: () => Navigator.maybePop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppSearchBar(
              controller: _searchController,
              hintText: l10n.chatNewSearchHint,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(child: _buildBody(state, l10n, isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(RelationsState state, AppLocalizations l10n, bool isDark) {
    if (_createFailed || _createError != null) {
      return ErrorView(
        message: l10n.chatLoadError,
        detail: _createError,
        retryLabel: l10n.chatRetry,
        onRetry: _lastTapped == null ? null : () => _startChat(_lastTapped!),
      );
    }

    final relations = state.relations;

    if (state.isLoading && relations.isEmpty) {
      return const ListShimmer();
    }

    if (state.error != null && relations.isEmpty) {
      return ErrorView(
        message: l10n.chatLoadError,
        detail: state.error,
        retryLabel: l10n.chatRetry,
        onRetry: () => ref.read(relationsProvider.notifier).refresh(),
      );
    }

    if (relations.isEmpty) {
      if (state.query.isNotEmpty) {
        return EmptyState(
          icon: PhosphorIconsRegular.magnifyingGlass,
          title: l10n.chatNewNoResults(state.query),
        );
      }
      return EmptyState(
        icon: PhosphorIconsRegular.users,
        title: l10n.chatNewEmptyTitle,
        subtitle: l10n.chatNewEmptySubtitle,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: relations.length,
      itemBuilder: (context, index) {
        final relation = relations[index];
        return _RelationTile(
          relation: relation,
          isCreating: _creatingUserId == relation.userId,
          onCreate: () => _startChat(relation),
        );
      },
    );
  }
}

class _RelationTile extends StatelessWidget {
  final RelationModel relation;
  final bool isCreating;
  final VoidCallback onCreate;

  const _RelationTile({
    required this.relation,
    required this.isCreating,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: isCreating ? null : onCreate,
      child: Row(
        children: [
          AppAvatar(name: relation.fullname, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relation.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                _RoleChip(role: relation.role),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCreating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              l10n.chatNewStart,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentFor(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final label = switch (role) {
      'student' => l10n.relationRoleStudent,
      'professor' => l10n.relationRoleProfessor,
      'parent' => l10n.relationRoleParent,
      'admin' => l10n.relationRoleAdmin,
      _ => role,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.chipFor(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.inkFor(isDark),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
