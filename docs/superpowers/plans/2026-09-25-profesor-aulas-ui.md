# Aulas del profesor — Implementation Plan (app Flutter)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extender la interfaz azul del profesor a la lista de aulas y al detalle de aula, y hacer que la API devuelva solo las aulas asignadas al profesor.

**Architecture:** Filtrado por rol en la API (`ClassroomController@index`/`@filters`); widgets base compartidos del profesor (`ProfessorGradientHeader`, `ProfessorCard`); la lista de aulas ramifica por rol dentro de `ClassroomListScreen`; el detalle pasa a hero azul con CTAs a asistencia/notas; `accentColor` configurable en los widgets de filtros y estados.

**Tech Stack:** Laravel 11 + Pest (tests escritos, no ejecutados), Flutter 3.x, Riverpod 2, go_router 14, Phosphor Icons, ARB (es/en).

**Spec:** `efe-app/docs/superpowers/specs/2026-09-25-profesor-aulas-design.md`

## Global Constraints

- Sin dependencias nuevas.
- Todos los textos vía ARB (es y en) + `flutter gen-l10n`.
- Reusar `AppCard`/`EmptyState`/`ErrorView`/`PaginationBar`/`AppSearchBar` y la paleta `ProfessorColors`.
- Tests: fakes manuales; correr `flutter analyze` y `flutter test`.
- Commits convencionales (`feat(api): ...`, `feat(professor): ...`).
- `efe-app`: no ejecutar Pest (borra la base); verificar con `./vendor/bin/pint`.

---

### Task 1: API — acotar aulas al profesor

**Files:**
- Modify: `app/Http/Controllers/Api/Classrooms/ClassroomController.php`
- Test: `tests/Feature/Api/ClassroomsTest.php`

**Interfaces:**
- Produces: `scopeToProfessor(Request $request, $query): void` (privado), aplicado en `index()` y `filters()`.

- [x] **Step 1:** Helper `scopeToProfessor`: si el usuario tiene rol `professor` y no tiene `admin`/`branch`, agrega `whereHas('professor', professor_data.user_id = user->id)`.
- [x] **Step 2:** Tests: profesor solo ve asignadas; sin asignadas → lista vacía; admin con rol profesor ve todas; `filters` acotado.
- [x] **Step 3:** `./vendor/bin/pint` + `php -l`. Commit `feat(api): acotar listado de aulas al profesor`.

### Task 2: Widgets base del profesor

**Files:**
- Create: `lib/features/professor/widgets/professor_gradient_header.dart`
- Create: `lib/features/professor/widgets/professor_card.dart`
- Modify: `lib/features/auth/domain/user_model.dart` (`extension UserModelRoleX`, `isProfessor`)
- Modify: `lib/features/professor/widgets/professor_screen_header.dart`
- Modify: `lib/features/dashboard/screens/widgets/professor_home_header.dart`
- Modify: `lib/features/dashboard/screens/widgets/professor_classroom_card.dart`

- [x] **Step 1:** Extraer el contenedor degradado y la tarjeta blanca; usarlos en los widgets existentes sin cambiar la salida visual.
- [x] **Step 2:** `flutter test` (suite existente) y `flutter analyze`. Commit `refactor(professor): reutilizar header y tarjeta del profesor`.

### Task 3: Estados vacío/error con acento

**Files:**
- Modify: `lib/core/widgets/empty_state.dart`, `lib/core/widgets/error_view.dart`, `lib/core/widgets/pill_button.dart`
- Modify: pantallas de profesor (home, asistencia, notas)

- [x] **Step 1:** `accentColor` opcional (default índigo) en `EmptyState`/`ErrorView`; `color` opcional en `PillButton`.
- [x] **Step 2:** Las pantallas del profesor pasan `ProfessorColors.primarySoft`. Commit `refactor(core): acento configurable`.

### Task 4: Filtros de aulas con acento

