# Boletín de notas de padres (etapa 3 de la experiencia de padres) — Diseño

**Fecha:** 2026-10-16
**Repos:** `efe_mobile` (Flutter, Riverpod 2, go_router 14.8.1) y `efe-app` (Laravel 11, API `/api/v1`)
**Estado:** diseño aprobado en conversación; pendiente de revisión de este spec.

## 1. Contexto

La acción “Boletín” del home de padres (etapa 1) abre hoy la ficha del hijo en el tab Notas. El boletín formal existe como **PDF** en el backend:

- `GET /api/v1/qualifications/boletin/{studentId}/{classroomId}` (`QualificationController@boletin`) devuelve un PDF (DomPDF, `resources/views/pdf/boletin.blade.php`, 289 líneas) con: encabezado alumno/aula, notas por tipo/período, **Promedio** (media simple de scores numéricos, 2 decimales), resumen de inasistencias (total/justificadas/sin justificar) + **% de asistencia por período** (`AttendanceCalculationService`), detalle de faltas y **Observaciones**. Soporta `?period=`.
- **La ruta API no tiene autorización** (findOrFail y listo) y **no tiene consumidores**: el web usa rutas propias (`students.boletin.download`, `classrooms.boletin.export.group` en `routes/web.php:174-181`; `BoletinDownloadButton.jsx` abre en pestaña nueva).
- El cliente móvil manda `Accept: application/json` global (`lib/core/api/api_client.dart:23`) → la negociación de contenido en la misma ruta es viable sin tocar al web.
- Observaciones tiene `is_public`: el API de observaciones filtra `is_public = true` para padre/alumno (`ObservationController.php:118,127`); el PDF actual incluye todas.
- La app no tiene boletín ni observaciones; sí tiene el grid de notas del detalle del hijo (`buildGradeGrid`, regla de dedup por tipo+categoría + mapa de texto) y `studentClassroomsProvider` (etapa 1).

## 2. Decisiones del usuario

| Pregunta | Respuesta |
|---|---|
| Naturaleza | **Pantalla nativa + descargar el PDF oficial** (con el gate del endpoint actual). |
| Mockup | Sin mockup: diseño propio siguiendo la estructura del PDF y el sistema de la app. |
| Aulas y períodos | **Selector de aula solo si hay 2+**; los 3 períodos en una vista (boletín completo). |
| Enfoque técnico | **A**: misma ruta con negociación de contenido (`Accept`) + link firmado + policy. |

## 3. Objetivo

Que el padre (y también el alumno, profesor y staff) vea el boletín completo de un alumno por aula dentro de la app — notas por período con promedio de paridad con el PDF, asistencia por período, inasistencias y observaciones públicas — y pueda descargar el PDF oficial, con la API autorizada y sin cambios para el web.

## 4. Alcance y no-objetivos

**Dentro del alcance**

- Backend: rama JSON por `wantsJson()` en la ruta del boletín (contrato §5.1); `authorizeBoletin`; filtro de observaciones por rol; rutas `…/link` (auth + policy) y `…/file` (pública + `signed`); tests Pest (escritos, no ejecutados).
- Móvil: dominio `BoletinData`; `QualificationApi.getBoletin/getBoletinLink`; repo; `boletinProvider`; `StudentBoletinScreen` (`/students/:id/boletin`) con chips de aula, secciones y descarga; la acción “Boletín” del home pasa a abrirla; botón “Ver boletín” al pie del tab Notas de la ficha (extra barato, vetable); l10n ES/EN; tests.
- Gate de la ruta actual (hoy sin autorización).

**Fuera del alcance (diferido)**

- Filtro de período en la pantalla (el boletín completo entra en una vista; el PDF ya soporta `?period=`).
- Export grupal por aula (`classrooms.boletin.export.group`), boletín por familia/grupo.
- Edición/creación de observaciones desde la app.
- Notificaciones, cambios al web, etapa 4 (no hay).

## 5. Contrato backend

### 5.1 JSON del boletín (misma ruta, por `Accept`)

`GET /qualifications/boletin/{studentId}/{classroomId}` → si `wantsJson()` responde:

