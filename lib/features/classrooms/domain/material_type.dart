/// Deriva el `type` de un material a partir de la extensión del archivo,
/// para que `MaterialTile` muestre el ícono correcto.
String materialTypeFor(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'pdf';
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'heic':
    case 'bmp':
      return 'image';
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
    case 'webm':
      return 'video';
    case 'mp3':
    case 'wav':
    case 'ogg':
    case 'm4a':
    case 'aac':
      return 'audio';
    case 'url':
    case 'link':
      return 'link';
    default:
      return 'other';
  }
}