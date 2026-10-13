# Rediseño del home de padres — Diseño (etapa 1 de la experiencia de padres)

**Fecha:** 2026-10-13
**Repos:** `efe_mobile` (Flutter 3.x, Riverpod 2, go_router 14.8.1) y `efe-app` (Laravel 11, API `/api/v1`)
**Estado:** diseño aprobado en conversación; pendiente de revisión de este spec.

## 1. Contexto

El mockup del usuario rediseña el inicio del rol padre. Hoy:

- `DashboardScreen` (`lib/features/dashboard/screens/dashboard_screen.dart`) delega en `ProfessorHomeScreen` para profesores (`:36`) y renderiza un home genérico para el resto, con ramas inline para padres (`:174-184`): `HomeHeader` (saludo por hora + nombre + campana + lupa + fila de 3 stats), badge “Tutor”, `ParentChildrenSection` (tarjetas de hijo solo con nombre + flecha) y `QuickActionGrid` de 8 tiles.
- `ParentChildrenSection` (`lib/features/dashboard/screens/widgets/parent_children_section.dart:15`) lista los hijos desde `relationsProvider` (`GET /relations`; `user_id` = id de cuenta del hijo).
- Barra inferior (`lib/app/router.dart:39`): pestañas Inicio / Aulas / Chat / Perfil para todos los roles; la 2ª pestaña apunta al branch `'/classrooms'` (`:251-280`).
- El “tap de hijo” navega a `/students/{user_id}` (`dashboard_screen.dart:180`), pero `GET /students/{student}` resuelve `StudentData` por su uuid (`StudentDataPolicy::view`, sin `getRouteKeyName`); el id correcto es el `student_id` (uuid) de `student_data`, no el id de cuenta. El selector de hijos del listado de cuotas tiene el mismo desajuste (la etapa 2 lo rediseña).
- `HomeHeader` (`lib/core/widgets/home_header.dart:30`) siempre muestra la lupa y calcula el saludo por hora; no es parametrizable hoy.

Hallazgos verificados en backend:

- `GET /api/v1/statistics/dashboard` (parent) ya devuelve `metrics` con `fees_overdue` y `total_owed` (`PlatformMetricsService::getParentMetrics`) y `details` con `myChildrenAbsenceRate` / `gradeComparison` / `myChildrenGrades` / `myFamilyAccountStatus` (`StatisticsService::getParentData`, `app/Services/StatisticsService.php:85`).
- No existe un resumen por hijo que junte identidad + aula/año + promedio/asistencia: `myChildrenAbsenceRate` solo trae `child_name`.
- `GET /students/{id}/classrooms` existe y autoriza a padre/profesor/admin (`StudentDataPolicy::view`).
- La biblioteca UIZZE no devolvió referencias útiles para apps escolares/de padres; el diseño se apoya en el mockup del usuario y en el sistema visual propio (`docs/superpowers/specs/2026-10-01-ui-azul-unificada-design.md`).

## 2. Decisiones del usuario

| Pregunta | Respuesta |
|---|---|
| Alcance | Toda la experiencia de padres, partida en etapas. Esta = Home (el mockup). |
| Backend | Se permite un cambio chico en `efe-app`. |
| Multi-hijo | Una tarjeta por hijo, cada una con sus stats. |
| “Boletín” con 2+ hijos | Hoja de selección de hijo; con 1 hijo, directo. |
| “Pagar” | Lleva a la pestaña Pagos (listado de cuotas; el flujo de pago llega en la etapa 2). |

## 3. Objetivo

Que el inicio del rol padre sea el del mockup — saludo “Hola / Familia {apellido}”, alerta de mora con “Pagar”, una tarjeta por hijo con Promedio y Asistencia, acciones Cuotas/Boletín/Chat y barra con pestaña “Pagos” — con datos reales en un solo request, sin regresiones para otros roles y sin perder el acceso de padres a las aulas.

## 4. Alcance y no-objetivos

**Dentro del alcance**

