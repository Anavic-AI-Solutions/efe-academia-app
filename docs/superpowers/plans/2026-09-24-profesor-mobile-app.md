# Interfaz del profesor — Implementation Plan (app Flutter)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar en `efe_mobile` las 3 pantallas del mockup (Inicio, Tomar asistencia, Calificaciones) con barra inferior de 4 ítems, consumiendo los endpoints de `efe-app`.

**Architecture:** Home específica por rol dentro del branch Inicio; feature nueva `attendance` (estado del día con ediciones locales y guardado bulk); feature `qualifications` extendida con resumen por aula y creación de notas; tokens azules del mockup en un archivo propio; barra inferior de 4 ítems con etiquetas.

**Tech Stack:** Flutter 3.x, Riverpod 2 (StateNotifier), go_router 14, Dio 5, freezed, Phosphor Icons, ARB (es/en).

**Spec:** `efe-app/docs/superpowers/specs/2026-09-24-profesor-mobile-design.md`

## Global Constraints

- Sin dependencias nuevas.
- Todos los textos vía ARB (es y en) + `flutter gen-l10n`.
- Modelos freezed nuevos → `dart run build_runner build --delete-conflicting-outputs`.
- Reusar `AppCard`, `AppAvatar`, `PillButton`, `EmptyState`, `ErrorView`, `LoadingShimmer`, `AppSearchBar`.
- Convención de tests: fakes manuales + `localizedApp` (ver `test/helpers/localized_app.dart`); correr `flutter test` y `flutter analyze`.
- Commits convencionales (`feat(professor): ...`, `test(professor): ...`).
- iOS status bar del mockup y el marco del teléfono **no** se implementan.

---

### Task B1: Tokens de color del profesor + badge de nota

**Files:**
- Create: `lib/app/theme/professor_colors.dart`
- Create: `lib/core/widgets/grade_badge.dart`
- Test: `test/theme/professor_colors_test.dart`

- [ ] **Step 1: Test** del mapeo de color por nota y de `formatGrade(9.2) == '9.2'`, `formatGrade(null) == '—'`.
- [ ] **Step 2: `ProfessorColors`** — gradiente `#5F92C9→#83B0E0`, `primary #3F6EA8`, `primarySoft #5F92C9`, `accent #83B0E0`, `ink #2F4A6B`, `muted #71799A`, `surface #F5F6FA`, `onPrimary #FFFFFF`, `overlay rgba(255,255,255,0.12)`, `navInactive #9AA2BD`, `present #2FA36C`, `absent #E05353`, `gradeHigh #2FA36C`, `gradeMid #4A5AA0`, `gradeWarn #E0912F`, `gradeLow #E05353`.
- [ ] **Step 3: `GradeBadge`** — pill con `Text(score)` y color por umbral (≥8 / 6-7.9 / 4-5.9 / <4 / null).
- [ ] **Step 4:** `flutter test test/theme` + commit.

### Task B2: Barra inferior de 4 ítems + reubicar búsqueda

**Files:**
- Modify: `lib/app/router.dart` (quitar `_CenterSearchItem`, `_NavItem` con etiqueta y pill)
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart` (lupa en el header)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb` (`navClasses` → "Aulas"/"Classrooms"; claves de búsqueda)
- Test: `test/app/bottom_nav_test.dart` (create)

**Interfaces:**
- Consumes: `authProvider` (rol) y `ProfessorColors`.
- Produces: nav con 4 ítems y color de acento por rol; `CustomBottomNav` sigue recibiendo `navigationShell`.

- [ ] **Step 1:** `flutter gen-l10n` tras editar ARB.
- [ ] **Step 2:** `CustomBottomNav` recibe `accentColor`; renderiza etiqueta debajo del ícono y un pill de fondo cuando está activo (mockup). Acento `ProfessorColors.primarySoft` si `user?.role == 'professor'`, si no `AppColors.primary`.
- [ ] **Step 3:** `_NavItem` dibuja `label` (hoy el parámetro existe sin usarse).
- [ ] **Step 4:** Agregar ícono de búsqueda (`PhosphorIconsRegular.magnifyingGlass`) al header del dashboard genérico; en `ProfessorHomeScreen` va en el header degradado.
- [ ] **Step 5:** Test de la barra: 4 destinos, sin botón central, etiquetas visibles. Commit.

