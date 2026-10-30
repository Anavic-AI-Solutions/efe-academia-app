# Carga profesor en detalle alumno + home con calendario, cumpleaños, novedades y documentos — Diseño

**Fecha:** 2026-10-08
**Repos:** `efe_mobile` (Flutter 3.x, Riverpod 2, go_router 14) y `efe-app` (Laravel 11, API `/api/v1`)

## 1. Contexto

Dos pedidos del rol profesor en EFE Mobile:

1. El detalle del alumno es de solo lectura. `StudentDetailScreen` (`lib/features/students/screens/student_detail_screen.dart:18`) muestra tabs Notas / Inasistencias / Cuotas / Info sin acciones. Ya calcula `isProfessor` (`:33`) pero no lo usa. El `classroomId` llega como query-param opcional (`lib/app/router.dart:310`), solo presente cuando se navega desde un aula.
2. El inicio del profesor (`ProfessorHomeScreen` en `lib/features/dashboard/screens/professor_home_screen.dart:20`) solo muestra header + stats + aulas + 2 botones (Tomar asistencia, Cargar nota). Faltan las 4 secciones pedidas: calendario, cumpleaños, novedades y documentos.

Hallazgos verificados:

- Cargar nota a nivel curso ya existe: `POST /qualifications` + `QualificationApi.createQualification` (`lib/features/qualifications/data/qualification_api.dart:31`) + `CreateQualificationSheet` con `initialStudentId` (`lib/features/qualifications/screens/widgets/create_qualification_sheet.dart:20`).
- Inasistencia tiene dos endpoints backend: `POST /classrooms/{id}/attendance` con `date + absent_student_ids` (`ClassroomAttendanceController:106`, ya usado por `AttendanceApi`) y `POST /absences` que exige `student_id + professor_id + classroom_id + date` (`StoreAbsenceRequest:14`). El móvil no tiene `professor_id` a mano en `UserModel`.
- Calendario: `GET /api/v1/events/calendar?start_date&end_date` existe (`Api/Events/EventController.php:56`). El móvil solo tiene `getEvents` cursor-paginado.
- Novedades: `GET /api/v1/news` existe. La web muestra últimas 3 (`PagesViewsController.php:32`).
- Documentos: `GET /api/v1/documents` cursor-paginado + `show` + `download` existen (`Api/Documents/DocumentController.php:21`), campos `title, description, file_url, created_at, updated_at, media[].url`. La web muestra últimos 5 (`PagesViewsController.php:52`). El móvil no tiene el feature. Pedido: solo lectura, es una sección.
- Cumpleaños: sin endpoint API. Solo web Inertia: `todayBirthdays` filtrado por profesor a alumnos de sus aulas (`PagesViewsController.php:104`) y próximos 30 días (`BirthdaysController.php:13`). `StudentResource` no expone `birth_date`; el móvil no puede calcularlo localmente.
- Patrones propios a reutilizar: `CreateQualificationSheet` (bottom sheet con validación y `pop(true)`), `_LoadGradeBar` / `_SaveBar` (barra inferior de acción), `AppCard` + `SectionHeader`, `EmptyState` + `ErrorView` + `ListShimmer`, `PagedTabList` + `PagedListNotifier`, `ApiException`, `RefreshIndicator` en home.

## 2. Objetivo

- **Parte A:** un profesor puede cargar una nota y marcar una inasistencia con fecha desde el detalle de un alumno, con aula fija cuando viene de un aula y dropdown de sus aulas cuando viene de `/students`.
- **Parte B:** el inicio del profesor suma calendario (próximos eventos), cumpleaños de hoy, novedades (últimas 3) y documentos (últimos 5, solo lectura), con deep-links a `/events`, `/news` y `/documents`, sin romper el home actual si un origen falla o aún no existe.

## 3. Alcance y no-objetivos

**Dentro del alcance**

- Acciones de profesor en `StudentGradesTab` y `StudentAbsencesTab` (gating por `isProfessor`), reutilizando `CreateQualificationSheet` y `AttendanceApi`.
- Extensión móvil `EventApi.getCalendar` y widgets de home para calendario + novedades (reusando providers existentes).
- Feature móvil `documents/` nuevo solo lectura (api, repositorio, modelo, providers, lista, detalle mínimo/apertura externa, widget de home, ruta).
- Feature móvil `birthdays/` (modelo, api, provider, widget) contra contrato backend nuevo, con fallback vacío.
- Contrato backend `GET /api/v1/birthdays` en `efe-app` (mismo filtro profesor que la web).
- Textos ARB es/en + tests móvil.

**Fuera del alcance (explícito)**

