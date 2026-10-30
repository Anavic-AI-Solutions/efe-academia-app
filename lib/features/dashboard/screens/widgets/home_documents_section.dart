import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../documents/providers/document_provider.dart';
import '../../../documents/screens/widgets/document_tile.dart';

/// Documentos del home del profesor: últimos 5 con link a `/documents`.
class HomeDocumentsSection extends ConsumerWidget {
  const HomeDocumentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final documents = ref.watch(homeDocumentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeDocuments,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.push('/documents'),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 11),
        documents.when(
          loading: () => const Column(
            children: [
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
              SizedBox(height: 10),
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
            ],
          ),
          error: (error, _) => ErrorView(
            message: l10n.documentsTitle,
            detail: error.toString(),
            onRetry: () => ref.invalidate(homeDocumentsProvider),
          ),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: PhosphorIconsRegular.fileText,
                  title: l10n.documentsEmpty,
                )
              : Column(
                  children: [
                    // Tope de visualización: el provider ya recorta a 5,
                    // pero un override en tests puede traer más.
                    for (final document in items.take(5))
                      DocumentTile(
                        document: document,
                        onTap: () => context.push('/documents/${document.id}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
