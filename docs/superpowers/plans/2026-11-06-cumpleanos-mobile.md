# Cumpleaños mobile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Exponer `GET /api/v1/birthdays` y hacer que la sección Cumpleaños del mobile muestre hoy + próximos 30 días, filtrado por rol, como la web.

**Architecture:** Un `BirthdayService` backend compartido entre el controlador web y un controlador API JSON. En mobile, un provider `upcomingBirthdaysProvider` consume el nuevo endpoint; la pantalla agrupa hoy/próximos y el home sigue usando `scope=today`.

**Tech Stack:** Laravel 12 + Pest (backend), Flutter 3.44 + Riverpod + GoRouter (mobile), PostgreSQL/SQLite.

**Spec:** `docs/superpowers/specs/2026-11-06-cumpleanos-mobile-design.md`

## Global Constraints

- Endpoint autenticado: `GET /api/v1/birthdays?scope=today|upcoming&days=30`.
- `scope=upcoming` por defecto; ventana de 30 días; incluye hoy y cruza diciembre→enero.
- Solo `SystemStudents` activos.
- Filtro por rol: admin todos, branch por `StudentData.branch`, professor por aulas propias, parent por hijos vinculados, student solo el propio, desconocido vacío.
- Respuesta `{ "data": [{ id, name, birth_date, days_until, age_turning, student_app_id }] }`.
- `birth_date` ISO `Y-m-d` en la API; la web conserva `d/m/Y`.
- Sin paginación.
- Mobile: sección `/birthdays` con “Cumpleaños de hoy” y “Próximos 30 días”.
- Home: `todayBirthdaysProvider` sigue usando `scope=today`.

## Review Focus

- Alumno sin `student_app_id`: debe mostrarse sin navegación, no romper.
- Fecha de nacimiento en enero vista desde diciembre: debe aparecer en la ventana.
- Alumno inactivo: no debe aparecer.
- Padre con varios hijos: deben aparecer todos los que cumplan, no solo el seleccionado.
- Profesor sin aulas / padre sin hijos: lista vacía, no error.

---

### Task 1: Backend BirthdayService + endpoint API

**Files:**
- Create: `app/Services/BirthdayService.php`
- Create: `app/Http/Controllers/Api/Birthdays/BirthdayController.php`
- Modify: `routes/api.php`
- Test: `tests/Feature/Api/BirthdaysTest.php`

**Interfaces:**
- Produces: `BirthdayService::forUser(User $user, string $scope = 'upcoming', int $days = 30): \Illuminate\Support\Collection`
- Produces: `GET /api/v1/birthdays` → `{data: Birthday[]}`

- [ ] **Step 1: Write failing Pest tests** covering admin window (in/out/inactive), `scope=today`, parent multi-child, professor own classrooms, student own, unknown empty, year wrap, and response shape.
- [ ] **Step 2: Run** `docker run --rm -v /opt/dev/efe-app/.worktrees/feat-menu-secciones:/app -w /app composer:2 php vendor/bin/pest --filter BirthdaysTest` → FAIL.
- [ ] **Step 3: Implement `BirthdayService`** with role scoping and driver-aware `MM-DD` filtering (`TO_CHAR`/`strftime`), mapping and sorting by `days_until`.
- [ ] **Step 4: Implement API controller + route.**
- [ ] **Step 5: Run tests** → PASS; run `php -l` on new files.
- [ ] **Step 6: Commit.**

### Task 2: Web controller uses BirthdayService

**Files:**
- Modify: `app/Http/Controllers/BirthdaysController.php`

**Interfaces:**
- Consumes: `BirthdayService::forUser(...)` from Task 1.
- Produces: same Inertia props (`birthdays`, `daysAhead`) with `birth_date` formatted `d/m/Y` and `birth_date_sort`.

- [ ] **Step 1: Replace query logic** with the service and map the web-only fields.
- [ ] **Step 2: Verify** `php -l app/Http/Controllers/BirthdaysController.php` and run `pest --filter BirthdaysTest`.
- [ ] **Step 3: Commit.**

### Task 3: Mobile API + upcoming provider

**Files:**
- Modify: `lib/features/birthdays/data/birthday_api.dart`
- Modify: `lib/features/birthdays/providers/birthday_provider.dart`
- Test: `test/birthdays/birthday_provider_test.dart`

**Interfaces:**
- Produces: `BirthdayApi.getBirthdays({String scope = 'upcoming', int days = 30})`
- Produces: `upcomingBirthdaysProvider: FutureProvider.autoDispose<List<BirthdayModel>>`
- Keeps: `todayBirthdaysProvider`, `birthdaysAvailableProvider`

- [ ] **Step 1: Add failing tests** for `scope=upcoming`, `days=30`, parse of `birth_date`, and 404 fallback.
- [ ] **Step 2: Run** `flutter test test/birthdays/birthday_provider_test.dart` → FAIL.
- [ ] **Step 3: Implement** `getBirthdays` + shared fallback helper + `upcomingBirthdaysProvider`; keep `getTodayBirthdays()` delegating to `scope=today`.
- [ ] **Step 4: Run tests** → PASS.
- [ ] **Step 5: Commit.**

### Task 4: BirthdayListScreen today + upcoming

**Files:**
- Modify: `lib/features/birthdays/screens/birthday_list_screen.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations*.dart`
- Test: `test/birthdays/birthday_list_screen_test.dart`

**Interfaces:**
- Consumes: `upcomingBirthdaysProvider` from Task 3.
- Produces: sections “Cumpleaños de hoy” / “Próximos 30 días”; cards with date, age, days text; tap to `/students/{id}`.

- [ ] **Step 1: Add failing widget tests** for grouping, “Hoy/Mañana/En X días”, empty upcoming, fallback, and navigation.
- [ ] **Step 2: Run** `flutter test test/birthdays/birthday_list_screen_test.dart` → FAIL.
- [ ] **Step 3: Add l10n keys** ES/EN and run `flutter gen-l10n`.
- [ ] **Step 4: Implement the sections/cards** and date formatting (`DateFormat('d/M')`).
- [ ] **Step 5: Run tests** → PASS.
- [ ] **Step 6: Commit.**

### Task 5: Full verification + push

**Files:** none new.

- [ ] **Step 1:** `flutter analyze --no-fatal-infos` → 0 errors/warnings.
- [ ] **Step 2:** `flutter test` → all pass.
- [ ] **Step 3:** Linux release build in Docker → `✓ Built`.
- [ ] **Step 4:** Backend `pest --filter BirthdaysTest` → pass; `php -l` new/changed files.
- [ ] **Step 5:** Commit mobile, merge to `master`, push; commit backend, merge to `preprod`, push.
