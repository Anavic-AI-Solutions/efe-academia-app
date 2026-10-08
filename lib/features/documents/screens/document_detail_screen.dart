import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../domain/document_model.dart';
import '../providers/document_provider.dart';

/// Detalle mínimo de documento (solo lectura): título, descripción,
/// fecha `d/m/Y` y botón Abrir/Descargar con apertura externa.
class DocumentDetailScreen extends ConsumerWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.documentsTitle),
          Expanded(
            child: documentAsync.when(
              loading: () => const ListShimmer(),
              error: (error, _) => ErrorView(
                message: l10n.documentsTitle,
                detail: error.toString(),
                onRetry: () =>
                    ref.invalidate(documentDetailProvider(documentId)),
              ),
              data: (document) => _DocumentDetailBody(document: document),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentDetailBody extends ConsumerWidget {
  final DocumentModel document;

  const _DocumentDetailBody({required this.document});

  Future<void> _openDocument(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final raw = document.mediaUrls.isNotEmpty
        ? document.mediaUrls.first
        : document.fileUrl;
    final url = raw.isNotEmpty
        ? raw
        : ref.read(documentApiProvider).downloadUrl(document.id);
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.documentsOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentFor(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhosphorIconsRegular.fileText,
                  color: AppColors.accentFor(isDark),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  document.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (document.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.calendar,
                  size: 13,
                  color: AppColors.mutedFor(isDark),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d/M/y').format(document.createdAt!),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
              ],
            ),
          ],
          if (document.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              document.description,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openDocument(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(PhosphorIconsRegular.downloadSimple, size: 20),
              label: Text(
                l10n.documentsOpen,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
