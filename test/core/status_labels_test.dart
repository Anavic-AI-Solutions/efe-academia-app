import 'package:efe_mobile/core/utils/status_labels.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations es;
  late AppLocalizations en;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es', 'AR'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('studentStatusLabel mapea conocidos, crudos y vacío', () {
    expect(studentStatusLabel('approved', es), 'Aprobado');
    expect(studentStatusLabel('PENDING', es), 'Pendiente');
    expect(studentStatusLabel('rejected', es), 'Rechazado');
    expect(studentStatusLabel('approved', en), 'Approved');
    expect(studentStatusLabel('active', es), 'active'); // desconocido → crudo
    expect(studentStatusLabel('', es), '');
  });

  test('feeStatusLabel mapea conocidos', () {
    expect(feeStatusLabel('paid', es), 'Pagado');
    expect(feeStatusLabel('partial', es), 'Parcial');
    expect(feeStatusLabel('pending', es), 'Pendiente');
    expect(feeStatusLabel('overdue', es), 'Vencido');
    expect(feeStatusLabel('weird', es), 'weird');
  });

  test('absenceStatusLabel usa status y cae al heurístico si está vacío', () {
    expect(absenceStatusLabel('pending', '', es), 'Pendiente');
    expect(absenceStatusLabel('justified', 'si', es), 'Justificada');
    expect(absenceStatusLabel('unjustified', '', es), 'Sin justificar');
    expect(absenceStatusLabel('', 'si', es), 'Justificada');
    expect(absenceStatusLabel('', '', es), 'Sin justificar');
    expect(absenceStatusLabel('raro', '', es), 'raro');
  });

  test('classroomStatusLabel mantiene los textos existentes', () {
    expect(classroomStatusLabel('active', es), 'Activo');
    expect(classroomStatusLabel('archived', es), 'Archivado');
    expect(classroomStatusLabel('other', es), 'other');
  });
}
