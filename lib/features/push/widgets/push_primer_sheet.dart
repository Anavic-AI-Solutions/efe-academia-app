import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/l10n.dart';

/// Contenido del bottom-sheet que invita a activar las notificaciones.
///
/// No se muestra a sí mismo: el coordinador lo presenta con
/// `showModalBottomSheet` y mapea el resultado a [onResult].
class PushPrimerSheet extends StatelessWidget {
  const PushPrimerSheet({super.key, required this.onResult});

  final void Function(bool activated) onResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsRegular.bell,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pushPrimerTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pushPrimerBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            PillButton(
              label: l10n.pushPrimerActivate,
              onPressed: () => onResult(true),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => onResult(false),
              child: Text(l10n.pushPrimerLater),
            ),
          ],
        ),
      ),
    );
  }
}