**Files:**
- Create: `lib/features/classrooms/screens/widgets/classroom_filter_button.dart`
- Modify: `classroom_filter_chips.dart`, `classroom_filter_sheet.dart`, `classroom_list_screen.dart`

- [x] **Step 1:** Extraer `_FilterButton` a `ClassroomFilterButton` con `accentColor`.
- [x] **Step 2:** Thread `accentColor` en chips, sheet y `PillButton` del sheet.
- [x] **Step 3:** `flutter test test/classrooms`. Commit `refactor(classrooms): acento configurable en filtros`.

### Task 5: Lista "Mis aulas" del profesor

**Files:**
- Create: `lib/features/classrooms/screens/widgets/professor_classrooms_header.dart`
- Create: `lib/features/classrooms/screens/widgets/professor_classroom_list_card.dart`
- Modify: `lib/features/classrooms/screens/classroom_list_screen.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/classrooms/professor_classroom_list_test.dart`

- [x] **Step 1:** `professorClassroomsCount` (plural ICU) + `flutter gen-l10n`.
- [x] **Step 2:** Header degradado "Mis aulas" con contador; tarjeta con horario/aula/alumnos/estado/chevron.
- [x] **Step 3:** `ClassroomListScreen` ramifica por `user.isProfessor` (header, fondo, acentos, tarjeta, vacío "Todavía no tenés aulas asignadas"); el resto de roles no cambia.
- [x] **Step 4:** Tests: header/contador/cards, tap navega al detalle, vacío del profesor, rol genérico intacto. Commit `feat(professor): lista de aulas del profesor`.

### Task 6: Detalle de aula con hero azul y CTAs

**Files:**
- Modify: `lib/core/widgets/detail_hero.dart` (`gradient`, `bottom` opcionales)
- Modify: `lib/features/classrooms/screens/widgets/classroom_detail_header.dart`
- Modify: `lib/features/classrooms/screens/classroom_detail_screen.dart`
- Modify: `lib/features/classrooms/screens/widgets/classroom_summary_tab.dart`
- Test: `test/classrooms/classroom_detail_screen_test.dart`

- [x] **Step 1:** `DetailHero` acepta degradado y slot inferior (sin cambios para el resto).
- [x] **Step 2:** Header del profesor: degradado azul + CTAs "Tomar asistencia"/"Cargar nota".
- [x] **Step 3:** Detalle: tabs en azul, fondo `ProfessorColors.surface`, CTAs con `context.push` a `/attendance` y `/grades`; resumen con StatCards azules.
- [x] **Step 4:** Tests: acciones visibles, navegación a ambas pantallas, detalle genérico sin acciones. Commit `feat(professor): detalle de aula con hero azul y accesos`.

### Task 7: Cierre

- [x] **Step 1:** `flutter gen-l10n`, `flutter analyze` (sin errores nuevos), `flutter test` (150 en verde).
- [x] **Step 2:** Spec `2026-09-25-profesor-aulas-design.md` en `efe-app`; actualizar tests de listas existentes con fake de auth.
- [ ] **Step 3:** Prueba manual en Linux desktop contra la API dev con un usuario profesor: Aulas solo con sus aulas → detalle → Tomar asistencia → volver → Cargar nota. (Pendiente: credencial del cliente.)

### Task 8: Detalle de alumno del profesor (marco + Info + vacíos)

**Files:**
- Modify: `lib/core/widgets/paged_tab_list.dart` (`accentColor` → `EmptyState`/`ErrorView`)
- Modify: `lib/features/classrooms/screens/widgets/classroom_related_tabs.dart` (`isProfessor` → accent)
- Modify: `lib/features/classrooms/screens/classroom_detail_screen.dart` (pasa `isProfessor` a los tabs)
- Modify: `lib/features/students/screens/student_detail_screen.dart` (hero/tabs/fondo/error por rol)
- Modify: `lib/features/students/screens/widgets/student_detail_header.dart` (degradado azul)
- Modify: `lib/features/students/screens/widgets/student_info_tab.dart` (StatCards azules)
- Modify: `lib/features/students/screens/widgets/student_related_tabs.dart` (`isProfessor` → accent)
- Test: `test/students/student_detail_screen_test.dart`, `test/classrooms/classroom_detail_screen_test.dart`

