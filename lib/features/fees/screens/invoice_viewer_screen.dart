import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../data/invoice_saver.dart';
import '../domain/fee_model.dart';
import '../domain/invoice_file.dart';
import '../providers/fee_provider.dart';
import 'widgets/fee_common.dart';

/// Builder del PDF inyectable para tests (evita cargar PDFium nativo).
typedef InvoicePdfBuilder = Widget Function(Uint8List bytes);

/// Visor in-app de la factura de una cuota (`/payments/:id/invoice`).
///
/// Pide el link firmado y descarga los bytes (`invoiceFileProvider`) para
/// renderizar el PDF oficial con pdfrx, sin salir de la app. 404 → "Factura
/// no disponible" (cuota sin PDF); otros errores → ErrorView con retry.
/// Al pie, "Descargar" guarda el PDF (diálogo nativo en desktop; en Android/
/// iOS abre el link firmado, porque `file_picker.saveFile` no está soportado).
class InvoiceViewerScreen extends ConsumerStatefulWidget {
  final String feeId;

  /// Guardado inyectable para tests; por defecto usa `saveInvoicePdf`.
  final InvoiceSaver? saver;

  /// Render del PDF inyectable para tests; por defecto usa `pdfrx`.
  final InvoicePdfBuilder? pdfBuilder;

  const InvoiceViewerScreen({
    super.key,
    required this.feeId,
    this.saver,
    this.pdfBuilder,
  });

  @override
  ConsumerState<InvoiceViewerScreen> createState() =>
      _InvoiceViewerScreenState();
}

enum _DownloadResult { saved, cancelled, error }

class _InvoiceViewerScreenState extends ConsumerState<InvoiceViewerScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoiceAsync = ref.watch(invoiceFileProvider(widget.feeId));
    // Subtítulo con mes/año e hijo desde el detalle ya cacheado; si no está,
    // el header queda solo con el título (el visor no depende de esta data).
    final fee = ref.watch(feeDetailProvider(widget.feeId)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          ScreenHeader(
            title: l10n.feesInvoiceViewerTitle,
            subtitle: fee == null ? null : _subtitle(fee),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody(invoiceAsync, l10n, isDark)),
          invoiceAsync.maybeWhen(
            data: (file) => _downloadBar(file, fee, l10n),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _subtitle(FeeModel fee) {
    final month = feeMonthLabel(fee, context);
    return fee.studentName.isEmpty ? month : '$month · ${fee.studentName}';
  }

  Widget _buildBody(
    AsyncValue<InvoiceFile> invoiceAsync,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return invoiceAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.accentFor(isDark)),
      ),
      error: (error, _) {
        final notFound = error is ApiException && error.statusCode == 404;

        if (notFound) {
          return EmptyState(
            icon: PhosphorIconsRegular.filePdf,
            title: l10n.feesInvoiceUnavailable,
          );
        }

        return ErrorView(
          message: l10n.feesInvoiceLoadError,
          detail: error.toString(),
          onRetry: () => ref.invalidate(invoiceFileProvider(widget.feeId)),
        );
      },
      data: (file) =>
          widget.pdfBuilder?.call(file.bytes) ??
          PdfViewer.data(
            file.bytes,
            sourceName: 'factura-${widget.feeId}',
            params: PdfViewerParams(
              backgroundColor: AppColors.backgroundFor(isDark),
              margin: 8,
            ),
          ),
    );
  }

  Widget _downloadBar(
    InvoiceFile file,
    FeeModel? fee,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: PillButton(
        label: l10n.feesInvoiceDownloadAction,
        icon: PhosphorIconsRegular.downloadSimple,
        isLoading: _saving,
        onPressed: () => _download(file, fee),
      ),
    );
  }

  Future<void> _download(InvoiceFile file, FeeModel? fee) async {
    if (_saving) return;
    setState(() => _saving = true);

    var result = _DownloadResult.error;
    try {
      final saver = widget.saver ?? _defaultSaver(file);
      final path = await saver(file.bytes, invoiceFileName(fee, context));
      // null = el usuario canceló el diálogo (no es error ni éxito).
      result = path == null ? _DownloadResult.cancelled : _DownloadResult.saved;
    } catch (_) {
      result = _DownloadResult.error;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result == _DownloadResult.cancelled) return;

    final message = result == _DownloadResult.saved
        ? context.l10n.feesInvoiceDownloadSuccess
        : context.l10n.feesInvoiceDownloadError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// En Android/iOS `file_picker.saveFile` no está implementado: se abre el
  /// link firmado externo (solo la descarga explícita) y se avisa si falla.
  InvoiceSaver _defaultSaver(InvoiceFile file) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isMobile) return saveInvoicePdf;

    return (bytes, name) async {
      final opened = await launchUrl(
        Uri.parse(file.url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('No se pudo abrir la factura');
      return file.url;
    };
  }
}

/// Nombre de archivo amigable: `Factura_Julio_2026_3.pdf`.
String invoiceFileName(FeeModel? fee, BuildContext context) {
  if (fee == null) return 'Factura.pdf';

  final month = feeMonthLabel(fee, context).replaceAll(' ', '_');
  return 'Factura_${month}_${fee.numberFee}.pdf';
}
