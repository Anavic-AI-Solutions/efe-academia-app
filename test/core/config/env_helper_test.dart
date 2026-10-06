import 'package:efe_mobile/core/config/env_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDefaultEnvContent', () {
    test('usa API_BASE_URL del build', () {
      final out = EnvHelper.buildDefaultEnvContent({
        'API_BASE_URL': 'https://preprod.efeacademia.com/api/v1',
        'REVERB_HOST': 'x',
        'REVERB_APP_KEY': '',
      });
      expect(
        out,
        contains('API_BASE_URL=https://preprod.efeacademia.com/api/v1'),
      );
      expect(out, contains('REVERB_HOST=x'));
      expect(out, isNot(contains('REVERB_APP_KEY')));
    });
    test('cae a localhost si API_BASE_URL falta o está vacía', () {
      expect(
        EnvHelper.buildDefaultEnvContent({}),
        contains('API_BASE_URL=http://localhost:8000/api/v1'),
      );
      expect(
        EnvHelper.buildDefaultEnvContent({'API_BASE_URL': ''}),
        contains('http://localhost:8000'),
      );
    });
  });
  group('parseEnvContent', () {
    test('parsea pares y tolera CRLF', () {
      expect(EnvHelper.parseEnvContent('A=1\r\nB=2\r\n'), {'A': '1', 'B': '2'});
    });
    test('ignora comentarios, líneas vacías y recorta espacios', () {
      expect(EnvHelper.parseEnvContent('# c\n\nA = x \nB=2 '), {
        'A': 'x',
        'B': '2',
      });
    });
    test('valores con = y líneas sin = se descartan', () {
      expect(EnvHelper.parseEnvContent('A=x=y\nmal'), {'A': 'x=y'});
    });
  });
}