**Interfaces:**
- Consumes: `UserModelRoleX.isProfessor`, `ProfessorColors`, `DetailHero.gradient`.
- Produces: `PagedTabList.accentColor`; `isProfessor` en los 6 widgets de tabs y en `StudentDetailHeader`/`StudentInfoTab`.

- [x] **Step 1:** `PagedTabList.accentColor`; tabs del detalle de aula lo reciben y los tests verifican azul para profesor / default para el resto.
- [x] **Step 2:** `StudentDetailScreen` ramifica por rol (fondo, TabBar, error) y pasa `isProfessor` a header y tabs; `StudentInfoTab` pinta los StatCards con `ProfessorColors`.
- [x] **Step 3:** Tests: Info azul, vacíos azules, genérico sin cambios, overflow en pantalla chica; `_openTab` con `ensureVisible` para TabBar scrolleable. `flutter analyze` 0 errores y `flutter test` 158 en verde.
- [ ] **Step 4:** Commit `feat(professor): detalle de alumno con la interfaz azul`.

### Task 9: Grilla de notas del alumno (paridad con la web)

**Files:**
- Modify: `lib/features/qualifications/domain/qualification_model.dart` (+`category`, +`scoreLabel`, +`classroomName` anidada)
- Create: `lib/features/students/domain/student_grade_grid.dart` (columnas, parser de notas y builder de filas/promedios)
- Create: `lib/features/students/providers/student_grades_provider.dart` (todas las páginas del endpoint)
- Create: `lib/features/students/screens/widgets/student_grades_grid.dart` (tabla con scroll horizontal)
- Modify: `lib/features/students/screens/widgets/student_related_tabs.dart` (la pestaña Notas usa la grilla)
- Modify: `lib/features/students/screens/student_detail_screen.dart` (`classroomId?`)
- Modify: `lib/app/router.dart` (lee `classroomId` del query)
- Modify: `lib/features/classrooms/screens/widgets/classroom_related_tabs.dart` (abre el alumno con `?classroomId=`)
- Modify: ARB es/en (`gradesGrid*`) + `flutter gen-l10n`
- Delete: `lib/features/students/screens/widgets/qualification_tile.dart` y `studentQualificationsProvider`
- Test: `test/students/student_grade_grid_test.dart` (nuevo), `test/qualifications/qualification_model_test.dart`, `test/students/student_detail_screen_test.dart`, `test/classrooms/classroom_detail_screen_test.dart`

**Interfaces:**
- Produces: `buildGradeGrid(List<QualificationModel>) → List<GradeGridRow>`; `qualificationScoreValue(String?) → double?`; `studentGradesProvider`; `StudentGradesGrid`; `StudentGradesTab.studentId/classroomId/isProfessor`.

- [x] **Step 1:** Modelo + builder + tests unitarios (mapeo por type/category, fallback sin categoría, promedios numéricos/textuales, casos vacíos); `build_runner`.
- [x] **Step 2:** Provider que trae todas las páginas (per_page 100) + grilla con encabezados agrupados, `—` en celdas vacías y promedio verde/rojo; l10n.
- [x] **Step 3:** Aula de origen (`?classroomId=`), secciones por aula sin contexto, limpieza de `QualificationTile`/`studentQualificationsProvider`.
- [x] **Step 4:** Tests de widget (grilla, filtro por aula, secciones, navegación con aula) y verificación: `flutter analyze` 0 errores, `flutter test` 172 en verde.
- [ ] **Step 5:** Commit `feat(students): grilla de notas como la web`.