- `ParentHomeScreen` + widgets (alerta de mora, tarjeta de hijo, acciones).
- `myChildrenSummary` en el backend (contrato §5).
- Pestaña “Pagos” para padres (branch del shell).
- Sección “Aulas” en la ficha del hijo (reemplazo del acceso que hoy da la pestaña Aulas).
- Boletín provisorio: abre la ficha del hijo en Notas (con selector si hay 2+ hijos).
- l10n es/en; tests móvil + Pest.

**Fuera del alcance (diferido)**

- Rediseño fino de la pantalla Pagos y flujo de pago/comprobante/factura (etapa 2).
- Fix de ids en los filtros por hijo de los listados de cuotas/aulas (etapa 2).
- Pantalla de Boletín real (etapa 3).
- Búsqueda en el home de padres: se remueve según el mockup (se reintegra si se pide).
- Cambios al panel web y notificaciones push nuevas.

## 5. Contrato backend — `myChildrenSummary`

`StatisticsService::getParentData()` agrega un array nuevo en `details`, sin tocar los existentes:

```json
"myChildrenSummary": [
  {
    "student_id": "uuid de student_data",
    "user_id": 123,
    "child_name": "Rahul Kuvalis",
    "classroom_name": "3G X",
    "classrooms_count": 1,
    "year": "3",
    "average_grade": 7.9,
    "attendance_rate": 95.0
  }
]
```

Reglas:

- `student_id`: uuid de `student_data`; `user_id`: id de cuenta del hijo (puede ser null; la app cruza por `user_id`).
- `classroom_name`: nombre de la primera aula del alumno; `''` si no tiene. `classrooms_count`: cantidad de aulas.
- `year`: `student_data.year`; `''` si vacío.
- `average_grade`: media simple de `qualifications` con score numérico (`score ~ '^[0-9]+(\.[0-9]+)?$'`), redondeo 2; `null` si no hay notas numéricas.
- `attendance_rate`: `100 − (inasistencias / clases × 100)`, con el mismo cálculo de `myChildrenAbsenceRate` (año lectivo, `quantity` sumado), clamp [0,100], redondeo 2; `null` si no hay clases registradas. Es el proxy disponible (idéntico al que usa la web); documentarlo en el código.
- Sin cambios de permisos ni de los arrays existentes.

Test Pest: parent con hijos → payload completo; hijo sin notas/clases → nulls; otros roles intactos.

## 6. Datos en Flutter

- Nuevo `lib/features/dashboard/domain/parent_home_data.dart`:
  - `ParentChildSummary { int userId; String studentId; String name; String classroomName; int classroomsCount; String year; double? averageGrade; double? attendanceRate; }`
  - `ParentHomeData { int overdueFeesCount; double moraTotal; List<ParentChildSummary> children; }`
- `DashboardData` suma `ParentHomeData? parentHome` (solo se llena con rol padre). `DashboardRepository` parsea `metrics.fees_overdue`, `metrics.total_owed` y `details.myChildrenSummary` del mismo `GET /statistics/dashboard`; sin cambios para otros roles. Regenerar freezed (`build_runner`).
- Cruce: hijos de `relationsProvider` (role student) ↔ `parentHome.children` por `userId`; sin summary para un hijo → stats “—” y sin subtítulo.
- Deploy: si la app sale antes que el backend, `myChildrenSummary` falta ⇒ tarjetas sin stats ni subtítulo (degradación limpia, sin crash).

## 7. UI del home

`ParentHomeScreen` (`lib/features/dashboard/screens/parent_home_screen.dart`); `DashboardScreen` delega en ella para rol padre (mismo patrón que profesor). Orden del contenido:

