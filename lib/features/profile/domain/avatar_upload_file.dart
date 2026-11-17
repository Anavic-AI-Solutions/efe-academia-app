import 'dart:typed_data';

/// Avatar elegido desde el dispositivo, listo para subir en `multipart/form-data`.
class AvatarUploadFile {
  final Uint8List bytes;
  final String name;

  const AvatarUploadFile({
    required this.bytes,
    required this.name,
  });
}