### Task B3: Dashboard role-aware

**Files:**
- Modify: `lib/features/dashboard/domain/dashboard_data.dart` (freezed: `role`, `classroomsCount`, `absencesToday`, `classrooms: List<ProfessorClassroomSummary>`)
- Create: `lib/features/dashboard/domain/professor_classroom_summary.dart` (freezed: id, name, studentsCount)
- Modify: `lib/features/dashboard/data/dashboard_repository.dart`
- Test: `test/dashboard/dashboard_repository_test.dart`

- [ ] **Step 1: Test** con payload real de `/statistics/dashboard` para profesor (`classrooms_count`, `total_students`, `absences_today`, `classrooms_detail`) y para admin (`total_students`, ...).
- [ ] **Step 2:** Implementar el mapeo por rol (keys del profesor + compatibilidad con las actuales).
- [ ] **Step 3:** `dart run build_runner build --delete-conflicting-outputs`, `flutter test test/dashboard`. Commit.

### Task B4: Home del profesor

**Files:**
- Create: `lib/features/dashboard/screens/professor_home_screen.dart`
- Create: `lib/features/dashboard/screens/widgets/professor_home_header.dart`
- Create: `lib/features/dashboard/screens/widgets/professor_stats_row.dart`
- Create: `lib/features/dashboard/screens/widgets/professor_classroom_card.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart` (ramifica por rol)
- Modify: ARB (saludo, stats, "Mis aulas", CTAs, vacío)
- Test: `test/dashboard/professor_home_screen_test.dart`

**Interfaces:**
- Consumes: `dashboardProvider`, `unreadCountProvider`, `ProfessorColors`.
- Produces: navegación a `/classrooms/:id/attendance` y `/classrooms/:id/grades` del aula seleccionada.

- [ ] **Step 1:** Test: con 2 aulas muestra ambas y selecciona la primera; tocar la segunda cambia la selección; "Tomar asistencia" navega al id seleccionado (usar un `GoRouter` de prueba o verificar el callback de navegación).
- [ ] **Step 2:** Header degradado con `AppAvatar` (iniciales, borde blanco), "Buen día" según hora, nombre, campanita con punto si `unreadCount > 0`, lupa.
- [ ] **Step 3:** Stats en 3 tarjetas translúcidas: Aulas / Alumnos / Ausentes.
- [ ] **Step 4:** Sección "Mis aulas" (`SectionHeader` estilo mockup) con tarjetas seleccionables; estado de selección local (`StatefulWidget` o `NotifierProvider`).
- [ ] **Step 5:** CTAs `PillButton` primario/secundario; navegación por `context.go('/classrooms/:id/attendance')` (mantiene el branch Aulas activo).
- [ ] **Step 6:** `dashboard_screen.dart`: `role == 'professor' ? const ProfessorHomeScreen() : _buildGeneric(...)`. Commit.

### Task B5: Datos de asistencia