1. **Header** (`HomeHeader`, reutilizado): `greeting: "Hola"`, `title: "Familia {apellido}"` (apellido = último token de `user.name`; con nombre de una sola palabra, se muestra sin “Familia”), avatar y campana con no leídas. Sin lupa y sin `HeaderStatsRow`. Cambios aditivos en `HomeHeader`: parámetro opcional `greeting` y ocultar la lupa cuando `onSearch == null`.
2. **Alerta de mora** (`ParentOverdueFeesCard`, nuevo): visible solo si `overdueFeesCount > 0`. Título `parentOverdueFeesCount(count)` (11/w800), subtítulo `parentMoraTotal` + `AppFormatters.formatCurrency(moraTotal)`, botón “Pagar”.
3. **Tarjetas de hijo** (`ParentChildCard`, nuevo; elimina `ParentChildrenSection` y su test): `AppCard` con avatar de iniciales, nombre, subtítulo `"{aula} · {año}° año"` (aula sola si no hay año; oculto si no hay datos) y dos tiles Promedio / Asistencia con `chipFor(isDark)` y valores `accentFor(isDark)`; sin notas o sin clases → “—”; tap → `/students/{student_id}`. El tap **no** escribe `parentSelectedStudentProvider` en esta etapa: los selectores de Cuotas/Aulas siguen manejando su propio estado hasta que la etapa 2 corrija el paso de ids.
4. **Acciones** (`ParentQuickActions`, nuevo): tres tarjetas solo texto. Cuotas → pestaña Pagos; Boletín → con 1 hijo push a su ficha (abre en Notas), con 2+ bottom sheet “Elegí un hijo”; Chat → pestaña Chat. Sin título de sección.

Estados: loading → shimmer con la estructura (header, alerta, 2 tarjetas); error de dashboard sin datos → `ErrorView` con retry (patrón profesor); error de relations (hijos) → error acotado en el bloque de tarjetas, sin tumbar alerta ni acciones; sin hijos → `EmptyState` existente; pull-to-refresh refresca dashboard + relations.

Colores (tokens nuevos en `AppColors`; el mockup trae `#FDEAEA / #C23B3B / #E05353`, este último 3.4:1 con blanco, insuficiente):

| Token | Claro | Oscuro |
|---|---|---|
| `dangerSoft` (fondo) | `#FDEAEA` | `#3A2327` |
| `dangerInk` (título) | `#B53434` | `#F0A9A9` |
| `dangerInkMuted` (subtítulo) | `#8F4A4A` | `#E0A0A0` |
| Botón Pagar | fondo `#B53434`, texto blanco | fondo `#F0A9A9`, texto `#3A2327` |

Contrastes ≥5:1 (claro) y ≥6:1 (oscuro); se revalidan en implementación.

## 8. Navegación

- `CustomBottomNav` (`lib/app/router.dart:39`): 2ª pestaña según rol — padre: `navPayments` + icono wallet apuntando al branch 1; resto: “Aulas” como hoy.
- Branch 1 suma la ruta `'/payments'` (renderiza `FeeListScreen` existente) y usa `StatefulShellBranch.initialLocation` (soportado por go_router 14.8.1): `'/payments'` para padre; sin valor (⇒ `'/classrooms'`) para el resto. `/fees` y `/fees/:id` se conservan para los demás roles; el detalle de cuota se sigue empujando sobre el shell.
- Acciones: Pagar/Cuotas → `context.go('/payments')`; Chat → `context.go('/chat')`; hijo → `context.push('/students/{student_id}')`; Boletín con 1 hijo → `context.push('/students/{student_id}')` (la ficha abre en Notas por defecto).
- **Aulas para padres:** sección nueva en `StudentInfoTab` (`lib/features/students/screens/widgets/student_info_tab.dart`) con las aulas del alumno (nombre + chevron, patrón `_ParentClassroomCard`) que abren `/classrooms/{id}`; datos de `GET /students/{id}/classrooms` con provider nuevo del feature students; sección oculta si no hay aulas; visible para todos los roles (sin rama de rol).

## 9. i18n

Nuevas claves en `app_es.arb` + `app_en.arb` (`flutter gen-l10n`):

| Clave | ES | EN |
|---|---|---|
| `parentFamilyTitle` | `Familia {surname}` | `The {surname} Family` |
| `parentOverdueFeesCount` | plural: `1 cuota vencida` / `{count} cuotas vencidas` | `1 overdue installment` / `{count} overdue installments` |
| `parentMoraTotal` | `Mora total` | `Total overdue` |
| `parentPayAction` | `Pagar` | `Pay` |
| `navPayments` | `Pagos` | `Payments` |
| `parentActionBoletin` | `Boletín` | `Report Card` |
| `parentChooseChild` | `Elegí un hijo` | `Choose a child` |

