import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'pill_button.dart';

/// Full screen scaffold shared by the people create/edit forms.
///
/// It only renders chrome: the title bar, the scrollable fields, the error
/// banner and the bottom save button. Validation and requests stay in the
/// caller. The scaffold resizes itself when the keyboard opens so the save
/// button stays reachable while typing.
class EntityFormScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String saveLabel;
  final VoidCallback? onSave;
  final bool isSaving;
  final String? error;

  const EntityFormScreen({
    super.key,
    required this.title,
    required this.children,
    required this.saveLabel,
    this.onSave,
    this.isSaving = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const ValueKey('entity-form-fields'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: children,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      Container(
                        key: const ValueKey('entity-form-error'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    PillButton(
                      key: const ValueKey('entity-form-save'),
                      label: saveLabel,
                      isLoading: isSaving,
                      onPressed: onSave,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
