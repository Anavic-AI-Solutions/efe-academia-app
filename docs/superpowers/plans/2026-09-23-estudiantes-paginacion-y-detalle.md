# Estudiantes: paginación numerada y detalle ampliado — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Duplicar el estilo de clases en estudiantes: lista con paginación numerada fija (sin scroll infinito) y detalle con hero + tabs reales paginadas (Notas / Inasistencias / Cuotas / Información).

**Architecture:** Se reutilizan `PageResult`, `PagedListNotifier` y `PaginationBar`; se extraen a `lib/core/widgets/` los widgets compartidos (`DetailHero`, `InfoRow`, `PagedTabList`) para que ambas vistas sean idénticas. Backend: filtro aditivo `student_app_id` en `/fees`.

**Tech Stack:** Flutter 3.x, Riverpod 2 (StateNotifier), Freezed, Dio, go_router, ARB + `flutter gen-l10n`, Laravel 11 (efe-app).

**Spec:** Decisiones del usuario en sesión: (1) lista + detalle, (2) tocar backend para Cuotas con filtro `student_app_id`.

## Global Constraints

- Reutilizar tokens (`AppColors`, `AppTypography`) y widgets existentes; no inventar lenguaje visual.
- i18n en `app_es.arb` (template) y `app_en.arb`; regenerar con `/opt/flutter/bin/flutter gen-l10n`.
- Verificación: `/opt/flutter/bin/flutter analyze` y `/opt/flutter/bin/flutter test`.
- Codegen Freezed: `/opt/flutter/bin/dart run build_runner build --delete-conflicting-outputs`.
- Commits convencionales, solo archivos propios de cada tarea. No tocar el trabajo sin commitear de otros features.

---

### T1: Backend fees — filtro `student_app_id`

**Files:** `/opt/dev/efe-app/app/Http/Controllers/Api/Fees/FeeController.php` (`applyFilters`).

- [ ] Aceptar `student_app_id` (UUID de `StudentData`) y filtrar vía relación `student`; verificar `php -l` y commit en `efe-app`.

### T2: Core compartido

**Files:** `lib/core/widgets/detail_hero.dart` (nuevo), `info_row.dart` (nuevo), `paged_tab_list.dart` (movido desde classrooms), `lib/features/students/screens/widgets/student_tile.dart` (movido), `pagination_bar.dart` (claves genéricas), ARB + gen.

- `DetailHero({leading, title, status, chips, onBack})` con gradiente y pills; usado por clases y estudiantes.
- `InfoRow({label, value, isLast})` compartido.
- Claves i18n `paginationShowing/Previous/Next/Page` (reemplazan `classroomsPagination*`).
- Tests de clases siguen verdes.

### T3: Modelos

**Files:** `student_model.dart` (+freezed), `absence_model.dart` (nuevo +freezed), `qualification_model.dart`, tests.

- `StudentModel.classroomCount` desde `relationships.classrooms.data.length`.
- `AbsenceModel`: id, quantity, period, justified, description, status, date, createdAt.
- `QualificationModel.date` con fallback a `created_at`.

### T4: API/Repo

**Files:** `student_api.dart`, `student_repository.dart`, `absence_api.dart` (nuevo), `absence_repository.dart` (nuevo), `qualification_api.dart`, `qualification_repository.dart`, `fee_api.dart`, `fee_repository.dart`, tests.

- Lista de estudiantes por `page` → `PageResult<StudentModel>`.
- `getStudentQualifications/Absences/Fees(studentId, page)` → `PageResult<...>`; fees envía `student_app_id`.

### T5: Providers

**Files:** `student_provider.dart`, tests.

- `StudentListNotifier` por página + guard de respuestas viejas + quitar `print`.
- `studentQualificationsProvider`, `studentAbsencesProvider`, `studentFeesProvider` (family por id) con `PagedListNotifier`.

### T6: Lista paginada

**Files:** `student_list_screen.dart`, `test/students/student_list_screen_test.dart`.

- Quitar scroll infinito; `PaginationBar` fija; conservar chips de estado, dropdowns año/sede, búsqueda y pull-to-refresh.

### T7: Detalle hero + Información

**Files:** `student_detail_screen.dart`, `widgets/student_detail_header.dart`, `widgets/student_info_tab.dart`, tests.

- Hero con `AppAvatar`, estado y chips (sede, año); tabs scrollables.
- Información: `StatCard` (Año, Sede, Documento, Clases) + secciones Datos personales / Institucional.

### T8: Tabs relacionadas

**Files:** `widgets/student_related_tabs.dart`, `widgets/qualification_tile.dart`, `widgets/absence_tile.dart`, `widgets/fee_tile.dart`, tests.

- Tiles contextuales sobre `PagedTabList` + `PaginationBar`; vacíos con `studentsNoGrades/NoAbsences/NoFees`.

### T9: Verificación final

- `gen-l10n`, `build_runner`, `flutter analyze`, suite completa, capturas temporales de lista/detalle (se borran).
