import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class LargeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  /// Debajo de este ancho de contenido las acciones con texto se reemplazan
  /// por [compactActions] para que el header no desborde en teléfonos.
  static const double compactBreakpoint = 480;

  final String title;
  final List<Widget>? actions;

  /// Alternativa con íconos para pantallas angostas. Si es null se usan
  /// siempre las [actions].
  final List<Widget>? compactActions;
  final Widget? bottom;
  final bool showBackButton;
  final Color? backgroundColor;

  const LargeTitleBar({
    super.key,
    required this.title,
    this.actions,
    this.compactActions,
    this.bottom,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom != null ? 60 : 0) + 8,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: backgroundColor == null
              ? (isDark
                  ? AppColors.primaryGradientDark
                  : AppColors.primaryGradient)
              : null,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < compactBreakpoint;
                  final effectiveActions = compact && compactActions != null
                      ? compactActions
                      : actions;

                  return Row(
                    children: [
                      if (showBackButton)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              context.go('/dashboard');
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      if (showBackButton) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 20 : null,
                          ),
                        ),
                      ),
                      if (effectiveActions != null) ...effectiveActions,
                    ],
                  );
                },
              ),
            ),
            if (bottom != null) bottom!,
            if (bottom != null) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
