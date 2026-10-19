import 'dart:typed_data';

/// Factura descargada por el link firmado: bytes del PDF y su URL (se usa
/// como fallback de descarga en plataformas sin diálogo de guardado).
class InvoiceFile {
  final Uint8List bytes;
  final String url;

  const InvoiceFile({required this.bytes, required this.url});
}
