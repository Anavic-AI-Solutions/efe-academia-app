# phosphor_flutter 2.1.0 + parche EFE (Flutter >= 3.43)

Fuente: https://pub.dev/packages/phosphor_flutter v2.1.0 (abandonado upstream).

Motivo: `class PhosphorIconData extends IconData` ya no compila porque
Flutter 3.43+ marco `IconData` como `final` (ver phosphor-icons/flutter#61).

Cambios aplicados por script (`/tmp/opencode/patch_phosphor.py`):
- `PhosphorFlatIconData(0xX, 'St')` -> `IconData(0xX, fontFamily:
  'PhosphorSt', fontPackage: 'phosphor_flutter', matchTextDirection: true)`
  (7560 constantes en 5 estilos + 2 en duotone).
- `PhosphorDuotoneIconData(0xA, PhosphorIconData(0xB, 'Duotone'))` ->
  `IconData(0xA, fontFamily: 'PhosphorDuotone', ...)` (1510 constantes).
  La capa secundaria duotone no se renderiza; la app no usa duotone.
- `phosphor_icons_base.dart`: tipos de retorno `PhosphorIconData` ->
  `IconData` (1512 metodos).
- `phosphor_icon_data.dart`: vaciado (solo nota). `phosphor_icon.dart`:
  widget sin rama duotone, misma API de constructor.

Glyphs, familias de fuentes y codepoints identicos al original.
