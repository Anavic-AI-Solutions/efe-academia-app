/// Classroom choice used by the qualification form when the caller does not
/// fix a single classroom.
class QualificationClassroomOption {
  final String id;
  final String name;

  const QualificationClassroomOption({required this.id, required this.name});
}

/// Qualification types accepted by the web grade table, in web order.
const qualificationTypes = [
  'Escrito',
  'Oral',
  'Tareas',
  'Disciplina',
  'Participación',
  'Asistencia',
  'Parcial',
  'Final',
  'Recuperatorio',
];

/// Periods shown by the qualification form.
const qualificationPeriods = ['1', '2', '3'];

/// Types for the dropdown. When editing a grade created elsewhere, its current
/// type is kept even if it is not part of the default list.
List<String> qualificationTypeOptions(String? current) {
  final value = current?.trim() ?? '';
  if (value.isEmpty || qualificationTypes.contains(value)) {
    return qualificationTypes;
  }
  return [...qualificationTypes, value];
}

/// Periods for the dropdown. When editing, the current period is kept even if
/// it is not part of the default list.
List<String> qualificationPeriodOptions(String? current) {
  final value = current?.trim() ?? '';
  if (value.isEmpty || qualificationPeriods.contains(value)) {
    return qualificationPeriods;
  }
  return [...qualificationPeriods, value];
}
