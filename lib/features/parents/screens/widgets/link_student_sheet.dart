import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/search_bar.dart';
import '../../../../l10n/l10n.dart';
import '../../../students/domain/student_model.dart';
import '../../../students/providers/student_provider.dart';
import '../../providers/parent_provider.dart';

/// Sheet para vincular un alumno a un padre.
///
/// Busca alumnos contra `studentRepository.getStudents` (página 1, 20
/// resultados) con debounce, y devuelve `true` al vincular uno. La pantalla de
/// detalle es la que invalida los providers y muestra el snackbar de éxito.
class LinkStudentSheet extends ConsumerStatefulWidget {
  final String parentId;

  const LinkStudentSheet({super.key, required this.parentId});

  @override
  ConsumerState<LinkStudentSheet> createState() => _LinkStudentSheetState();
}

class _LinkStudentSheetState extends ConsumerState<LinkStudentSheet> {
  static const _searchDebounce = Duration(milliseconds: 300);
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  List<StudentModel> _students = const [];
  String? _error;
  bool _isLoading = true;
  String? _linkingId;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      _search = value;
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(studentRepositoryProvider).getStudents(
            search: _search.isEmpty ? null : _search,
            page: 1,
            limit: _pageSize,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _students = result.data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _link(StudentModel student) async {
    if (_linkingId != null) return;

    setState(() => _linkingId = student.id);

    try {
      await ref.read(parentRepositoryProvider).linkStudent(
            widget.parentId,
            student.id,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _linkingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.parentsLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final sheetHeight = math.min(520.0, availableHeight * 0.85);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: sheetHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: surface,
            child: Container(
              key: const Key('link-student-sheet'),
              child: SafeArea(
                top: false,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 8, 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.parentsLinkStudentTitle,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('link-student-close'),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: AppSearchBar(
                        key: const Key('link-student-search'),
                        controller: _searchController,
                        hintText: l10n.parentsLinkStudentSearch,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    Expanded(child: _buildResults(context, isDark)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isDark) {
    final l10n = context.l10n;

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.studentsLoadError,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadStudents,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const ListShimmer(itemCount: 4, itemHeight: 48);
    }

    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.studentsEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mutedFor(isDark),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = _students[index];
        final isLinking = _linkingId == student.id;
        return ListTile(
          key: Key('link-student-${student.id}'),
          onTap: _linkingId == null ? () => _link(student) : null,
          tileColor:
              isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: AppAvatar(name: student.fullname, size: 40),
          title: Text(
            student.fullname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: student.year.isEmpty
              ? null
              : Text(
                  student.year,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
          trailing: isLinking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  PhosphorIconsRegular.plus,
                  size: 18,
                  color: AppColors.accentFor(isDark),
                ),
        );
      },
    );
  }
}
