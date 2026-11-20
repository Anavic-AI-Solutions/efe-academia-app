/// Text scores accepted by the web grade form, in display order.
const qualificationTextScores = [
  'Excelente',
  'Muy bueno',
  'Bueno',
  'Regular',
  'Insuficiente',
  'Mal',
];

/// Converts a raw score (number or text) into its numeric value, using the
/// same text map as the web grade table. Returns null when it cannot be
/// computed.
double? qualificationScoreValue(String? raw) {
  if (raw == null) return null;
  final clean = raw.trim().toLowerCase();
  if (clean.isEmpty) return null;

  final numeric = double.tryParse(clean);
  if (numeric != null) return numeric;

  const textMap = {
    'excelente': 10.0,
    'muy bueno': 9.0,
    'bueno': 7.0,
    'regular': 6.0,
    'insuficiente': 4.0,
    'mal': 2.0,
  };
  return textMap[clean];
}

/// Validates and normalizes the score typed in the form.
///
/// Accepts a number between 0 and 10 (with `.` or `,` as the decimal
/// separator) or one of the web text scores (case-insensitive). When editing,
/// [original] may be passed so an unchanged legacy value is always accepted,
/// even if it matches neither format. Returns null when the value is invalid.
String? normalizeQualificationScore(String raw, {String? original}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (original != null && trimmed == original.trim()) return trimmed;

  final numeric = double.tryParse(trimmed.replaceAll(',', '.'));
  if (numeric != null) {
    if (numeric.isNaN || numeric < 0 || numeric > 10) return null;
    return numeric.toString();
  }

  final lower = trimmed.toLowerCase();
  final isTextScore =
      qualificationTextScores.any((score) => score.toLowerCase() == lower);
  return isTextScore ? trimmed : null;
}
