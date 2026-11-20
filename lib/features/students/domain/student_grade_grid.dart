import '../../qualifications/domain/qualification_model.dart';
import '../../qualifications/domain/qualification_score.dart';

/// Periods shown in the grade grid (same as the web grade table).
const gradeGridPeriods = ['1', '2', '3'];

/// A criterion column of the web grade table: a `type` inside an optional
/// `category` group.
class GradeGridColumn {
  final String type;
  final String category;

  const GradeGridColumn({required this.type, required this.category});
}

/// Criterion columns, in web order: Escrito/Oral (Desempeño),
/// Tareas/Disciplina/Participación/Asistencia (Actitud) and Parcial.
const gradeGridColumns = [
  GradeGridColumn(type: 'Escrito', category: 'Desempeño'),
  GradeGridColumn(type: 'Oral', category: 'Desempeño'),
  GradeGridColumn(type: 'Tareas', category: 'Actitud'),
  GradeGridColumn(type: 'Disciplina', category: 'Actitud'),
  GradeGridColumn(type: 'Participación', category: 'Actitud'),
  GradeGridColumn(type: 'Asistencia', category: 'Actitud'),
  GradeGridColumn(type: 'Parcial', category: ''),
];

class GradeGridRow {
  final String period;
  final List<QualificationModel?> cells;
  final double? average;

  const GradeGridRow({
    required this.period,
    required this.cells,
    required this.average,
  });
}

/// Builds the three period rows of the grade grid.
///
/// A cell matches by `type` + `category`; when the exact category is missing
/// it falls back to the same `type` with an empty category, so qualifications
/// created from the app (no category) still show up. The period average
/// follows the web rule: every period qualification with a usable score,
/// deduplicated by `type` + `category`.
List<GradeGridRow> buildGradeGrid(List<QualificationModel> qualifications) {
  return gradeGridPeriods.map((period) {
    final periodQualifications =
        qualifications.where((item) => item.period == period).toList();

    final cells = gradeGridColumns
        .map((column) => _findCell(periodQualifications, column))
        .toList();

    final scoresByKey = <String, double>{};
    for (final qualification in periodQualifications) {
      if (qualification.scoreLabel.trim().isEmpty) continue;
      final value = qualificationScoreValue(qualification.scoreLabel);
      if (value == null) continue;
      scoresByKey[_key(qualification.type, qualification.category)] = value;
    }

    final values = scoresByKey.values.toList();
    final average =
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

    return GradeGridRow(period: period, cells: cells, average: average);
  }).toList();
}

QualificationModel? _findCell(
  List<QualificationModel> periodQualifications,
  GradeGridColumn column,
) {
  QualificationModel? fallback;
  for (final qualification in periodQualifications) {
    if (!_equal(qualification.type, column.type)) continue;
    if (_equal(qualification.category, column.category)) {
      return qualification;
    }
    if (qualification.category.trim().isEmpty) {
      fallback ??= qualification;
    }
  }
  return fallback;
}

String _key(String type, String category) =>
    '${type.trim().toLowerCase()}|${category.trim().toLowerCase()}';

bool _equal(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();