```json
"data": {
  "student": {"id": "uuid", "fullname": "…"},
  "classroom": {"id": "…", "name": "…"},
  "periods": ["1", "2", "3"],
  "qualifications": [{"type": "Escrito", "category": "Desempeño", "period": "1", "score": "8"}],
  "averages": {"1": 8.0, "2": null, "3": 7.75},
  "absences": {
    "total": 5, "justified": 2, "unjustified": 3,
    "attendance_by_period": {"1": 95.0, "2": null, "3": 88.5},
    "list": [{"date": "…", "quantity": 1, "justified": true}]
  },
  "observations": [{"date": "…", "description": "…"}]
}
```

Reglas:
- **`averages`**: media simple de scores **numéricos** por período, redondeo 2, `null` sin datos — **regla del PDF** (paridad con el documento descargable). El grid del detalle del hijo conserva su regla propia (dedup + mapa de texto); son vistas distintas y queda documentado.
- **`attendance_by_period`**: `AttendanceCalculationService` por período (1, 2, 3), `null` cuando no hay clases registradas.
- **`absences.justified/unjustified`** y `list[].justified`: misma clasificación del sistema (status justificado/pendiente/sin justificar con fallback al campo `justified`).
- **`observations`**: para padre/alumno solo `is_public = true`; admin/sucursal/profesor todas (como el PDF actual). La generación del PDF por esta ruta aplica el mismo filtro por rol.
- Sin `?period=`, el payload trae todos los períodos (la app no manda período).

### 5.2 Autorización (`authorizeBoletin`)

| Rol | Regla |
|---|---|
| admin/branch | todo |
| parent | `student->parents()` contiene al user (`parent_data.user_id`) |
| student | `user->studentData->id === student->id` |
| professor | `classroom->professor` con `professor_data.user_id === user->id` |
| otros | 403 |

Aplica a la data (JSON y PDF) y al `link`. Se implementa en el controller (patrón `authorizeStudentFees` de la etapa 2).

### 5.3 Descarga firmada

- `GET /qualifications/boletin/{studentId}/{classroomId}/link` (auth + policy) → `{data:{url}}` con `URL::temporarySignedRoute('api.qualifications.boletin.file', now()->addMinutes(10), [...])`.
- `GET /qualifications/boletin/{studentId}/{classroomId}/file` (pública, middleware `signed`) → el PDF (misma generación y filtro de observaciones por rol).

### 5.4 Tests backend (Pest, escritos y **no ejecutados** — AGENTS.md)

Policy (padre propio/ajeno, alumno, profesor de la cátedra/otra, admin), JSON por `wantsJson` (shape + nulls), observaciones filtradas para padre, link firmado (valid/tampered) y file. Verificación local: `php -l`, `pint`, tinker.

## 6. Datos en Flutter

- Dominio nuevo `lib/features/qualifications/domain/boletin_data.dart`: `BoletinData` (student, classroom, periods, qualifications, averages, absences, observations) + `BoletinQualification{type, category, period, score}` + `BoletinAbsences{total, justified, unjustified, attendanceByPeriod, list}` + `BoletinAbsence{date, quantity, justified}` + `BoletinObservation{date, description}` (freezed + fromJson manual, null-safe).
- `QualificationApi`: `getBoletin(studentId, classroomId)` → `GET /qualifications/boletin/{s}/{c}`; `getBoletinLink(studentId, classroomId)` → `…/link` (parse `data.url`). Repo con manejo de `DioException`.
- `boletinProvider = FutureProvider.family<BoletinData, ({String studentId, String classroomId})>`.
- Chips de aula: reusa `studentClassroomsProvider(studentId)` (etapa 1).

## 7. UI — Pantalla Boletín (`StudentBoletinScreen`)

- `ScreenHeader`: volver + “Boletín” (`boletinTitle`) + subtítulo con el nombre del hijo.
- **Chips de aula** (solo con 2+): pills con `accentFor(isDark)`; default la primera; cambio → refetch.
- **Secciones** (todos los períodos del aula elegida):
  1. **Notas** (`studentsTabGrades`): por período con datos, card “1° Período” (`boletinPeriod`) + badge **Promedio** (`gradesGridAverage`, color por `AppColors.gradeColor`) + filas tipo → nota (numérica coloreada, texto tal cual).
  2. **Asistencia** (`dashboardAttendance`): resumen (total / justificadas / sin justificar) + % por período.
  3. **Inasistencias** (`studentsTabAbsences`): lista fecha · cantidad · badge justificada/sin justificar; oculta si vacía.
  4. **Observaciones** (`boletinObservations`): fecha + descripción; oculta si vacía.