**Files:**
- Create: `lib/features/attendance/domain/attendance_day.dart` (freezed)
- Create: `lib/features/attendance/data/attendance_api.dart`
- Create: `lib/features/attendance/data/attendance_repository.dart`
- Create: `lib/features/attendance/providers/attendance_provider.dart`
- Test: `test/attendance/attendance_repository_test.dart`, `test/attendance/attendance_provider_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (`/classrooms/$id/attendance` GET/POST).
- Produces: `AttendanceDay {date, classroomId, classroomName, studentsCount, absentCount, students[AttendanceStudent{id, fullname, status, absenceId}]}`; `AttendanceNotifier`: `load()`, `toggle(studentId)`, `save()`, `hasChanges`, `saveSuccess`.

- [ ] **Step 1: Test** de parseo (status `present/absent`, `absence_id` null) y de payload de guardado (`absent_student_ids`).
- [ ] **Step 2:** Implementar api/repo/providers (estados loading/error/data, `toggle` local, `save` con `isSaving` y error).
- [ ] **Step 3:** Test del notifier con fake repository: toggle cambia estado y `hasChanges`; save exitoso limpia `hasChanges`; error mantiene ediciones. Commit.

### Task B6: Pantalla Tomar asistencia

**Files:**
- Create: `lib/features/attendance/screens/attendance_screen.dart`
- Create: `lib/features/attendance/screens/widgets/attendance_student_row.dart`
- Modify: `lib/app/router.dart` (ruta hija `attendance` de `/classrooms/:id`)
- Modify: ARB
- Test: `test/attendance/attendance_screen_test.dart`

- [ ] **Step 1:** Test widget con fake: lista alumnos, toggles P/A cambian color, "Guardar asistencia" llama al save, estado vacío y error.
- [ ] **Step 2:** Header (back, "Asistencia · {aula}", "{fecha} · {N} alumnos") con `SafeArea`; lista de filas; botón fijo abajo.
- [ ] **Step 3:** `PopScope`/`canPop: false` con diálogo si `hasChanges`.
- [ ] **Step 4:** Ruta + navegación. Commit.

### Task B7: Datos de calificaciones por aula

**Files:**
- Create: `lib/features/qualifications/domain/classroom_grades_summary.dart` (freezed)
- Modify: `lib/features/qualifications/data/qualification_api.dart` (+ `getClassroomGradesSummary`, + `createQualification`)
- Modify: `lib/features/qualifications/data/qualification_repository.dart`
- Modify: `lib/features/qualifications/providers/qualification_provider.dart` (+ `classroomGradesProvider` family, + `createQualification`)
- Test: `test/qualifications/classroom_grades_test.dart`

- [ ] **Step 1: Test** de parseo (`average` null → null; no 0) y de payload de creación.
- [ ] **Step 2-3:** Implementar y testear. Commit.

### Task B8: Pantalla Calificaciones

**Files:**
- Create: `lib/features/qualifications/screens/classroom_grades_screen.dart`
- Create: `lib/features/qualifications/screens/widgets/grade_student_row.dart`
- Modify: `lib/app/router.dart` (ruta hija `grades`)
- Modify: ARB
- Test: `test/qualifications/classroom_grades_screen_test.dart`

- [ ] **Step 1:** Test widget: promedio del aula, filas con badge, sin notas muestra "—".
- [ ] **Step 2:** Header degradado con back + caja "Promedio del aula"; lista; botón "+ Cargar calificación".
- [ ] **Step 3:** Ruta + navegación. Commit.

### Task B9: Sheet de carga de nota

**Files:**
- Create: `lib/features/qualifications/screens/widgets/create_qualification_sheet.dart`
- Modify: `lib/features/qualifications/screens/classroom_grades_screen.dart` (abre el sheet y refresca)
- Modify: ARB
- Test: `test/qualifications/create_qualification_sheet_test.dart`

- [ ] **Step 1:** Test: validación de nota (numérica 0-10), submit llama al repository, error visible.
- [ ] **Step 2:** Formulario: alumno (preseleccionado si viene de una fila), tipo (`Parcial` / `Oral`), período (`1`/`2`/`3`), nota, descripción.
- [ ] **Step 3:** Al guardar: cerrar, snackbar de éxito y `refresh()` del resumen. Commit.

### Task B10: Cierre

- [ ] **Step 1:** `flutter gen-l10n`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (sin errores nuevos), `flutter test`.
- [ ] **Step 2:** Prueba manual en Linux desktop contra la API de dev con un usuario profesor (credencial provista por el cliente): Inicio → Asistencia → guardar → reabrir; Inicio → Calificaciones → cargar nota → promedio actualizado.
- [ ] **Step 3:** Actualizar `TASKS.md`/`STATE.md` en ambos repos y commit final.
