import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/material_model.dart';

class MaterialTile extends StatelessWidget {
  final MaterialModel material;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenUrl;

  const MaterialTile({
    super.key,
    required this.material,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final accent = AppColors.accentFor(isDark);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(material.type), color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (material.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    material.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (material.category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          material.category,
                          style: AppTypography.labelSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (material.visibility == 'specific') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.materialsStudentCount(
                            material.studentIds.length,
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      PhosphorIconsRegular.downloadSimple,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.classroomsMaterialDownloads(material.downloadCount),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onOpenUrl != null) ...[
            IconButton(
              icon: Icon(
                PhosphorIconsRegular.openInNew,
                size: 18,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              tooltip: l10n.open,
              onPressed: onOpenUrl,
            ),
          ],
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              tooltip: l10n.materialsEdit,
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.materialsEdit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.materialsDelete),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return PhosphorIconsRegular.filePdf;
      case 'video':
        return PhosphorIconsRegular.videoCamera;
      case 'image':
      case 'imagen':
        return PhosphorIconsRegular.image;
      case 'audio':
        return PhosphorIconsRegular.musicNotes;
      case 'link':
        return PhosphorIconsRegular.link;
      default:
        return PhosphorIconsRegular.fileText;
    }
  }
}