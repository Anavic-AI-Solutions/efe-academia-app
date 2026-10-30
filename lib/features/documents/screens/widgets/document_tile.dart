import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/document_model.dart';

/// Tile compacto de documento: ícono file, título y fecha `d/m/Y`.
/// Sin botón de apertura cuando no hay `mediaUrls` ni `fileUrl`.
class DocumentTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const DocumentTile({
    super.key,
    required this.document,
    required this.onTap,
  });

  bool get _hasFile =>
      document.mediaUrls.isNotEmpty || document.fileUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentFor(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsRegular.fileText,
              color: AppColors.accentFor(isDark),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (document.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('d/M/y').format(document.createdAt!),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_hasFile)
            IconButton(
              onPressed: onTap,
              icon: Icon(
                PhosphorIconsRegular.arrowSquareOut,
                size: 20,
                color: AppColors.accentFor(isDark),
              ),
            ),
        ],
      ),
    );
  }
}
