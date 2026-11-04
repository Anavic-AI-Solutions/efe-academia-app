# Menú Mobile y Secciones Nuevas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar un quinto ítem Menú al bottom nav y las pantallas nativas Historial, Biblioteca, FAQ y Estadísticas, filtradas por rol.

**Architecture:** `/menu` será un quinto `StatefulShellBranch`; las secciones nuevas serán rutas top-level apiladas. Historial reutiliza `ClassroomListNotifier` con estado archivado; Biblioteca, FAQ y Estadísticas usan features Riverpod propias sobre endpoints REST existentes. El único cambio de backend es el scoping por rol/alumno en `ClassroomController@index`.

**Tech Stack:** Flutter 3.44, Riverpod 2, go_router 14, Freezed, Dio, url_launcher, intl, Phosphor, Laravel 11 + Pest.

**Spec:** Diseño aprobado en la conversación del 2026-11-04 (12 secciones, matriz de roles web, mobile-first funcional, cambio mínimo de backend).

## Global Constraints

- Mostrar exactamente 12 secciones; no agregar Alumnos, Profesores, Padres, Solicitudes, Reinscripciones, Avisos, Soporte ni Sistema.
- Sin WebView; todo Flutter nativo.
- Notificaciones y Cuotas solo alumno/padre; Cumpleaños admin/sede/profesor/padre; el resto para todos.
- No hay endpoints nuevos para Biblioteca, FAQ ni Estadísticas.
- Backend: solo `ClassroomController@index` y su test.
- No usar Pest en `efe-app` salvo pedido explícito de AGENTS.md; verificar PHP con `php -l` y `pint`.
- Verificación móvil: `flutter gen-l10n`, `flutter analyze --no-fatal-infos`, `flutter test`.

## Review Focus

- Un usuario sin rol conocido no debe ver Notificaciones, Cuotas ni Cumpleaños.
- Un padre con varios hijos debe ver solo el historial del hijo seleccionado.
- Un alumno/padre no debe poder listar aulas archivadas de otro alumno manipulando `student_id`.
- Biblioteca con `public_url` vacío debe avisar, no abrir una URL inválida.
- Estadísticas con `metrics`/`details` vacíos o con claves ausentes debe mostrar vacío/error, no crashear.

---

### Task 1: Backend scoping de aulas por rol

**Files:**
- Modify: `app/Http/Controllers/Api/Classrooms/ClassroomController.php`
- Test: `tests/Feature/Api/ClassroomsTest.php`

**Interfaces:**
- Consumes: `ClassroomResource`, `Classrooms`, `StudentData`, `ParentData`.
- Produces: `scopeToRole(Request $request, $query): void` aplicado en `index()` y `filters()`.

- [ ] **Step 1: Escribir tests de scoping**

Agregar tests para: alumno ve solo sus aulas; padre ve solo las de sus hijos; padre no ve aulas de otro hijo; admin sigue viendo todo; profesor sigue viendo solo las suyas. Usar `status=archived` en al menos uno.

- [ ] **Step 2: Correr y ver fallar**

Run: `php artisan test --filter=classroom` (solo si el entorno lo permite; AGENTS.md prohíbe la suite completa).
Expected: FAIL en los nuevos casos.

- [ ] **Step 3: Implementar `scopeToRole`**

Reemplazar `scopeToProfessor` por `scopeToRole`, con precedencia admin/sede → profesor → padre → alumno. Para padre, validar el vínculo con `student_id` (id de `student_data` o `user_id` del hijo); si no viene, usar `current_selected_id`; si tampoco, todos sus hijos. Alumno: solo su `studentData`.

- [ ] **Step 4: Verificar sintaxis y estilo**

Run: `php -l app/Http/Controllers/Api/Classrooms/ClassroomController.php` y `vendor/bin/pint --dirty`.
Expected: sin errores.

### Task 2: Bottom nav, rutas y pantalla Menú

**Files:**
- Modify: `lib/app/router.dart`
- Create: `lib/features/menu/domain/menu_entry.dart`
- Create: `lib/features/menu/screens/menu_screen.dart`
- Create: `lib/features/menu/screens/widgets/menu_tile.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/app/bottom_nav_test.dart`
- Test: `test/features/menu/menu_screen_test.dart`

**Interfaces:**
- Produces: `MenuEntry`, `MenuGroup`, `MenuScreen`, `menuEntriesForRole(String role)`; rutas `/menu`, `/history`, `/library`, `/faqs`, `/statistics`.

- [ ] **Step 1: Test de bottom nav con 5 destinos y apertura de Menú**
- [ ] **Step 2: Test de matriz de roles del menú**
- [ ] **Step 3: Implementar `MenuEntry` y `menuEntriesForRole`**
- [ ] **Step 4: Implementar `MenuScreen` con grupos y navegación**
- [ ] **Step 5: Agregar el quinto branch `/menu` y las rutas top-level**
- [ ] **Step 6: Agregar textos ES/EN y regenerar l10n**
- [ ] **Step 7: Correr tests del menú y analizar**

