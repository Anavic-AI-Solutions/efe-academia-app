# Clases: paginación numerada y detalle ampliado — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el scroll infinito de la lista de clases por paginación numerada fija al pie y ampliar la vista de clase individual con hero, tabs y listas relacionadas paginadas (estudiantes, profesores, materiales).

**Architecture:** El backend Laravel (`efe-app`) pagina por `page`/`per_page` (trait `CursorPagination` sobre `paginate()`), con `meta.total`; no requiere cambios de servidor. En el móvil se agrega `PageResult<T>` + un `PagedListNotifier<T>` genérico, un widget `PaginationBar` reutilizable y se reescribe la pantalla de detalle con `DefaultTabController` + `TabBarView`, reutilizando tokens y widgets existentes.

**Tech Stack:** Flutter 3.x, Riverpod 2 (StateNotifier), Freezed, Dio, go_router, phosphor_flutter, ARB + `flutter gen-l10n`.

**Spec:** Decisión del usuario en sesión: (1) rediseño + tabs con datos relacionados, (2) barra numerada fija al pie, (3) misma paginación en cada tab. Materiales v1 solo informativa (abrir `public_url` queda fuera; requeriría `url_launcher`).

## Global Constraints

- No tocar el backend; usar `page` + `per_page` existentes.
- No romper el scroll infinito de otras features (students/events/news/fees quedan igual).
- Reutilizar tokens (`AppColors`, `AppTypography`) y widgets (`AppCard`, `StatCard`, `AppAvatar`, `EmptyState`, `ErrorView`, `ListShimmer`); no inventar lenguaje visual.
- i18n en `app_es.arb` (template) y `app_en.arb`; regenerar con `/opt/flutter/bin/flutter gen-l10n`.
- Verificación: `/opt/flutter/bin/flutter analyze` y `/opt/flutter/bin/flutter test`.
- Codegen Freezed: `/opt/flutter/bin/dart run build_runner build --delete-conflicting-outputs`.
- Commits convencionales, solo archivos propios de cada tarea.

---

### Tarea 1: Core paginación por página

**Files:**
- Create: `lib/core/api/page_pagination.dart`
- Create: `lib/core/pagination/paged_list_notifier.dart`
- Test: `test/core/page_result_test.dart`, `test/core/paged_list_notifier_test.dart`

**Interfaces:**
- `PageResult<T>({data, page, perPage, total})`, `totalPages`, `hasPrev`, `hasNext`, `PageResult.empty({perPage})`
- `PagedListState<T>({page, isLoading, error})`
- `PagedListNotifier<T>(PageFetcher<T> fetch)` con `load({page})`, `refresh()`, `goToPage(page)`; ignora respuestas obsoletas vía `_requestId`; si `data.isEmpty && page > 1 && total > 0` reintenta página 1.

- [ ] Tests primero (fallan), luego implementación, `flutter test test/core`, commit `feat(core): add page-based pagination primitives`.

### Tarea 2: API/Repo de clases por página

**Files:** `lib/features/classrooms/data/classroom_api.dart`, `classroom_repository.dart`, `test/classrooms/classroom_repository_test.dart`.

- `getClassrooms({search, page, limit, branch, level, year, status})` envía `page`; repo devuelve `PageResult<ClassroomModel>` usando `meta.total` y `limit` solicitado.
- Commit `feat(classrooms): page-based list in api and repository`.

### Tarea 3: Provider de lista por página

**Files:** `lib/features/classrooms/providers/classroom_provider.dart`, `test/classrooms/classroom_list_notifier_test.dart`.

- `ClassroomListState.page`; `goToPage`; sin `loadMore`; search/filtros vuelven a página 1.
- Commit `feat(classrooms): page state and goToPage in list notifier`.

### Tarea 4: i18n

**Files:** `lib/l10n/app_es.arb`, `app_en.arb` + `flutter gen-l10n`.

- Claves: `classroomsPaginationShowing/Previous/Next/Page`, `classroomsTabSummary/Students/Professors/Materials`, `classroomsSectionSchedule/Academic/Location`, `classroomsGrade/Book/Commission/CourseDays`, `classroomsNoStudents/NoProfessors/NoMaterials`, `classroomsRelatedLoadError`, `classroomsMaterialDownloads`.
- Commit `feat(i18n): add classrooms pagination and detail strings`.

### Tarea 5: PaginationBar

**Files:** `lib/core/widgets/pagination_bar.dart`, `test/core/pagination_bar_test.dart`.

- `List<int?> pageWindow({current, totalPages, maxSlots = 5})` con elipsis; widget con prev/next, números, caption "Mostrando X–Y de Z", Semantics, deshabilitados, oculto si `totalPages <= 1`.
- Commit `feat(core): add numbered pagination bar widget`.

### Tarea 6: Lista sin scroll infinito

**Files:** `lib/features/classrooms/screens/classroom_list_screen.dart`, `test/classrooms/classroom_list_screen_test.dart`.

- Quitar listener/`loadMore`/ítem spinner; `PaginationBar` fijo bajo el listado; pull-to-refresh; `goToPage` + scroll al tope; `LinearProgressIndicator` al cambiar de página.
- Commit `feat(classrooms): replace infinite scroll with numbered pagination`.

### Tarea 7: Modelo de clase ampliado

**Files:** `lib/features/classrooms/domain/classroom_model.dart` (+freezed), `test/classrooms/classroom_model_test.dart`.

- Campos `grade/book/commission/courseDays/period1Days..3Days/isActive`; `studentCount` desde `relationships.students.data.length` con fallback `student_count`.
- Commit `feat(classrooms): parse extended classroom fields and student count`.

### Tarea 8: Modelos Professor y Material

**Files:** `lib/features/classrooms/domain/professor_model.dart`, `material_model.dart` (+freezed) y tests.

- Commit `feat(classrooms): add professor and material models`.

### Tarea 9: API/Repo de relacionados

**Files:** `classroom_api.dart`, `classroom_repository.dart`, tests.

- `getClassroomStudents/Professors/Materials(id, {page, limit})` → `PageResult<...>`; estudiantes reutiliza `StudentModel`.
- Commit `feat(classrooms): related lists api and repository`.

### Tarea 10: Providers de relacionados

**Files:** `classroom_provider.dart`.

- `classroomStudentsProvider`, `classroomProfessorsProvider`, `classroomMaterialsProvider` (family por id) sobre `PagedListNotifier<T>`.
- Commit `feat(classrooms): related paged providers`.

### Tarea 11: Detalle — hero + tabs + Resumen

**Files:** `widgets/classroom_detail_header.dart`, `widgets/classroom_summary_tab.dart`, `classroom_detail_screen.dart`, `test/classrooms/classroom_detail_screen_test.dart`.

- Hero con gradiente existente, nombre, badge de estado, chips; `TabBar` scrollable 4 tabs; Resumen con `StatCard` y secciones Horario/Académico/Ubicación/Descripción; estados loading/error.
- Commit `feat(classrooms): redesign detail with hero header and summary tab`.

### Tarea 12: Detalle — tabs relacionadas

**Files:** `widgets/paged_tab_list.dart`, `widgets/student_tile.dart`, `professor_tile.dart`, `material_tile.dart`, detalle y tests.

- `PagedTabList<T>` centraliza shimmer/vacío/error/lista/pager; estudiante navega a `/students/{id}`; materiales informativos.
- Commit `feat(classrooms): add paginated related tabs to detail`.

### Tarea 13: Verificación final

- `/opt/flutter/bin/flutter analyze` sin issues nuevos; `/opt/flutter/bin/flutter test` completo; smoke visual opcional.
