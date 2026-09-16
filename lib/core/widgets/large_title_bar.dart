import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class LargeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBackButton;
  final Color? backgroundColor;

  const LargeTitleBar({
    super.key,
    required this.title,
    this.actions,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.lightBackground);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Container(
        color: bgColor,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: 20,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
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
                  if (showBackButton)
                    const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
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