### Task 3: Historial de cursos archivados

**Files:**
- Modify: `lib/features/classrooms/providers/classroom_provider.dart`
- Create: `lib/features/classrooms/screens/classroom_history_screen.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/classrooms/classroom_history_test.dart`

**Interfaces:**
- Consumes: `ClassroomRepository.getClassrooms(status: 'archived', studentId: ...)`.
- Produces: `classroomHistoryProvider` (`StateNotifierProvider<ClassroomListNotifier, ClassroomListState>`), `ClassroomHistoryScreen`.

- [ ] **Step 1: Test de provider con estado archivado y búsqueda**
- [ ] **Step 2: Test de selector de hijo para padre**
- [ ] **Step 3: Permitir estado inicial en `ClassroomListNotifier`**
- [ ] **Step 4: Crear `classroomHistoryProvider` y la pantalla**
- [ ] **Step 5: Conectar la ruta `/history` y el menú**
- [ ] **Step 6: Correr tests y analizar**

### Task 4: Biblioteca global de materiales

**Files:**
- Create: `lib/features/library/data/library_api.dart`
- Create: `lib/features/library/data/library_repository.dart`
- Create: `lib/features/library/providers/library_provider.dart`
- Create: `lib/features/library/screens/library_screen.dart`
- Modify: `lib/features/classrooms/screens/widgets/material_tile.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/library/library_repository_test.dart`
- Test: `test/library/library_screen_test.dart`

**Interfaces:**
- Consumes: `GET /materials?search=&cursor=&per_page=`.
- Produces: `LibraryApi.getMaterials`, `LibraryRepository.getMaterials`, `libraryProvider`, `LibraryScreen`.

- [ ] **Step 1: Test de repositorio con paginación por cursor y búsqueda**
- [ ] **Step 2: Test de pantalla con resultado, vacío y error**
- [ ] **Step 3: Implementar API/repositorio/notifier**
- [ ] **Step 4: Implementar pantalla con búsqueda, scroll infinito y apertura externa**
- [ ] **Step 5: Agregar callback opcional a `MaterialTile`**
- [ ] **Step 6: Conectar ruta y menú; correr tests y analizar**

### Task 5: FAQ con acordeón y búsqueda

**Files:**
- Create: `lib/features/faqs/domain/faq_model.dart`
- Create: `lib/features/faqs/data/faq_api.dart`
- Create: `lib/features/faqs/data/faq_repository.dart`
- Create: `lib/features/faqs/providers/faq_provider.dart`
- Create: `lib/features/faqs/screens/faq_screen.dart`
- Create: `lib/features/faqs/screens/widgets/faq_tile.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/faqs/faq_repository_test.dart`
- Test: `test/faqs/faq_screen_test.dart`

**Interfaces:**
- Consumes: `GET /faqs?search=&page=&per_page=`.
- Produces: `FaqModel`, `FaqApi.getFaqs`, `FaqRepository.getFaqs`, `faqListProvider`, `FaqScreen`.

- [ ] **Step 1: Test de modelo/repositorio con búsqueda y paginación**
- [ ] **Step 2: Test de acordeón y vacío**
- [ ] **Step 3: Implementar modelo, API, repositorio y notifier**
- [ ] **Step 4: Implementar pantalla y tile**
- [ ] **Step 5: Conectar ruta y menú; correr tests y analizar**

### Task 6: Estadísticas por rol

**Files:**
- Create: `lib/features/statistics/domain/statistics_model.dart`
- Create: `lib/features/statistics/data/statistics_api.dart`
- Create: `lib/features/statistics/data/statistics_repository.dart`
- Create: `lib/features/statistics/providers/statistics_provider.dart`
- Create: `lib/features/statistics/screens/statistics_screen.dart`
- Create: `lib/features/statistics/screens/widgets/stat_kpi_card.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/statistics/statistics_repository_test.dart`
- Test: `test/statistics/statistics_screen_test.dart`

**Interfaces:**
- Consumes: `GET /statistics/dashboard`.
- Produces: `StatisticsModel`, `StatisticsApi.getDashboard`, `StatisticsRepository.getDashboard`, `statisticsDashboardProvider`, `StatisticsScreen`.

- [ ] **Step 1: Test de parseo de metrics/details por rol**
- [ ] **Step 2: Test de KPIs admin y lista de profesor/padre/alumno**
- [ ] **Step 3: Implementar modelo, API, repositorio y provider**
- [ ] **Step 4: Implementar pantalla con KPI grid, listas y estados**
- [ ] **Step 5: Conectar ruta y menú; correr tests y analizar**

### Task 7: Verificación integral

**Files:**
- Modify: `test/app/bottom_nav_test.dart` si hace falta.
- Test: suite móvil.

- [ ] **Step 1: Correr `flutter gen-l10n`**
- [ ] **Step 2: Correr `flutter analyze --no-fatal-infos`**
- [ ] **Step 3: Correr `flutter test`**
- [ ] **Step 4: Revisar diff completo y confirmar que no se agregaron secciones fuera de las 12**
