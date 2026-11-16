import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/search_bar.dart';
import '../../../../l10n/l10n.dart';
import '../../providers/request_provider.dart';

class ClassroomPickerSheet extends ConsumerStatefulWidget {
  const ClassroomPickerSheet({super.key});

  @override
  ConsumerState<ClassroomPickerSheet> createState() =>
      _ClassroomPickerSheetState();
}

class _ClassroomPickerSheetState extends ConsumerState<ClassroomPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final sheetHeight = math.min(520.0, availableHeight * 0.85);
    final options = ref.watch(requestClassroomOptionsProvider(_search));
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Material(
              color: surface,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Material(
                    color: surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.requestsClassroomPickerTitle,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: AppSearchBar(
                        controller: _searchController,
                        hintText: l10n.requestsClassroomPickerSearch,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: options.when(
                        loading: () =>
                            const ListShimmer(itemCount: 4, itemHeight: 52),
                        error: (error, _) => _ErrorState(
                          message: l10n.requestsClassroomPickerLoadError,
                          retryLabel: l10n.commonRetry,
                          onRetry: () => ref.invalidate(
                            requestClassroomOptionsProvider(_search),
                          ),
                        ),
                        data: (classrooms) {
                          if (classrooms.isEmpty) {
                            return _EmptyState(
                              message: l10n.requestsClassroomPickerEmpty,
                            );
                          }

                          return ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: classrooms.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final classroom = classrooms[index];
                              return ListTile(
                                tileColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  PhosphorIconsRegular.chalkboardTeacher,
                                  color: AppColors.accentFor(isDark),
                                ),
                                title: Text(
                                  classroom.name,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                subtitle: classroom.branch.isNotEmpty
                                    ? Text(classroom.branch)
                                    : null,
                                onTap: () =>
                                    Navigator.of(context).pop(classroom),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.mutedFor(isDark),
        ),
      ),
    );
  }
}
