import 'dart:typed_data';

/// Archivo elegido desde el dispositivo para adjuntar a un material.
///
/// En plataformas IO se usa [path]; en web se usa [bytes].
class MaterialUploadFile {
  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;

  const MaterialUploadFile({
    required this.name,
    this.size = 0,
    this.path,
    this.bytes,
  });
}
