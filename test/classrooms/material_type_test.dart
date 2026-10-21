import 'package:efe_mobile/features/classrooms/domain/material_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('materialTypeFor deriva el tipo desde la extensión', () {
    expect(materialTypeFor('guia.pdf'), 'pdf');
    expect(materialTypeFor('foto.JPG'), 'image');
    expect(materialTypeFor('video.mp4'), 'video');
    expect(materialTypeFor('tema.mp3'), 'audio');
    expect(materialTypeFor('enlace.url'), 'link');
    expect(materialTypeFor('notas.docx'), 'other');
  });
}
