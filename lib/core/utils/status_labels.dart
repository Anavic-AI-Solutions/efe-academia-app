import '../../l10n/app_localizations.dart';

/// Etiquetas normalizadas para estados crudos que devuelve la API.
///
/// Reglas comunes: la comparación es en minúsculas; un valor desconocido se
/// devuelve tal cual y un valor vacío devuelve `''` (los widgets ocultan el
/// badge en ese caso).

String studentStatusLabel(String status, AppLocalizations l10n) {
  switch (status.toLowerCase()) {
    case 'approved':
      return l10n.studentsStatusApproved;
    case 'pending':
      return l10n.studentsStatusPending;
    case 'rejected':
      return l10n.studentsStatusRejected;
    case 'active':
      return l10n.studentsStatusActive;
    case 'inactive':
      return l10n.studentsStatusInactive;
    default:
      return status;
  }
}

String feeStatusLabel(String status, AppLocalizations l10n) {
  switch (status.toLowerCase()) {
    case 'paid':
      return l10n.feesStatusPaid;
    case 'partial':
      return l10n.feesStatusPartial;
    case 'pending':
      return l10n.feesStatusPending;
    case 'overdue':
      return l10n.feesStatusOverdue;
    default:
      return status;
  }
}

/// Verdadero cuando la falta cuenta como justificada.
///
/// Con `status` conocido la respuesta es directa; con `status` vacío cae al
/// heurístico histórico sobre el campo `justified` (texto de la justificación).
bool absenceIsJustified(String status, String justified) {
  switch (status.toLowerCase()) {
    case 'justified':
      return true;
    case 'pending':
    case 'unjustified':
      return false;
  }
  final value = justified.toLowerCase();
  return value.isNotEmpty && value != 'no' && value != 'false' && value != '0';
}

String absenceStatusLabel(
  String status,
  String justified,
  AppLocalizations l10n,
) {
  switch (status.toLowerCase()) {
    case 'pending':
      return l10n.studentsAbsencePending;
    case 'justified':
      return l10n.studentsAbsenceJustified;
    case 'unjustified':
      return l10n.studentsAbsenceUnjustified;
    default:
      if (status.isEmpty) {
        return absenceIsJustified(status, justified)
            ? l10n.studentsAbsenceJustified
            : l10n.studentsAbsenceUnjustified;
      }
      return status;
  }
}

String classroomStatusLabel(String status, AppLocalizations l10n) {
  switch (status.toLowerCase()) {
    case 'active':
      return l10n.classroomsStatusActive;
    case 'inactive':
      return l10n.classroomsStatusInactive;
    case 'archived':
      return l10n.classroomsStatusArchived;
    default:
      return status;
  }
}

/// Localized label for the canonical classroom shift values.
///
/// Legacy or unknown raw values are returned untouched so nothing is hidden.
String classroomShiftLabel(String shift, AppLocalizations l10n) {
  switch (shift.toLowerCase()) {
    case 'morning':
      return l10n.classroomsShiftMorning;
    case 'afternoon':
      return l10n.classroomsShiftAfternoon;
    case 'night':
      return l10n.classroomsShiftNight;
    default:
      return shift;
  }
}
