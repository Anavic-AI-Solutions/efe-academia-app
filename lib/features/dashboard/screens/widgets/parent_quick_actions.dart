import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';

/// Fila de acciones rápidas del home de padres: Cuotas, Boletín y Chat.
///
/// No decide la navegación: cada acción solo dispara el callback recibido.
class ParentQuickActions extends StatelessWidget {
  final VoidCallback onFees;
  final VoidCallback onBoletin;
  final VoidCallback onChat;

  const ParentQuickActions({
    super.key,
    required this.onFees,
    required this.onBoletin,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(label: l10n.feesTitle, onTap: onFees),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            label: l10n.parentActionBoletin,
            onTap: onBoletin,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(label: l10n.navChat, onTap: onChat),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.accentFor(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
