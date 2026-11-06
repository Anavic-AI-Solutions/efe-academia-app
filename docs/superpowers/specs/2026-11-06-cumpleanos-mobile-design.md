# Cumpleaños en mobile — Diseño

**Fecha:** 2026-11-06
**Alcance:** completar el módulo de Cumpleaños en la app mobile con el mismo
alcance que la web: cumpleaños de hoy + próximos 30 días, filtrados por rol.

## Contexto actual

- El mobile ya tiene `BirthdayModel`, `BirthdayApi`, `todayBirthdaysProvider`,
  `BirthdayListScreen`, `HomeBirthdaysSection` y tests.
- Todo cae en “Disponible próximamente” porque `GET /api/v1/birthdays` no
  existe en el backend.
- La web sí tiene `BirthdaysController@index` (`/platform/birthdays`) con
  filtro por rol y ventana de 30 días, pero renderiza Inertia y no expone JSON.
- El menú mobile muestra “Cumpleaños” a admin/sede/profesor/padre.

## Objetivo

Que la sección `/birthdays` muestre, para el rol autenticado:

1. **Cumpleaños de hoy** (destacados).
2. **Próximos 30 días**.
3. Nombre, fecha de nacimiento, edad que cumple, días restantes y acceso al
   alumno cuando tiene cuenta de app.

El home del profesor sigue mostrando solo los de hoy.

## No-objetivos

- Push/notificaciones de cumpleaños.
- Edición de fechas de nacimiento desde mobile.
- Paginación: la ventana de 30 días acota el volumen.
- Cambios de UI web más allá de reutilizar la lógica de consulta.

## Contrato backend

`GET /api/v1/birthdays?scope=upcoming&days=30` (auth:sanctum)

- `scope=today` → solo hoy (lo usa el home mobile).
- `scope=upcoming` (default) → hoy + próximos `days` días (default 30).
- Respuesta:

```json
{
  "data": [
    {
      "id": 123,
      "name": "Ana Ruiz",
      "birth_date": "2018-10-08",
      "days_until": 0,
      "age_turning": 8,
      "student_app_id": "uuid-o-null"
    }
  ]
}
```

- `birth_date` en ISO `Y-m-d` para que mobile lo parsee; la web puede seguir
  formateando `d/m/Y` en su controlador.
- Orden: `days_until` ascendente.

### Filtro por rol

| Rol | Alcance |
|---|---|
| admin | Todos los `SystemStudents` activos |
| branch | Activos cuyo `StudentData.branch` = `user.branch_name` |
| professor | Activos de alumnos en aulas del profesor |
| parent | Activos de los hijos vinculados al padre |
| student | Solo su propio cumpleaños (aunque el menú no muestre la sección) |
| desconocido | Lista vacía |

Solo alumnos `active = true`.

### Ventana de fechas

Se compara `MM-DD` de `birth_date` contra `[hoy, hoy+30]`, incluyendo el cruce
de año (diciembre → enero). Se usa una expresión compatible con PostgreSQL y
SQLite (`TO_CHAR` / `strftime`) para que los tests corran en SQLite.

## Backend — implementación

- Nuevo `App\Services\BirthdayService` con `forUser(User $user, string $scope,
  int $days): Collection`.
- `BirthdaysController` (web) y nuevo
  `App\Http\Controllers\Api\Birthdays\BirthdayController@index` comparten el
  service.
- Ruta en `routes/api.php` dentro del grupo autenticado.
- Tests `tests/Feature/Api/BirthdaysTest.php`: admin, branch, professor,
  parent, student, rol desconocido, `scope=today`, inactivos, cruce de año y
  forma de la respuesta.

## Mobile — implementación

- `BirthdayApi.getBirthdays({String scope = 'upcoming', int days = 30})`.
- `todayBirthdaysProvider` → `scope=today` (sin cambios de contrato).
- Nuevo `upcomingBirthdaysProvider` → `scope=upcoming`.
- `BirthdayListScreen`:
  - Sección “Cumpleaños de hoy” solo si hay.
  - Sección “Próximos 30 días”.
  - Tarjeta: inicial/avatar, nombre, fecha (`d/M`), edad, “Hoy / Mañana / En X
    días”; tap a `/students/{student_app_id}` si existe.
  - Loading shimmer, ErrorView con retry, EmptyState, fallback 404/501.
  - Pull-to-refresh.
- l10n ES/EN: títulos de secciones, “Hoy”, “Mañana”, “En {n} días”, “Cumple
  {n} años”, vacío de próximos.
- Tests: API query, parseo, agrupación hoy/próximos, navegación, fallback,
  error y refresco.

## Decisiones tomadas (revisables)

- Un solo endpoint con `scope` en vez de dos endpoints.
- `birth_date` ISO en la API; la web mantiene su formato.
- Se reutiliza `SystemStudents` (fuente de la web) y no `StudentData`, para
  incluir alumnos sin cuenta de app.
- La sección mobile no se muestra a alumno (matriz del menú), pero la API
  mantiene el alcance “solo su cumpleaños” por consistencia con la web.
- Sin paginación por la ventana de 30 días.

## Riesgos

- Diferencias de driver SQL: se cubren con la expresión por driver y tests.
- Zona horaria: se usa la zona de la app (`now()`), igual que la web.
- Alumnos sin `student_app_id`: se muestran sin navegación.
