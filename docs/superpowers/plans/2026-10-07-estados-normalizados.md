# Estados normalizados (alumnos, cuotas, faltas) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que los estados que hoy se muestran crudos en la app (alumnos, cuotas, faltas y aula) aparezcan siempre normalizados y localizados (ES/EN), con color coherente, sin cambiar los datos que devuelve la API.

**Architecture:** Helper puro `status_labels.dart` que mapea valores crudos de la API a etiquetas ARB (desconocidos pasan crudos; vacío se oculta). `StatusBadge` gana un `label` opcional y mantiene el valor crudo para el color. `classroomStatusLabel` se centraliza acá. No hay cambios de API ni de modelos.

**Tech Stack:** Flutter 3.x, Riverpod 2, ARB (es/en), `flutter gen-l10n`, widget tests con fakes manuales.

**Spec:** `docs/superpowers/specs/2026-10-07-estados-normalizados-y-materiales-profesor-design.md`

## Global Constraints

- Sin dependencias nuevas.
- Todos los textos vía ARB (`lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`) + `flutter gen-l10n`.
- Reusar `StatusBadge` / `DetailHero`; no tocar capa de datos, modelos ni API.
- Tests: fakes/manuales como el resto de la suite; verificación `flutter analyze` (0 issues) y `flutter test`.
- Commits convencionales (`fix(students): ...`, `refactor(core): ...`).
- Rama de trabajo: `feat/estados-y-materiales` en `efe_mobile` (crear desde `master` al iniciar la ejecución; los dos planes comparten rama para no conflictuar los ARB).

## Review Focus

- Estado de alumno vacío: el badge desaparece (no queda una píldora vacía).
- Valor desconocido (p. ej. `active` histórico en alumno): se muestra crudo, sin crash.
- Falta con `status` vacío y `justified` con texto: cae al heurístico (Justificada/No justificada).
- Locale EN: todas las etiquetas nuevas salen en inglés.
- Aula en el hero del detalle: mismo texto normalizado que en la tarjeta de la lista.

---

### Task 1: Helper de etiquetas + claves ARB

**Files:**
- Create: `lib/core/utils/status_labels.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/core/status_labels_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations` generado.
- Produces: `String studentStatusLabel(String status, AppLocalizations l10n)`; `String feeStatusLabel(String status, AppLocalizations l10n)`; `String absenceStatusLabel(String status, String justified, AppLocalizations l10n)`; `String classroomStatusLabel(String status, AppLocalizations l10n)`; `bool absenceIsJustified(String status, String justified)` (usada por el tile para el color).

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/status_labels_test.dart
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
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/core/status_labels_test.dart`
Expected: FAIL de compilación (`status_labels.dart` no existe / getters ARB inexistentes).

- [ ] **Step 3: Agregar las claves ARB**

En `app_es.arb`:

```json
"studentsStatusApproved": "Aprobado",
"studentsStatusPending": "Pendiente",
"studentsStatusRejected": "Rechazado",
"feesStatusPaid": "Pagado",
"feesStatusPartial": "Parcial",
"feesStatusPending": "Pendiente",
"feesStatusOverdue": "Vencido",
"studentsAbsencePending": "Pendiente"
```

En `app_en.arb`: `Approved`, `Pending`, `Rejected`, `Paid`, `Partial`, `Pending`, `Overdue`, `Pending`.

- [ ] **Step 4: Generar localizaciones**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations*.dart` regenerados sin errores.

- [ ] **Step 5: Implementar el helper**

`lib/core/utils/status_labels.dart`: switch por `status.toLowerCase()` con los mapeos de la tabla del spec; default → `status`. `absenceIsJustified`: `justified` no vacío y distinto de `no|false|0` (misma heurística que hoy en `AbsenceTile`), salvo `status` conocido (`justified` → true, `unjustified|pending` → false). `absenceStatusLabel`: con `status` vacío usa `absenceIsJustified`; con desconocido no vacío devuelve crudo. `classroomStatusLabel`: mover el switch existente de `classroom_filter_sheet.dart` sin cambiar textos.

- [ ] **Step 6: Correr el test y verificar que pasa**

Run: `flutter test test/core/status_labels_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/core/utils/status_labels.dart lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/core/status_labels_test.dart
git commit -m "feat(core): helper de etiquetas de estado normalizadas"
```

---

### Task 2: Badge compartido + alumno (tarjeta, tile, hero)

**Files:**
- Modify: `lib/core/widgets/status_badge.dart`, `lib/features/students/screens/widgets/student_card.dart`, `student_tile.dart`, `student_detail_header.dart`
- Test: `test/students/student_status_badge_test.dart`