Se reutilizan Promedio (`gradesGridAverage`), Asistencia (`dashboardAttendance`), Cuotas (`feesTitle`), Chat (`navChat`), Aulas (`classroomsTitle`) y los textos de empty/error existentes.

## 10. Testing y verificación

**Flutter**

- Unit: parseo de `ParentHomeData` (fixture con `metrics` + `details`; nulls; summary ausente); cruce por `userId`; apellido para “Familia” (2 token / 1 token).
- Widget `ParentHomeScreen`: familia + “Hola”; alerta visible con vencidas y monto formateado; oculta con 0; tarjeta por hijo con stats y “—”; error de relations no tumba la alerta; vacío → `EmptyState`; tap hijo → `/students/{uuid}`; Pagar → branch Pagos; Boletín 1 vs 2 hijos (sheet → ficha).
- Nav: padre muestra “Pagos” (icono wallet); profesor “Aulas” (regresión).
- Ficha: sección Aulas lista y navega; el detalle sigue abriendo en Notas.
- Actualizar `test/dashboard/parent_children_section_test.dart` (se elimina) y `test/dashboard/dashboard_screen_test.dart`.
- Comandos: `flutter gen-l10n`, `flutter analyze` (0 issues), `flutter test` en verde.

**Backend (`efe-app`)**

- Pest feature de `statistics/dashboard` parent: `myChildrenSummary` con ids/aula/año/promedio/asistencia; nulls sin notas/clases; otros roles intactos. `php -l` + `pint` donde aplique. No ejecutar suites que borren la base de desarrollo.

## 11. Riesgos y decisiones

- **Ids:** la navegación usa `student_id` (uuid), corrigiendo el tap actual que manda `user_id`. Verificar en implementación contra el backend real. Los listados de cuotas/aulas conservan su comportamiento hasta la etapa 2; por eso el tap de hijo no escribe el estado compartido del “hijo seleccionado” en esta etapa.
- **Semántica de asistencia:** proxy inasistencias/clases (el mismo que usa la web); sin clases → “—”, nunca 0.
- **Contraste:** rojos del mockup ajustados a ≥4.5:1 (tabla §7).
- **Multi-hijo:** una tarjeta por hijo; familias grandes scrollean (aceptado).
- **Deploy desacoplado:** app y backend publican en cualquier orden sin romper (degradación limpia).
- **Búsqueda del home de padres:** removida según mockup; reintegrable a pedido.

## 12. Criterios de éxito

1. Home de padres fiel al mockup en claro y oscuro (con las adaptaciones de contraste): “Hola / Familia X”, alerta de mora con Pagar cuando hay vencidas, una tarjeta por hijo con Promedio/Asistencia, acciones Cuotas/Boletín/Chat.
2. Datos del home en un solo request; sin notas/clases → “—”; sin mora → sin alerta.
3. Tap de hijo con id correcto; Pagar/Chat cambian de pestaña; Boletín pide hijo solo con 2+ hijos.
4. Barra: “Pagos” para padres; profesor/admin igual que hoy; aulas del hijo accesibles desde su ficha.
5. `myChildrenSummary` en backend con test; sin cambios para otros roles ni arrays existentes.
6. `flutter analyze` limpio, `flutter test` verde, l10n es/en completo.

## 13. Etapas siguientes (fuera de este spec)

- **Etapa 2 — Pagos:** listado de cuotas de padres multi-hijo (vencidas primero), detalle con pago/comprobante/factura (`pay`, `upload-proof`, `invoice`) y fix de ids de los filtros por hijo.
- **Etapa 3 — Boletín:** pantalla de boletín por hijo/aula (`GET /qualifications/boletin/{studentId}/{classroomId}`) con notas y promedios; la acción “Boletín” pasa a abrirla.
