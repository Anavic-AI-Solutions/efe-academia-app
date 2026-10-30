library phosphor_flutter;

import 'package:flutter/material.dart';

/// Patched for Flutter >= 3.43: [IconData] is final, so duotone two-layer
/// rendering (which relied on a [PhosphorDuotoneIconData] subtype check) is
/// not available. Duotone constants resolve to their primary glyph and render
/// like any other icon. Constructor API is unchanged.
class PhosphorIcon extends Icon {
  const PhosphorIcon(
    super.icon, {
    super.key,
    super.size,
    super.fill,
    super.weight,
    super.grade,
    super.opticalSize,
    super.color,
    super.shadows,
    super.semanticLabel,
    super.textDirection,
    this.duotoneSecondaryOpacity = 0.20,
    this.duotoneSecondaryColor,
  });

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;
}
