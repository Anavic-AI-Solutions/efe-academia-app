# Carga profesor + home con calendario, cumpleaños, novedades y documentos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** El profesor carga notas e inasistencias desde el detalle del alumno y su inicio muestra calendario, cumpleaños, novedades y documentos.

**Architecture:** Reutilizar `CreateQualificationSheet` y `POST /classrooms/{id}/attendance` (merge) para la parte A; extender `EventApi` con `getCalendar`, crear features `documents/` (clon de `news/`) y `birthdays/` mínimo con fallback, y montar 4 secciones aisladas en `ProfessorHomeScreen` con el vocabulario existente.

**Tech Stack:** Flutter 3.24 / Dart 3.5, Riverpod 2 + go_router 14, Dio 5, freezed, flutter_gen-l10n (ES/EN), flutter_test. Única dependencia nueva: `url_launcher`.

**Spec:** `docs/superpowers/specs/2026-10-08-profesor-alumno-carga-home-design.md`

## Global Constraints

- Seguir el patrón por feature: `data/` (API, repository), `domain/` (models freezed), `providers/` (Riverpod), `screens/` + `screens/widgets/`.
- UI solo con vocabulario existente: `AppCard`, `SectionHeader`, `EmptyState`, `ErrorView`, `ListShimmer`, iconos Phosphor, `AppColors`. Sin rediseño fuera del alcance.
- Cada texto visible nuevo lleva clave ARB en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`, luego `flutter gen-l10n`.
- Modelos freezed nuevos requieren `dart run build_runner build --delete-conflicting-outputs`.
- Solo `url_launcher` como dependencia nueva (`flutter pub add url_launcher`); nada más.
- `flutter analyze` debe quedar en 0 issues y `flutter test` en verde.
- El endpoint `GET /api/v1/birthdays` vive en el repo `efe-app` y está FUERA de este plan; el móvil se programa contra su contrato con fallback "próximamente" ante 404/501.
- No tocar `POST /absences` directo ni el flujo de justificaciones.

## Review Focus

- Alumno de profesor sin aulas asignadas ve la acción de nota deshabilitada en vez de un crash → test en Task 1 (`sin aulas deshabilita la acción`).
- Parte del día con otros ausentes: marcar uno nuevo preserva los ausentes existentes → test en Task 2 (`merge preserva ausentes existentes`).
- Fecha futura no se puede elegir en el sheet de inasistencia → test en Task 2 (`fecha futura bloqueada`).
- Una sección del home en error (p. ej. cumpleaños 404) no impide ver las otras tres → test en Task 7 (`sección en error no tumba el home`).
- Documento sin `media` ni `file_url` muestra el tile sin botón de apertura y no rompe → test en Task 5 (`documento sin archivo no rompe`).

---

### Task 1: Cargar nota desde el detalle del alumno

**Files:**
- Modify: `lib/features/students/screens/student_detail_screen.dart:28-90` (pasar `isProfessor` ya calculado a los tabs)
- Modify: `lib/features/students/screens/widgets/student_related_tabs.dart:19-61` (`StudentGradesTab`: nuevos params `canWrite`, `studentFullname`; barra inferior de acción)
- Modify: `lib/features/qualifications/screens/widgets/create_qualification_sheet.dart:20-35` (aula opcional con dropdown + alumno bloqueado con 1 entrada)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/students/professor_student_grade_action_test.dart`

