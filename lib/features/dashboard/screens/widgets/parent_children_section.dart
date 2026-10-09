import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../relations/domain/relation_model.dart';
import '../../../relations/providers/relations_provider.dart';

class ParentChildrenSection extends ConsumerWidget {
  final ValueChanged<RelationModel> onSelect;

  const ParentChildrenSection({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(relationsProvider);
    final children = state.relations
        .where((r) => r.role == 'student')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.studentsTitle, padding: EdgeInsets.zero),
        const SizedBox(height: 11),
        if (state.isLoading && children.isEmpty)
          const Column(
            children: [
              LoadingShimmer(
                  width: double.infinity, height: 64, borderRadius: 14),
              SizedBox(height: 11),
              LoadingShimmer(
                  width: double.infinity, height: 64, borderRadius: 14),
            ],
          )
        else if (state.error != null && children.isEmpty)
          ErrorView(
            message: l10n.studentsLoadError,
            detail: state.error,
            onRetry: () => ref.read(relationsProvider.notifier).refresh(),
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
              child: _ChildCard(
                child: child,
                onTap: () => onSelect(child),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  final RelationModel child;
  final VoidCallback onTap;

  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              child.fullname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightInk,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
