import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/fee_model.dart';
import '../../providers/fee_provider.dart';

/// Archivo elegido para subir como comprobante de pago.
class ProofUploadFile {
  final List<int> bytes;
  final String name;

  const ProofUploadFile({required this.bytes, required this.name});
}

/// Extensiones y tamaño máximo que acepta el backend para el comprobante.
const _proofAllowedExtensions = {'jpg', 'jpeg', 'png', 'pdf'};
const _proofMaxBytes = 10 * 1024 * 1024;

/// Sheet modal para subir (o reemplazar) el comprobante de una cuota.
///
/// Valida extensión y tamaño en el cliente antes de llamar a la API; en
/// éxito cierra con `pop(true)` (el caller muestra el snackbar y refresca).
class ParentFeeProofSheet extends ConsumerStatefulWidget {
  final FeeModel fee;

  /// Picker inyectable para tests; por defecto usa [FilePicker.platform].
  final Future<ProofUploadFile?> Function()? pickFile;

  const ParentFeeProofSheet({
    super.key,
    required this.fee,
    this.pickFile,
  });

  @override
  ConsumerState<ParentFeeProofSheet> createState() =>
      _ParentFeeProofSheetState();
}

class _ParentFeeProofSheetState extends ConsumerState<ParentFeeProofSheet> {
  late final Future<ProofUploadFile?> Function() _pickFile =
      widget.pickFile ?? _defaultPickFile;

  ProofUploadFile? _file;
  String? _error;
  bool _isSaving = false;

  /// Verdadero si el comprobante está en revisión, por cualquiera de las dos
  /// fuentes que usa la API (`proof_status` o `status`).
  bool get _isUnderReview =>
      widget.fee.proofStatus.toLowerCase() == 'under_review' ||
      widget.fee.status.toLowerCase() == 'under_review';

  Future<ProofUploadFile?> _defaultPickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return ProofUploadFile(bytes: bytes, name: file.name);
  }

  /// Valida extensión y tamaño en el cliente (mismos límites del backend).
  String? _validationError(ProofUploadFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (!_proofAllowedExtensions.contains(extension) ||
        file.bytes.length > _proofMaxBytes) {
      return context.l10n.feesProofHint;
    }
    return null;
  }

  Future<void> _pick() async {
    final picked = await _pickFile();
    if (picked == null || !mounted) return;
    final error = _validationError(picked);
    setState(() {
      _error = error;
      _file = error == null ? picked : null;
    });
  }

  Future<void> _submit() async {
    final file = _file;
    if (file == null || _isSaving) return;
    final l10n = context.l10n;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(feeRepositoryProvider).uploadProof(
            widget.fee.id,
            bytes: file.bytes,
            filename: file.name,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = l10n.feesProofError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightInk;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.navInactive.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isUnderReview
                    ? l10n.feesReplaceProofAction
                    : l10n.feesUploadProofAction,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _contextLine(context),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedFor(isDark),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pick,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(l10n.feesProofPickFile),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.absent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.absent,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.feesProofHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedFor(isDark),
                  ),
                ),
              if (_file != null) ...[
                const SizedBox(height: 10),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 16,
                        color: AppColors.mutedFor(isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _file!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatSize(_file!.bytes.length),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PillButton(
                label: l10n.feesProofSubmit,
                isLoading: _isSaving,
                onPressed: _file == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// “Julio 2026 · Ana Pérez · $25.000,00”: mes capitalizado, hijo y monto.
  String _contextLine(BuildContext context) {
    final fee = widget.fee;
    final month = int.tryParse(fee.month);
    String monthLabel;
    if (month == null || month < 1 || month > 12) {
      monthLabel = '${fee.month} ${fee.year}'.trim();
    } else {
      final name =
          DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag())
              .format(DateTime(int.tryParse(fee.year) ?? 2000, month));
      final capitalized =
          name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
      monthLabel = '$capitalized ${fee.year}';
    }
    return [
      monthLabel,
      if (fee.studentName.isNotEmpty) fee.studentName,
      AppFormatters.formatCurrency(fee.toPay),
    ].join(' · ');
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
