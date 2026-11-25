import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/request_model.dart';

class RequestTile extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onTap;

  const RequestTile({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final kindLabel = request.kind == RequestKind.student
        ? l10n.requestsKindStudent
        : l10n.requestsKindParent;
    final secondary =
        request.email.isNotEmpty ? request.email : request.identityNumber;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(
            name: request.fullname,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fullname.isNotEmpty ? request.fullname : kindLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$kindLabel · $secondary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
                if (request.kind == RequestKind.parent &&
                    request.childrenCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.requestsChildrenCount(request.childrenCount),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentFor(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (request.status.isNotEmpty)
            StatusBadge(
              status: request.status,
              label: studentStatusLabel(request.status, l10n),
            ),
        ],
      ),
    );
  }
}