- Editar/eliminar notas o inasistencias desde el detalle (solo crear; la edición sigue en pantallas de curso).
- Justificar inasistencias desde el detalle (flujo existente de justificaciones no se toca).
- Subir/crear/editar/borrar documentos desde la app (documentos es solo lectura).
- Biblioteca de aula (`/library`), upload de materiales, notificaciones por estas acciones.
- Cambios al panel web salvo el endpoint de cumpleaños.

## 4. Parte A — Cargar nota desde el detalle

### 4.1 Entrada

- En `StudentGradesTab`, si `isProfessor`: barra inferior de acción "Cargar nota" dentro del tab (mismo patrón `_LoadGradeBar` de Notas, no FAB global para no chocar con los 4 tabs).
- Abre `CreateQualificationSheet` con `classroomId` resuelto + `initialStudentId = studentId` y el selector de alumno bloqueado/oculto (un solo alumno).
- Resolución de aula: si `classroomId != null` se usa fijo; si es `null` el sheet muestra dropdown "Aula" con `dashboardProvider.classrooms` (aulas del profesor). Sin aulas, el botón se deshabilita con tooltip.
- Tipos/períodos/score se mantienen (`Parcial|Oral`, `1|2|3`, 0–10, default período académico actual).

### 4.2 Flujo

- Guardar → `POST /qualifications` (existente) → `pop(true)` → `invalidate(studentGradesProvider(studentId))` + `invalidate(classroomGradesProvider(classroomId))` cuando hay aula → snackbar "Nota cargada".
- Error de red/validación 422/403 → mensaje inline al pie del sheet (patrón actual), sin cerrar.
- Permisos UI: solo `isProfessor`. El backend (`QualificationPolicy`) es fuente de verdad.

## 5. Parte A — Cargar inasistencia con fecha

### 5.1 Decisión

Se usa `POST /classrooms/{id}/attendance` (merge de ausentes), no `POST /absences` directo, porque evita necesitar `professor_id` en el móvil y respeta el cálculo server de `quantity/period` (`ClassroomAttendanceController:118`).

### 5.2 Entrada

- En `StudentAbsencesTab`, si `isProfessor`: barra inferior de acción "Marcar inasistencia" dentro del tab que abre `MarkAbsenceSheet` (nuevo, mismo lenguaje visual que `CreateQualificationSheet`).
- Campos: Aula (fija si hay `classroomId`, si no dropdown de sus aulas) + Fecha (`showDatePicker`, default hoy, rango hoy−90d a hoy, sin futuro) + texto informativo ("Se agrega al parte del día sin quitar a los demás ausentes"). Sin campo motivo (el endpoint de parte no lo tiene).
- Confirmar → `GET /classrooms/{id}/attendance?date=X` → `absentIds + studentId` (set) → `POST` mismo endpoint → `invalidate(studentAbsencesProvider)` + refresco del día si la pantalla de asistencia está abierta → snackbar "Inasistencia registrada".
- Si el alumno ya estaba ausente ese día, la operación es idempotente (el server actualiza) y se informa "Ya estaba ausente ese día".
- Errores 403/422 → snackbar de error con mensaje de `ApiException`.

## 6. Parte B — Home del profesor

Principios (`operate`): misma vocabulario (`AppCard`, `SectionHeader`, `EmptyState`, `ErrorView`, `ListShimmer`, iconos Phosphor), densidad compacta, `spacing` antes que bordes extra, estados loading/empty/error por sección para que una falle sin tumbar el home. Sin rediseño fuera del alcance.

Orden y límites aprobados: Calendario (5) → Cumpleaños hoy → Novedades (3) → Documentos (5), debajo de los botones actuales de asistencia/nota. Cada sección con header + "Ver todo".

### 6.1 Calendario

- Nuevo `EventApi.getCalendar({startDate, endDate})` → `GET /events/calendar`. Home pide `hoy` a `hoy+30`, `take(5)`, orden asc (orden server).
- Tile: fecha (`MMM d`), título, hora si hay. Tap → `/events`. Vacío → `EmptyState` calendario. Error → `ErrorView` compacto con reintentar solo esa sección.

### 6.2 Novedades

- Reusa `newsListProvider` / `NewsApi.getNews`, `take(3)` en home (la lista completa sigue paginada en `/news`).
- Card compacta (título + 2 líneas + fecha). Tap → `/news`. Mismo manejo vacío/error por sección.

### 6.3 Documentos (solo lectura)