- **Botón fijo al pie**: “Descargar boletín (PDF)” (`boletinDownloadAction`, `PillButton`) → `getBoletinLink` → `openUrl` (inyectable, default `launchUrl` externo); fallo → snackbar `boletinDownloadError` sin crash.
- **Estados**: shimmer, `ErrorView` + retry, sin aulas → `EmptyState` reusando `classroomsEmptyTitle`, secciones sin datos con su vacío (“No hay calificaciones registradas para este período”, `boletinNoGrades`); pull-to-refresh.
- Adaptaciones documentadas: promedios con regla del PDF (paridad); observaciones solo públicas; sin filtro de período (YAGNI).

## 8. Navegación

- Ruta nueva `/students/:id/boletin` (hija de `/students/:id`; push sobre el shell, back vuelve).
- Home: `_openBoletin` de `ParentHomeScreen` pasa a empujar `/students/{studentId}/boletin` (1 hijo directo; 2+ hoja “Elegí un hijo” como hoy).
- Extra: botón “Ver boletín” al pie del tab Notas de la ficha (`StudentGradesTab`) → misma ruta.

## 9. i18n

Nuevas ES/EN: `boletinTitle` (“Boletín”/“Report card”), `boletinDownloadAction` (“Descargar boletín (PDF)”/“Download report card (PDF)”), `boletinPeriod` (“{n}° Período”/“Period {n}”), `boletinObservations` (“Observaciones”/“Observations”), `boletinNoGrades` (“No hay calificaciones registradas para este período”/“No grades recorded for this period”), `boletinDownloadError` (“No se pudo descargar el boletín”/“Could not download the report card”). Se reutilizan `gradesGridAverage`, `dashboardAttendance`, `studentsTabAbsences`, justificada/sin justificar y `commonRetry`.

## 10. Testing y verificación

**Flutter**
- Unit: parseo de `BoletinData` (nulls, listas vacías, `attendance_by_period`), api (URLs del boletín y del link), repo.
- Widget: `StudentBoletinScreen` (1 aula sin chips; 2+ con refetch al cambiar; secciones con datos; promedio coloreado; inasistencias/observaciones ocultas si vacías; PDF → `openUrl` con la URL del repo; fallo → snackbar; loading/error/sin-aulas; dark); home (Boletín abre la ruta nueva, 1 vs 2+ hijos); ficha (botón “Ver boletín”); routing con shell real.
- Comandos: `flutter gen-l10n`, `flutter analyze` (sin issues nuevos), `flutter test` verde.

**Backend (`efe-app`)**
- Pest por §5.4 (escritos, no ejecutados). Verificación: `php -l`, `pint`, tinker (JSON real con un padre de la base; filtro de observaciones; firma valid/tampered).

## 11. Riesgos y decisiones

- **Negociación por `Accept`**: la ruta API no tiene consumidores y el web usa rutas propias (verificado) — sin riesgo para el web; la app ya manda `Accept: application/json`.
- **Promedio del boletín (regla PDF) ≠ grid del detalle (dedup+mapa)**: decisión explícita por paridad con el documento descargable; documentada en código y spec.
- **Observaciones**: padre/alumno solo públicas (el PDF generado por esta ruta también filtra por rol) — evita exponer notas internas.
- **`current_selected_id`**: la regla de alumno usa `user->studentData` (quirk pre-existente, igual que las policies de la etapa 2).
- **Firma 10 min**: uso inmediato; depende de `APP_URL` correcta (ya usado por facturas).
- **Pest no ejecutable localmente**: queda para CI; verificación local con tinker.

## 12. Criterios de éxito

1. Desde el home, “Boletín” abre la pantalla del hijo elegido (1 directo / 2+ selector).
2. La pantalla muestra notas por período con promedio de paridad-PDF, asistencia por período, inasistencias y observaciones públicas — con selector de aula si el hijo tiene 2+.
3. “Descargar boletín (PDF)” abre el PDF oficial vía URL firmada.
4. La API queda autorizada (padre solo su hijo; alumno propio; profesor su aula; admin todo) y el web intacto.
5. Otros roles y pantallas intactos; `flutter analyze` sin issues nuevos y `flutter test` verde; ES/EN; claro/oscuro.

## 13. Cierre de la serie

Con esta etapa, la experiencia de padres queda completa: **Home (etapa 1) + Pagos (etapa 2) + Boletín (etapa 3)**, con las tres integradas y sus specs/planes en `docs/superpowers/`.