**Interfaces:**
- Consumes: `qualificationRepositoryProvider.createQualification({studentId, classroomId, score, type, period, description})`, `dashboardProvider` (`data.classrooms: List<ProfessorClassroomSummary>` con `id`, `name`), `studentGradesProvider(studentId)`, `classroomGradesProvider(classroomId)`.
- Produces: `StudentGradesTab({studentId, classroomId, canWrite, studentFullname})`; `CreateQualificationSheet({classroomId, classrooms, students, initialStudentId})` donde `classroomId` pasa a ser `String?` y `classrooms` es `List<ProfessorClassroomSummary>?` (obligatorio cuando `classroomId == null`); si `students.length == 1` el dropdown de alumno se muestra deshabilitado.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('sin aulas deshabilita la acción', (tester) async {
  // Profesor, StudentGradesTab canWrite:true, dashboard sin classrooms.
  // Expect: encuentra el botón de cargar nota deshabilitado (onPressed null).
});
testWidgets('guardar invalida los providers de notas', (tester) async {
  // Fake QualificationRepository registra createQualification con
  // studentId 's1', classroomId 'c1', score '8.5', type 'Parcial', period '1'.
  // Expect: fake.createCalls tiene 1 llamada con esos valores exactos.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/students/professor_student_grade_action_test.dart`
Expected: FAIL (no existe `canWrite` ni la barra de acción).

- [ ] **Step 3: Implement `canWrite` + barra inferior en `StudentGradesTab` y resolución de aula en `CreateQualificationSheet`**

Hoja: si `classroomId == null`, dropdown "Aula" con `classrooms` (default primera); si `students.length == 1`, dropdown de alumno deshabilitado. Submit usa el aula resuelta. Llamador construye `students: [ClassroomGradeStudent(studentId: studentId, fullname: studentFullname)]`. Al éxito (`pop(true)`): invalidar `studentGradesProvider(studentId)` y, si hay aula, `classroomGradesProvider(classroomId)`; snackbar `gradeFormSaved`.

- [ ] **Step 4: Add ARB keys `studentGradeFromDetail`, `studentGradeClassroom`, `studentGradeNoClassrooms` (ES/EN) y correr `flutter gen-l10n`**

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/students/professor_student_grade_action_test.dart test/students/student_detail_screen_test.dart`
Expected: PASS (incluye `sin aulas deshabilita la acción` del Review Focus).

- [ ] **Step 6: Commit**

```bash
git add lib/features/students lib/features/qualifications lib/l10n test/students
git commit -m "feat(students): carga de nota por profesor desde el detalle del alumno"
```

### Task 2: Marcar inasistencia con fecha desde el detalle

**Files:**
- Modify: `lib/features/attendance/data/attendance_api.dart:10-11` (agregar `date` opcional a `getAttendance`)
- Modify: `lib/features/attendance/data/attendance_repository.dart:12-19` (propagar `date`)
- Create: `lib/features/students/screens/widgets/mark_absence_sheet.dart`
- Modify: `lib/features/students/screens/widgets/student_related_tabs.dart:115-139` (`StudentAbsencesTab`: nuevos params `classroomId`, `canWrite`; barra inferior de acción)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/students/mark_absence_sheet_test.dart`

**Interfaces:**
- Consumes: `attendanceRepositoryProvider.getAttendance(classroomId, {date})`, `.saveAttendance(classroomId, date:, absentStudentIds:)`, `studentAbsencesProvider(studentId)`, `dashboardProvider` (aulas para dropdown).
- Produces: `AttendanceRepository.getAttendance(String classroomId, {String? date})`; `MarkAbsenceSheet({studentId, classroomId, classrooms})` con misma regla de aula que Task 1; `StudentAbsencesTab({studentId, classroomId, canWrite})`.

- [ ] **Step 1: Write the failing test**

```dart
test('merge preserva ausentes existentes', () async {
  // Fake repository: getAttendance devuelve ausente ['otro'].
  // Acción: marcar 's1' el '2026-10-05'.
  // Expect: saveAttendance llamado con date '2026-10-05'
  // y absentStudentIds contiene 's1' y 'otro'.
});
testWidgets('fecha futura bloqueada', (tester) async {
  // Abre MarkAbsenceSheet. Expect: showDatePicker con lastDate == hoy
  // (mañana no seleccionable).
});
test('alumno ya ausente es idempotente', () async {
  // getAttendance ya incluye 's1'. Expect: save con el mismo set + mensaje
  // de "ya estaba ausente" (clave ARB).
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/students/mark_absence_sheet_test.dart`
Expected: FAIL (`MarkAbsenceSheet` no existe; `getAttendance` no acepta `date`).

- [ ] **Step 3: Implement `date` opcional en `AttendanceApi.getAttendance` + `AttendanceRepository`**

Firma exacta: `Future<Response> getAttendance(String classroomId, {String? date})` enviando `queryParameters: {if (date != null) 'date': date}`; el repositorio propaga igual. Sin fecha, comportamiento actual intacto.

- [ ] **Step 4: Implement `MarkAbsenceSheet` con merge idempotente**

Campos: aula (fija o dropdown) + fecha (`showDatePicker`, `firstDate = hoy-90d`, `lastDate = hoy`, inicial hoy). Confirmar: `getAttendance(classroomId, date: yyyy-MM-dd)` → set ausentes + `studentId` → `saveAttendance` → invalidar `studentAbsencesProvider(studentId)` → snackbar (`absenceMarked` o `absenceAlreadyMarked` si ya estaba).

- [ ] **Step 5: Add ARB keys `absenceMarkTitle`, `absenceMarkClassroom`, `absenceMarkDate`, `absenceMarked`, `absenceAlreadyMarked`, `absenceMarkError` (ES/EN) y `flutter gen-l10n`**

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/students/mark_absence_sheet_test.dart test/attendance/`
Expected: PASS (incluye `merge preserva ausentes existentes` y `fecha futura bloqueada` del Review Focus).

- [ ] **Step 7: Commit**

```bash
git add lib/features/attendance lib/features/students lib/l10n test/students test/attendance
git commit -m "feat(students): inasistencia con fecha por profesor desde el detalle"
```

### Task 3: Calendario en el home (API + modelo + sección)

**Files:**
- Modify: `lib/features/events/data/event_api.dart:8-13` (agregar `getCalendar`)
- Modify: `lib/features/events/domain/event_model.dart:16-26` (parsear `start_date`/`end_date` con fallback)
- Modify: `lib/features/events/data/event_repository.dart:9-26` (agregar `getCalendarEvents`)
- Modify: `lib/features/events/providers/event_provider.dart:103-106` (agregar `homeCalendarProvider`)
- Create: `lib/features/dashboard/screens/widgets/home_calendar_section.dart`
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart:89-154` (montar sección tras los botones)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/events/event_calendar_test.dart`, `test/dashboard/professor_home_calendar_test.dart`

**Interfaces:**
- Consumes: `ApiClient.get` con `queryParameters`.
- Produces: `EventApi.getCalendar({required String startDate, required String endDate})` → `GET /events/calendar`; `EventRepository.getCalendarEvents({startDate, endDate}): Future<List<EventModel>>` (respuesta `{'data': [...]}` sin paginación, orden server); `homeCalendarProvider: FutureProvider.autoDispose<List<EventModel>>` (rango hoy → hoy+30, `take(5)`); `HomeCalendarSection()` (firma sin params; lee el provider; estados shimmer/vacío/error propios con reintento local).

- [ ] **Step 1: Write the failing test**

```dart
test('getCalendarEvents parsea start_date del calendario', () async {
  // Fake ApiClient devuelve {'data': [{'id': 'e1', 'attributes': {
  // 'title': 'Acto', 'start_date': '2026-10-10T09:00:00', 'color': '#FF0000'}}]}.
  // Expect: 1 evento, title 'Acto', start 2026-10-10 09:00.
});
testWidgets('sección muestra 5 y link a eventos', (tester) async {
  // homeCalendarProvider override con 6 eventos.
  // Expect: 5 tiles + botón que hace push a '/events'.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/events/event_calendar_test.dart`
Expected: FAIL (`getCalendar` no existe; `start_date` no se parsea).

- [ ] **Step 3: Implement `getCalendar` + parseo `start_date`/`end_date` con fallback a `start`/`end` en `EventModel.fromJson`**

Sin cambiar el parseo actual cuando las claves viejas vienen presentes (compatibilidad con lista existente; la suite de events debe seguir verde).

- [ ] **Step 4: Implement `EventRepository.getCalendarEvents` + `homeCalendarProvider` (take 5) + `HomeCalendarSection` con `SectionHeader`, `AppCard`, `EmptyState`, `ErrorView` y reintento local**

- [ ] **Step 5: Mount `HomeCalendarSection` en `ProfessorHomeScreen` tras la fila de botones y agregar ARB `homeCalendar`, `homeSeeAll`, `homeCalendarEmpty` (ES/EN) + `flutter gen-l10n`**

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/events/ test/dashboard/professor_home_calendar_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/events lib/features/dashboard lib/l10n test/events test/dashboard
git commit -m "feat(dashboard): seccion calendario en inicio del profesor"
```

### Task 4: Documents — datos y dominio

**Files:**
- Create: `lib/features/documents/domain/document_model.dart` (+ freezed `*.freezed.dart` vía build_runner)
- Create: `lib/features/documents/data/document_api.dart`
- Create: `lib/features/documents/data/document_repository.dart`
- Create: `lib/features/documents/providers/document_provider.dart`
- Test: `test/documents/document_repository_test.dart`

**Interfaces:**
- Consumes: `apiClientProvider.get` (`/documents`, `/documents/{id}`).
- Produces: `DocumentModel{id, title, description, fileUrl, createdAt, mediaUrls: List<String>}` con `fromJson` estilo JsonApi (`attributes` con fallback, `media: [{url}]` o `file_url`); `DocumentApi.getDocuments({cursor, limit = 20})`, `.getDocument(id)`; `DocumentRepository.getDocuments({cursor}) -> CursorPagination<DocumentModel>`, `.getDocument(id)` con `DioException → ApiException`; `documentApiProvider`, `documentRepositoryProvider`, `documentListProvider` (StateNotifier, clon de `newsListProvider`), `homeDocumentsProvider: FutureProvider.autoDispose<List<DocumentModel>>` (primera página, take 5).

- [ ] **Step 1: Write the failing test**

```dart
test('parsea media array y file_url fallback', () {
  // JsonApi con attributes {title 'Reglamento', file_url 'https://f/r.pdf',
  // created_at '2026-09-01T10:00:00', media: [{url 'https://m/a.pdf'}]}.
  // Expect: mediaUrls ['https://m/a.pdf'], fileUrl 'https://f/r.pdf'.
});
test('sin media ni file_url queda vacío', () {
  // attributes sin media ni file_url. Expect: mediaUrls [] y fileUrl ''.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/documents/document_repository_test.dart`
Expected: FAIL (feature no existe).

- [ ] **Step 3: Implement `DocumentModel` (freezed) + `DocumentApi` + `DocumentRepository` + providers**

Repositorio clona el mapeo cursor-paginado de `NewsRepository`. Luego `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/documents/document_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/documents test/documents
git commit -m "feat(documents): modelo, api, repositorio y providers solo lectura"
```

### Task 5: Documents — UI, ruta y sección del home

**Files:**
- Create: `lib/features/documents/screens/widgets/document_tile.dart`
- Create: `lib/features/documents/screens/document_list_screen.dart`
- Create: `lib/features/documents/screens/document_detail_screen.dart`
- Modify: `lib/app/router.dart:319-334` (agregar `/documents` + `/documents/:id` junto a `/news`)
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart` (montar `HomeDocumentsSection`)
- Create: `lib/features/dashboard/screens/widgets/home_documents_section.dart`
- Modify: `pubspec.yaml:9-31` (agregar `url_launcher`), `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/documents/document_list_screen_test.dart`

**Interfaces:**
- Consumes: `documentListProvider`, `homeDocumentsProvider`, `DocumentModel` de Task 4.
- Produces: `DocumentTile({document, onTap})` (sin botón de apertura cuando `mediaUrls` vacío y `fileUrl` vacío); `DocumentListScreen()` (clon de `NewsListScreen`: shimmer/vacío/error/infinito); `DocumentDetailScreen({documentId})` (título, descripción, fecha `d/m/Y`, botón Abrir/Descargar vía `url_launcher` a `mediaUrls.firstOrNull ?? fileUrl`, fallback a `GET /documents/{id}/download`); ruta `/documents`; `HomeDocumentsSection()` (take 5 + "Ver todo" → `/documents`).

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('documento sin archivo no rompe', (tester) async {
  // DocumentModel con mediaUrls [] y fileUrl ''.
  // Expect: el tile se renderiza y no hay botón de apertura.
});
testWidgets('lista muestra documentos y navega al detalle', (tester) async {
  // documentListProvider override con 2 documentos.
  // Expect: 2 tiles; tap navega a DocumentDetailScreen.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/documents/document_list_screen_test.dart`
Expected: FAIL (pantallas no existen).

- [ ] **Step 3: Run `flutter pub add url_launcher` y verificar en `pubspec.yaml`**

- [ ] **Step 4: Implement tile + lista + detalle + ruta `/documents` + `HomeDocumentsSection` y montarla en `ProfessorHomeScreen`**

Apertura externa con `launchUrl(uri, mode: externalApplication)`; error de apertura → snackbar (clave ARB).

- [ ] **Step 5: Add ARB keys `documentsTitle`, `documentsEmpty`, `documentsOpen`, `documentsOpenError`, `homeDocuments` (ES/EN) + `flutter gen-l10n`**

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/documents/ test/dashboard/`
Expected: PASS (incluye `documento sin archivo no rompe` del Review Focus).

- [ ] **Step 7: Commit**

```bash
git add lib/features/documents lib/app/router.dart lib/features/dashboard lib/l10n pubspec.yaml test/documents
git commit -m "feat(documents): lista, detalle, ruta y seccion en inicio solo lectura"
```

### Task 6: Novedades en el home

**Files:**
- Create: `lib/features/dashboard/screens/widgets/home_news_section.dart`
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart` (montar tras calendario)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/dashboard/professor_home_news_test.dart`

**Interfaces:**
- Consumes: `newsListProvider` (`pagination.data: List<NewsModel>` con `title`, `content`, `createdAt`).
- Produces: `HomeNewsSection()` (take 3 primeros, card compacta título + 2 líneas + fecha, "Ver todo" → `/news`, estados propios).

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('muestra hasta 3 novedades con ver todo', (tester) async {
  // newsListProvider override con 5 items. Expect: 3 cards + botón '/news'.
});
testWidgets('sin novedades muestra vacío', (tester) async {
  // Override con lista vacía. Expect: EmptyState, sin crash.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dashboard/professor_home_news_test.dart`
Expected: FAIL (`HomeNewsSection` no existe).

- [ ] **Step 3: Implement `HomeNewsSection` + montaje + ARB `homeNews`, `homeNewsEmpty` (ES/EN) + `flutter gen-l10n`**

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/dashboard/professor_home_news_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard lib/l10n test/dashboard
git commit -m "feat(dashboard): seccion novedades en inicio del profesor"
```

### Task 7: Cumpleaños en el home y aislamiento de secciones

**Files:**
- Create: `lib/features/birthdays/domain/birthday_model.dart` (+ freezed vía build_runner)
- Create: `lib/features/birthdays/data/birthday_api.dart`
- Create: `lib/features/birthdays/providers/birthday_provider.dart`
- Create: `lib/features/dashboard/screens/widgets/home_birthdays_section.dart`
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart` (montar tras novedades; orden final: calendario → cumpleaños → novedades → documentos)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Test: `test/birthdays/birthday_provider_test.dart`, `test/dashboard/professor_home_sections_test.dart`

**Interfaces:**
- Consumes: `apiClientProvider.get` (`/birthdays?scope=today`).
- Produces: `BirthdayModel{id, name, ageTurning, studentAppId, birthDate, daysUntil}`; `BirthdayApi.getTodayBirthdays(): Future<Response>`; `todayBirthdaysProvider: FutureProvider.autoDispose<List<BirthdayModel>>` (ante 404/501 devuelve `[]` con flag de no disponible, NO propaga error rojo); `HomeBirthdaysSection()` (avatar + nombre + edad; vacío normal con `EmptyState` pastel; tap con `studentAppId` → `/students/{id}`).

- [ ] **Step 1: Write the failing test**

```dart
test('404 de cumpleaños devuelve lista vacía disponible=false', () async {
  // Fake ApiClient lanza DioException 404.
  // Expect: provider entrega [] y el widget muestra "próximamente".
});
testWidgets('sección en error no tumba el home', (tester) async {
  // todayBirthdaysProvider override con error; calendario/novedades/documentos ok.
  // Expect: las otras 3 secciones visibles + cumpleaños en fallback.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/birthdays/birthday_provider_test.dart test/dashboard/professor_home_sections_test.dart`
Expected: FAIL (feature no existe).

- [ ] **Step 3: Implement modelo (freezed) + API + provider con fallback 404/501 + widget + montaje en orden final + ARB `homeBirthdays`, `homeBirthdaysEmpty`, `homeBirthdaysSoon` (ES/EN) + `flutter gen-l10n` + build_runner**

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/birthdays/ test/dashboard/`
Expected: PASS (incluye `sección en error no tumba el home` del Review Focus).

- [ ] **Step 5: Commit**

```bash
git add lib/features/birthdays lib/features/dashboard lib/l10n test/birthdays test/dashboard
git commit -m "feat(dashboard): cumpleanos en inicio con fallback sin backend"
```

### Task 8: Verificación final

**Files:** ninguno nuevo (solo fixes si aparecen).

- [ ] **Step 1: Run `flutter gen-l10n` y `flutter analyze`**

Run: `flutter gen-l10n && flutter analyze`
Expected: 0 issues.

- [ ] **Step 2: Run la suite completa**

Run: `flutter test`
Expected: PASS en verde (incluye suites nuevas y las existentes de events, attendance, dashboard, students sin regresiones).
