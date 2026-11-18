import 'dart:typed_data';

/// Archivo elegido desde el dispositivo para subirlo al backend.
///
/// En plataformas IO se usa [path]; en web se usa [bytes].
class UploadFile {
  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;

  const UploadFile({
    required this.name,
    this.size = 0,
    this.path,
    this.bytes,
  });
}
