import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/request_model.dart';

class RequestMediaSection extends StatelessWidget {
  final List<RequestMedia> media;

  const RequestMediaSection({super.key, required this.media});

  String _label(RequestMedia item, AppLocalizations l10n) {
    switch (item.collectionName) {
      case 'front_dni':
        return l10n.requestsDocumentFrontDni;
      case 'selfie':
        return l10n.requestsDocumentSelfie;
      default:
        return item.fileName.isNotEmpty
            ? item.fileName
            : l10n.requestsDocumentOther;
    }
  }

  Future<void> _open(BuildContext context, RequestMedia item) async {
    final uri = Uri.tryParse(item.url);
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
        SnackBar(content: Text(context.l10n.requestsOpenDocumentError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.requestsSectionDocuments,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        if (media.isEmpty)
          Text(
            l10n.requestsNoDocuments,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.mutedFor(isDark),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var index = 0; index < media.length; index++)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      PhosphorIconsRegular.fileText,
                      color: AppColors.accentFor(isDark),
                      size: 20,
                    ),
                    title: Text(
                      _label(media[index], l10n),
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: media[index].fileName.isNotEmpty
                        ? Text(
                            media[index].fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Icon(
                      PhosphorIconsRegular.arrowSquareOut,
                      size: 18,
                      color: AppColors.accentFor(isDark),
                    ),
                    onTap: () => _open(context, media[index]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