**Interfaces:**
- Consumes: `studentStatusLabel` de Task 1.
- Produces: `StatusBadge({required String status, String? label, Color? color})` (el texto mostrado es `label ?? status`; el color se calcula con `status` crudo); `StatusBadge.colorFor` suma `rejected` → `AppColors.error`.

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/students/student_status_badge_test.dart
// Para cada widget: pump con localizedApp(home: Scaffold(body: ...)).
// - StudentCard(status: 'approved') → find.text('Aprobado') y find.text('approved') findsNothing.
// - StudentCard(status: '') → find.byType(StatusBadge) findsNothing.
// - StudentCard(status: 'active') → find.text('active') (desconocido, crudo, sin romper).
// - StudentTile(status: 'pending') → find.text('Pendiente').
// - StudentDetailHeader(status: 'rejected') → find.text('Rechazado').
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/students/student_status_badge_test.dart`
Expected: FAIL (hoy se muestra `approved` crudo y el badge vacío).

- [ ] **Step 3: Implementar**

- `StatusBadge`: agregar `final String? label;` y mostrar `label ?? status`; agregar `case 'rejected': return AppColors.error;` en `colorFor`.
- `StudentCard`: borrar el `_StatusBadge` privado; usar `StatusBadge(status: student.status, label: studentStatusLabel(student.status, l10n))`, envuelto en `if (student.status.isNotEmpty)`.
- `StudentTile`: mismo cambio (ya oculta si vacío).
- `StudentDetailHeader`: `status: studentStatusLabel(student.status, l10n)`.

- [ ] **Step 4: Correr tests**

Run: `flutter test test/students test/core`
Expected: PASS (los existentes de alumnos siguen verdes; el fixture `active` del detalle se sigue mostrando crudo).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/status_badge.dart lib/features/students/screens/widgets/student_card.dart lib/features/students/screens/widgets/student_tile.dart lib/features/students/screens/widgets/student_detail_header.dart test/students/student_status_badge_test.dart
git commit -m "fix(students): estado del alumno normalizado en lista, aula y detalle"
```

---

### Task 3: Cuotas, faltas y hero del aula

**Files:**
- Modify: `lib/features/fees/screens/widgets/fee_card.dart`, `lib/features/students/screens/widgets/fee_tile.dart`, `lib/features/fees/screens/fee_detail_screen.dart`, `lib/features/students/screens/widgets/absence_tile.dart`, `lib/features/classrooms/screens/widgets/classroom_filter_sheet.dart`, `classroom_filter_chips.dart`, `professor_classroom_list_card.dart`, `classroom_detail_header.dart`
- Modify (tests existentes): `test/students/student_detail_screen_test.dart:447`, `test/classrooms/classroom_detail_screen_test.dart:245`
- Test: `test/fees/fee_status_badge_test.dart`, `test/students/absence_status_badge_test.dart`

**Interfaces:**
- Consumes: `feeStatusLabel`, `absenceStatusLabel`, `absenceIsJustified`, `classroomStatusLabel` de Task 1; `StatusBadge.label` de Task 2.
- Produces: `ClassroomDetailHeader` pasa `classroomStatusLabel(classroom.status, l10n)` a `DetailHero.status`.

- [ ] **Step 1: Escribir/actualizar los tests que fallan**

- `test/fees/fee_status_badge_test.dart`: `FeeCard(status: 'paid')` → `'Pagado'`; `FeeTile(status: 'partial')` → `'Parcial'`; `FeeTile(status: 'overdue')` → `'Vencido'`.
- `test/students/absence_status_badge_test.dart`: `AbsenceTile(status: 'pending')` → `'Pendiente'`; `status: ''` + `justified: 'si'` → `'Justificada'`; `status: 'unjustified'` → `'Sin justificar'`.
- `test/students/student_detail_screen_test.dart:447`: cambiar `expect(find.text('pending'), ...)` → `'Pendiente'`.
- `test/classrooms/classroom_detail_screen_test.dart:245`: cambiar `expect(find.text('active'), ...)` → `'Activo'`.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/fees test/students/absence_status_badge_test.dart test/students/student_detail_screen_test.dart test/classrooms/classroom_detail_screen_test.dart`
Expected: FAIL en los textos normalizados nuevos.

- [ ] **Step 3: Implementar**

- `FeeCard`: borrar `_StatusBadge` privado; `StatusBadge(status: fee.status, label: feeStatusLabel(fee.status, l10n))`.
- `FeeTile`: `StatusBadge(status: fee.status, label: feeStatusLabel(...))`.
- `FeeDetailScreen`: `_InfoRow` de estado con `feeStatusLabel(fee.status, l10n)`.
- `AbsenceTile`: reemplazar `_isJustified` por `absenceStatusLabel(...)`; color: `status == 'pending'` → warning, `absenceIsJustified` → success, si no → error.
- `classroom_filter_sheet.dart`: borrar `classroomStatusLabel` local (queda en `status_labels.dart`); actualizar imports en `classroom_filter_sheet.dart`, `classroom_filter_chips.dart`, `professor_classroom_list_card.dart`.
- `classroom_detail_header.dart`: `status: classroomStatusLabel(classroom.status, context.l10n)`.

- [ ] **Step 4: Correr la suite completa**

Run: `flutter analyze && flutter test`
Expected: 0 issues y suite en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/features/fees lib/features/students/screens/widgets/absence_tile.dart lib/features/classrooms/screens/widgets lib/features/fees/screens/fee_detail_screen.dart test/fees test/students test/classrooms
git commit -m "fix(core): cuotas, faltas y aula con estados normalizados"
```
