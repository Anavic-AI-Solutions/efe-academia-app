import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../classrooms/domain/classroom_model.dart';
import '../domain/request_model.dart';
import '../providers/request_provider.dart';
import 'widgets/classroom_picker_sheet.dart';
import 'widgets/request_media_section.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final RequestKind kind;
  final String id;
  final String? parentId;

  const RequestDetailScreen({
    super.key,
    required this.kind,
    required this.id,
    this.parentId,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isSubmitting = false;

  ({RequestKind kind, String id}) get _key =>
      (kind: widget.kind, id: widget.id);

  Future<void> _openChild(RequestModel parent, RequestChild child) async {
    final changed = await context.push<bool>(
      '/requests/student/${child.id}?parentId=${parent.id}',
    );

    if (changed == true && mounted) {
      ref.invalidate(requestDetailProvider(_key));
      await ref.read(requestListProvider.notifier).refresh();
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style:
                  destructive ? const TextStyle(color: AppColors.error) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(RequestModel request) async {
    final l10n = context.l10n;
    final repository = ref.read(requestRepositoryProvider);

    if (request.kind == RequestKind.student) {
      final classroom = await showModalBottomSheet<ClassroomModel>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const ClassroomPickerSheet(),
      );

      if (classroom == null || !mounted) return;

      final confirmed = await _confirm(
        title: l10n.requestsApproveTitle,
        body: l10n.requestsApproveStudentBody,
        confirmLabel: l10n.requestsApproveConfirm,
      );

      if (confirmed != true || !mounted) return;

      await _runAction(
        () => repository.approve(request, classroomId: classroom.id),
        l10n.requestsApprovedSuccess,
      );
      return;
    }

    final confirmed = await _confirm(
      title: l10n.requestsApproveParentTitle,
      body: l10n.requestsApproveParentBody,
      confirmLabel: l10n.requestsApproveConfirm,
    );

    if (confirmed != true || !mounted) return;

    await _runAction(
      () => repository.approve(request),
      l10n.requestsApprovedSuccess,
    );
  }

  Future<void> _reject(RequestModel request) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.requestsRejectTitle,
      body: request.kind == RequestKind.student
          ? l10n.requestsRejectStudentBody
          : l10n.requestsRejectParentBody,
      confirmLabel: l10n.requestsRejectConfirm,
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    await _runAction(
      () => ref.read(requestRepositoryProvider).reject(request),
      l10n.requestsRejectedSuccess,
    );
  }

  Future<void> _runAction(
    Future<bool> Function() action,
    String successMessage,
  ) async {
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    try {
      final changed = await action();
      if (!mounted) return;

      final message = changed ? successMessage : l10n.requestsNoChange;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      ref.invalidate(requestDetailProvider(_key));

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requestsActionError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncRequest = ref.watch(requestDetailProvider(_key));

    return asyncRequest.when(
      loading: () => _buildLoading(context, isDark),
      error: (error, _) => _buildError(context, isDark, error),
      data: (request) => _buildDetail(context, isDark, request),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: context.l10n.requestsTitle),
          const Expanded(child: ListShimmer()),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, Object error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: context.l10n.requestsTitle),
          Expanded(
            child: ErrorView(
              message: context.l10n.requestsDetailLoadError,
              detail: error.toString(),
              onRetry: () => ref.invalidate(requestDetailProvider(_key)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    bool isDark,
    RequestModel request,
  ) {
    final l10n = context.l10n;
    final isParent = request.kind == RequestKind.parent;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.requestsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _header(isDark, request, l10n),
                const SizedBox(height: 18),
                SectionHeader(
                  title: l10n.studentsSectionPersonal,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                _personalData(isDark, request, l10n),
                const SizedBox(height: 20),
                RequestMediaSection(media: request.media),
                if (isParent && request.children.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: l10n.requestsSectionChildren,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  _children(request, l10n),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          request.status == 'pending' ? _actions(request, l10n) : null,
    );
  }

  Widget _header(
    bool isDark,
    RequestModel request,
    AppLocalizations l10n,
  ) {
    final kindLabel = request.kind == RequestKind.student
        ? l10n.requestsKindStudent
        : l10n.requestsKindParent;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.fullname.isNotEmpty ? request.fullname : kindLabel,
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kindLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedFor(isDark),
                ),
              ),
            ],
          ),
        ),
        if (request.status.isNotEmpty)
          StatusBadge(
            status: request.status,
            label: studentStatusLabel(request.status, l10n),
          ),
      ],
    );
  }

  Widget _personalData(
    bool isDark,
    RequestModel request,
    AppLocalizations l10n,
  ) {
    final rows = <Widget>[
      InfoRow(label: l10n.studentsInfoFullName, value: request.fullname),
      InfoRow(label: l10n.studentsInfoEmail, value: request.email),
      InfoRow(
        label: l10n.studentsInfoIdentityNumber,
        value: request.identityNumber,
      ),
    ];

    if (request.kind == RequestKind.parent) {
      rows.add(InfoRow(label: l10n.requestsPhone, value: request.phone));
      rows.add(InfoRow(label: l10n.requestsAddress, value: request.address));
    } else {
      rows.add(InfoRow(label: l10n.studentsInfoYear, value: request.year));
      rows.add(InfoRow(label: l10n.studentsInfoBranch, value: request.branch));
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            KeyedSubtree(
              key: ValueKey('request-info-$index'),
              child: rows[index],
            ),
        ],
      ),
    );
  }

  Widget _children(RequestModel request, AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var index = 0; index < request.children.length; index++)
            ListTile(
              key: ValueKey('request-child-${request.children[index].id}'),
              title: Text(
                request.children[index].fullname,
                style: AppTypography.titleSmall,
              ),
              subtitle: request.children[index].identityNumber.isNotEmpty
                  ? Text(request.children[index].identityNumber)
                  : null,
              trailing: request.children[index].status.isNotEmpty
                  ? StatusBadge(
                      status: request.children[index].status,
                      label: studentStatusLabel(
                        request.children[index].status,
                        l10n,
                      ),
                    )
                  : null,
              onTap: () => _openChild(request, request.children[index]),
            ),
        ],
      ),
    );
  }

  Widget _actions(RequestModel request, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _reject(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withOpacity(
                        isDark ? 0.7 : 0.5,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    l10n.requestsActionReject,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: l10n.requestsActionApprove,
                icon: PhosphorIconsRegular.check,
                isGradient: true,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : () => _approve(request),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
