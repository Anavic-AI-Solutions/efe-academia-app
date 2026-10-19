import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda el PDF de una factura y devuelve la ruta elegida.
///
/// `null` significa que el usuario canceló el diálogo (no es un error).
/// En Android/iOS `saveFile` no está implementado en `file_picker` 6.x; el
/// visor usa el fallback externo (ver `InvoiceViewerScreen`).
typedef InvoiceSaver = Future<String?> Function(
  Uint8List bytes,
  String fileName,
);

Future<String?> saveInvoicePdf(Uint8List bytes, String fileName) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: fileName,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    // Canceló el diálogo: no se escribe nada.
    if (path == null) return null;

    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  } on UnimplementedError {
    // Sin `saveFile` (Android/iOS): el visor resuelve la descarga por fuera.
    rethrow;
  } catch (_) {
    // Diálogo nativo no disponible (p. ej. Linux sin zenity/kdialog): se
    // guarda en la carpeta Descargas del usuario para no perder la descarga.
    final downloads = await getDownloadsDirectory();
    if (downloads == null) rethrow;

    final file = File(p.join(downloads.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