- Nuevo feature `lib/features/documents/` clonando `news/`: `document_api.dart` (`getDocuments({cursor,limit})`, `getDocument(id)`), `document_repository.dart`, `document_model.dart` (freezed: `id, title, description, fileUrl, createdAt, media[]` con `url`), `document_provider.dart` (cursor + `homeDocumentsProvider` take 5), `document_list_screen.dart`, widget `document_tile.dart`.
- Home: últimos 5 (`order created_at desc`, paridad web). Tile: ícono file, título, fecha `d/m/Y`. Tap → `DocumentDetailScreen` mínima (título, descripción, fecha, botón "Abrir/Descargar" con `url_launcher` si ya está en el proyecto; si no, se agrega como única dependencia nueva) que abre `media.url ?? file_url` o `GET /documents/{id}/download`.
- Ruta `/documents` en `router.dart` (fuera del shell o push simple, igual que `/news`). Solo lectura: sin FAB ni menú.

### 6.4 Cumpleaños

- Nuevo feature mínimo `lib/features/birthdays/`: `birthday_model.dart` (`id, name, ageTurning, studentAppId, birthDate, daysUntil`), `birthday_api.dart` (`getTodayBirthdays()`), `birthday_provider.dart` (`FutureProvider`).
- Widget home: "Cumpleaños de hoy" con avatar + nombre + edad que cumple. Vacío → `EmptyState` pastel (caso normal). Si el backend responde 404/501 (aún no implementado) → mensaje "Disponible próximamente", sin error rojo ni crash. Tap en un cumple → `/students/{studentAppId}` cuando hay id.
- Depende del contrato §7; el móvil no calcula cumpleaños localmente porque no tiene `birth_date`.

## 7. Contratos

```
POST  /api/v1/qualifications              existente: student_id, classroom_id, score, type, period, description?
GET   /api/v1/classrooms/{id}/attendance?date=YYYY-MM-DD   existente
POST  /api/v1/classrooms/{id}/attendance  existente: {date, absent_student_ids[]}
GET   /api/v1/events/calendar?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&branch_name?  existente
GET   /api/v1/news?cursor?&per_page=20     existente
GET   /api/v1/documents?cursor?&per_page=20&search?        existente
GET   /api/v1/documents/{id}               existente
GET   /api/v1/documents/{id}/download      existente
GET   /api/v1/birthdays?scope=today        NUEVO (efe-app):
      auth sanctum; filtro profesor = alumnos de sus aulas (Classrooms whereHas professor),
      parent = sus hijos, branch = su sede, admin = todo;
      match TO_CHAR(birth_date,'MM-DD') = today (scope=today)
      o BETWEEN hoy y hoy+days_ahead (scope=upcoming, default 30);
      response {data: [{id, name, age_turning, student_app_id, birth_date, days_until}]}
```

Backend `birthdays`: controlador API nuevo + ruta en `routes/api.php` + policy (profesor solo ve sus alumnos). Sin cambios al dashboard agregado.

## 8. Testing y verificación

**Mobile**

- Unit: resolución de aula (fija vs dropdown vs sin aulas), `MarkAbsenceSheet` merge idempotente, parseo `DocumentModel`/`BirthdayModel` (media ausente, fechas nulas).
- Widget: tabs muestran/ocultan acciones según `isProfessor`; sheet de nota con aula fija y con dropdown; sheet de inasistencia con fecha futura bloqueada; home renderiza 4 secciones con loading → datos, una sección en error no rompe las demás; documentos abre URL.
- Comandos: `flutter gen-l10n`, `flutter analyze` (0 issues), `flutter test` (suite + nuevos en verde).

**Backend**

- Pest/feature para `GET /birthdays`: profesor solo ve cumpleaños de hoy de sus alumnos; parent/admin/branch según filtro; `php -l` + `pint`. No ejecutar suite que borre la base de desarrollo.

## 9. Riesgos y decisiones tomadas

- **`POST /absences` descartado en móvil**: exige `professor_id`; el parte por aula ya lo resuelve server y es idempotente.
- **Sobreescritura del parte**: el merge lee el día antes de escribir; nunca se envía solo el alumno (evita borrar otros ausentes).
- **Fecha futura bloqueada**: el parte es registro, no planificación.
- **Cumpleaños sin backend**: fallback "próximamente" en vez de cálculo local con datos que el móvil no tiene.
- **Documentos grandes**: apertura externa en vez de visor propio; timeout de descarga con el `ApiClient` actual.
- **`url_launcher`**: única dependencia candidata; solo si no existe ya en `pubspec.yaml`.

## 10. Criterios de éxito

1. Un profesor carga una nota desde el detalle con aula fija o dropdown, y la ve reflejada al volver al tab.
2. Un profesor marca inasistencia con fecha desde el detalle sin alterar otros ausentes del parte.
3. El home muestra calendario (5), cumpleaños de hoy, novedades (3) y documentos (5) con deep-links; una sección caída no rompe el resto.
4. Documentos es solo lectura y abre/descarga el archivo.
5. `flutter analyze` limpio y `flutter test` en verde.
