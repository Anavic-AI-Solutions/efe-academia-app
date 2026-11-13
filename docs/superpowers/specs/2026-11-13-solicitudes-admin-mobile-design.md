# Solicitudes (admin/sede) en EFE Mobile — Diseño

**Fecha:** 2026-11-13
**Repos:** `efe_mobile` (Flutter) y `efe-app` (Laravel API)
**Estado:** aprobado en conversación

## Intención

Que un usuario con rol real **admin** o **sede/branch** pueda revisar y resolver
desde la app móvil las solicitudes de alta de alumnos y padres/tutores, con la
misma lógica de negocio que la pantalla web `/platform/requests`.

Hoy la app móvil no tiene la sección ni la pantalla, y el menú mobile fue
deliberadamente limitado a 12 secciones en el plan del 2026-11-04. La API mobile
tampoco expone el flujo de solicitudes: `/api/v1/registrations` es el formulario
público de inscripción, no la cola de altas pendientes.

## Objetivos

- Agregar la sección **Solicitudes** al menú mobile, visible solo para
  `admin` y `branch`.
- Listar solicitudes de alumnos y padres con búsqueda, filtro por estado y tipo,
  y paginación.
- Ver el detalle de una solicitud, incluida su documentación.
- Aprobar o rechazar solicitudes respetando las reglas actuales de la web.
- Mantener paridad de comportamiento con la web y no duplicar reglas de negocio.

## No objetivos

- Gestión general de alumnos, padres o profesores desde mobile.
- Edición de los datos de una solicitud.
- Filtro por sede en la lista.
- Badge o contador de solicitudes en el menú.
- Nuevas notificaciones push de “nueva solicitud”.
- Cambios de comportamiento en la web.

## Anti-objetivos

- Reimplementar en mobile reglas de aprobación/rechazo distintas a la web.
- Mostrar la sección a roles que no sean admin/sede.
- Aprobar un alumno sin asignarle un curso.
- Dejar acciones de aprobar/rechazar visibles para solicitudes ya resueltas.

## Restricciones

- La app usa Flutter 3.44, Riverpod 2, go_router 14, Freezed, Dio y Phosphor.
- La API usa Laravel 11, Sanctum, PostgreSQL y respuestas JSON:API.
- `efe-app/AGENTS.md` prohíbe correr Pest/`php artisan test` sobre la base de
  desarrollo. Los tests backend se ejecutan en CI o con una base descartable.
- Los strings nuevos van en `lib/l10n/app_es.arb` y `app_en.arb`; los archivos
  `app_localizations*.dart` se regeneran con `flutter gen-l10n`, no se editan a
  mano.
- Los tests mobile deben pasar con `flutter analyze` y `flutter test`.
- Los chequeos de permisos siguen usando roles reales (`hasRole`), no el rol
  activo del token. La visibilidad del menú sí usa el rol activo, como el resto
  de la app.
- No se agregan dependencias nuevas.

## Enfoques considerados

### A. Endpoint dedicado de Solicitudes (elegido)

Un solo `GET /api/v1/requests` devuelve la lista combinada de alumnos y padres,
con detalle y acciones por tipo. Mobile tiene una sola pantalla de lista.

- Ventaja: paridad exacta con la web y una sola paginación.
- Costo: más trabajo de backend en el listado combinado.

### B. Extender alumnos y padres

`GET /students?request_status=pending` y `GET /parents?request_status=pending`,
más acciones en cada recurso. Mobile usa dos tabs.

- Ventaja: menos backend nuevo y más REST.
- Costo: la UI no queda igual a la web, son dos flujos y la aprobación
  encadenada de padre → hijos se coordina peor en mobile.

Se eligió **A** porque el pedido es replicar la vista de admin de la web.

## Diseño funcional

### Menú

- Nueva sección `requests` en `MenuSection`, grupo Académico, después de Cursos.
- Etiqueta “Solicitudes”.
- Visible solo para `admin` y `branch` (incluido `sede`, que se normaliza a
  `branch`).
- `admin` ve todas las sedes; `branch` ve solo solicitudes de su sede, tanto en
  la lista como en el detalle y en las acciones.
- Ruta `/requests`, apilada sobre el menú (no es tab del shell).
- Ícono: `PhosphorIconsRegular.clipboardText`.

### Lista

- Título “Solicitudes”.
- Búsqueda por nombre, email o DNI (accent-insensitive).
- Filtro de estado: Pendientes (por defecto), Aprobadas, Rechazadas.
- Filtro de tipo: Todos (por defecto), Alumnos, Padres/Tutores.
- Las solicitudes rechazadas siguen visibles aunque el usuario asociado esté
  soft-deleted (`withTrashed`), para que el filtro “Rechazadas” sea útil.
- Paginación por página, con el componente `PaginationBar`.
- Cada ítem muestra tipo, nombre, email/DNI, estado y, para padres, cantidad de
  hijos.
- Estados de carga, vacío, error y pull-to-refresh.

### Detalle de alumno

- Datos personales: nombre, email, DNI, sede, año.
- Documentación: DNI frente, selfie y otros archivos. Cada archivo se abre con
  la app externa correspondiente.
- Si `status == pending`: acciones **Aceptar** y **Rechazar**.
- Aceptar abre un selector de curso activo con búsqueda **en el servidor**
  (debounce de 350 ms, `per_page=50`). No se limita a los primeros 100 cursos
  cargados en memoria. Sin curso seleccionado no se puede confirmar. Al
  confirmar se llama al approve con `classroom_id`.
- Rechazar pide confirmación y llama al reject.

### Detalle de padre/tutor

- Datos personales: nombre, email, DNI, teléfono, dirección.
- Documentación del tutor.
- Lista de hijos con nombre, DNI y estado. Tocar un hijo abre su solicitud de
  alumno. El detalle del hijo recibe el id del padre para poder refrescar el
  detalle del tutor al volver.
- Si el tutor está pendiente: **Aceptar tutor** y **Rechazar**.
- Aceptar tutor no asigna cursos: marca al tutor como aprobado. Los hijos
  pendientes se aprueban individualmente desde su propia solicitud, donde se
  elige el curso. El resultado final es el mismo que la web, que aprueba al
  tutor y luego encadena al primer hijo.
- Rechazar al tutor rechaza también a sus hijos pendientes y elimina sus
  accesos, igual que la web.

### Después de una acción

- Se vuelve a la pantalla anterior y se refresca la lista.
- Si la acción se originó desde el detalle de un padre, al volver se invalida
  también el detalle del padre para que sus hijos y su estado se vean al día.
- Si la acción falla, se muestra un SnackBar con el error y no se navega.

## Diseño técnico — Backend (`efe-app`)

### Rutas

Todas bajo `auth:sanctum` y `role:admin,branch`:

```
GET    /api/v1/requests
GET    /api/v1/requests/students/{student}
GET    /api/v1/requests/parents/{parent}
POST   /api/v1/requests/students/{student}/approve
POST   /api/v1/requests/students/{student}/reject
POST   /api/v1/requests/parents/{parent}/approve
POST   /api/v1/requests/parents/{parent}/reject
```

### Lista

- `status`: `pending` por defecto; acepta `approved` y `rejected`.
- `type`: `all` por defecto; acepta `student` y `parent`.
- `search`: nombre, email o DNI con búsqueda accent-insensitive.
- `page`, `per_page` (default 20, máximo 100).
- Incluye alumnos con usuario y alumnos sin usuario.
- Solo incluye alumnos con `identity_number` no nulo y padres con
  `identity_number` y `email` no nulos, como la web.
- `admin` ve todo. `branch` solo ve alumnos de su sede y padres con al menos un
  hijo de su sede. El scope de sucursal de `StudentData` se conserva; solo se
  remueve el scope de orden.
- Las solicitudes rechazadas se buscan con `withTrashed()` sobre `User` para que
  no desaparezcan al soft-delete del usuario. Esto también mejora la lista web.
- Orden y paginación combinada equivalentes a `requestsIndex()` de la web.

Respuesta:

```json
{
  "data": [
    {
      "type": "student_request",
      "id": "uuid",
      "attributes": {
        "kind": "student",
        "fullname": "Ana Gómez",
        "email": "ana@example.com",
        "identity_number": "12345678",
        "branch": "Centro",
        "year": "2026",
        "status": "pending",
        "children_count": 0
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 41
  }
}
```

### Detalle

Mismo formato, con `phone`, `address`, `created_at`, `media` y, para padres,
`children`.

```json
{
  "data": {
    "type": "parent_request",
    "id": "uuid",
    "attributes": {
      "kind": "parent",
      "fullname": "María Pérez",
      "email": "maria@example.com",
      "phone": "3454...",
      "address": "Calle 123",
      "identity_number": "87654321",
      "status": "pending",
      "children_count": 2,
      "children": [
        {
          "id": "uuid",
          "fullname": "Juan Pérez",
          "identity_number": "11223344",
          "status": "pending",
          "branch": "Centro",
          "year": "2026"
        }
      ],
      "media": [
        {
          "collection_name": "front_dni",
          "file_name": "dni.jpg",
          "mime_type": "image/jpeg",
          "url": "https://.../storage/dni.jpg"
        }
      ]
    }
  }
}
```

Las URLs de media relativas se normalizan con el origen del request.

### Acciones

- `approve` alumno: requiere `classroom_id` existente. Marca `approved`, vincula
  el curso sin desvincular otros, notifica al alumno y, si el padre no tiene más
  hijos pendientes, aprueba al padre y lo notifica.
- `reject` alumno: si ya está `approved`, no hace nada. Si no, marca `rejected`,
  notifica y elimina (soft delete) el usuario.
- `approve` padre: marca `approved`, setea `current_student_id` al primer hijo y
  `current_selected_id` del usuario, y notifica.
- `reject` padre: marca `rejected`, rechaza a los hijos pendientes, notifica y
  elimina los usuarios correspondientes. Las notificaciones se envían antes del
  borrado.
- Acciones idempotentes: si la solicitud ya está en el estado destino, la
  respuesta sigue siendo `200` con `changed: false`. Un `classroom_id` faltante,
  inválido o inexistente devuelve `422`.
- Todas las respuestas de acción son `200` con
  `{"data": {"status": "approved" | "rejected", "changed": true | false, ...}}`.
- Para `branch`, un padre sin hijos en su sede responde `404` en detalle y
  acciones, aunque el route binding de `ParentData` no tenga scope de sede.

### Servicios compartidos

- `App\Services\RequestSearchService::paginate(User $viewer, string $status, string $type, string $search, int $perPage, int $page)`
  devuelve el `LengthAwarePaginator` que hoy arma `StudentDataController::requestsIndex()`.
  Web y API lo usan. Aplica el scope de sede para `branch`, usa `withTrashed()`
  en las consultas de `User` y busca por nombre, email y DNI.
- Nuevo scope `searchByFields(array $fields, ?string $search)` en
  `HasAccentInsensitiveSearch`, reutilizado por el servicio.
- `App\Services\RequestReviewService` concentra aprobar/rechazar alumno y padre,
  incluidas notificaciones y borrados. Web y API lo usan.
- Los controladores web conservan sus redirects actuales; solo delegan la
  lógica de negocio.

### Recursos

- `App\Http\Resources\RequestResource` acepta `StudentData` o `ParentData`.
- `type`: `student_request` / `parent_request`.
- `kind`, datos personales, `children_count`, `children` y `media` según
  relaciones cargadas.

## Diseño técnico — Mobile (`efe_mobile`)

### Feature `requests`

```
lib/features/requests/
├── data/
│   ├── request_api.dart
│   └── request_repository.dart
├── domain/
│   └── request_model.dart          (Freezed)
├── providers/
│   └── request_provider.dart
└── screens/
    ├── request_list_screen.dart
    ├── request_detail_screen.dart
    └── widgets/
        ├── request_tile.dart
        ├── request_media_section.dart
        └── classroom_picker_sheet.dart
```

### Modelo

- `RequestKind { student, parent }`.
- `RequestModel`: id, kind, fullname, email, phone, address, identityNumber,
  branch, year, status, childrenCount, children, media, createdAt.
- `RequestChild`: id, fullname, identityNumber, status, branch, year.
- `RequestMedia`: collectionName, fileName, mimeType, url.
- Parseo tolerante a respuestas planas y con `attributes`.

### Datos y providers

- `RequestApi`: lista, detalle por tipo y cuatro acciones.
- `RequestRepository`: parsea `PageResult<RequestModel>` y `RequestModel`,
  ejecuta acciones y traduce `DioException` a `ApiException`.
- `RequestListNotifier`: estado con página, búsqueda, status y tipo; carga,
  búsqueda con debounce, cambio de filtros, refresh, retry y paginación.
- `requestDetailProvider`: `FutureProvider.family` con una clave
  `({RequestKind kind, String id})`.
- `requestClassroomOptionsProvider`: `FutureProvider.family` con el texto de
  búsqueda; consulta `/classrooms?search=...&per_page=50` y devuelve
  `List<ClassroomModel>`.

### UI

- Lista con `LargeTitleBar`, `AppSearchBar`, chips de estado y tipo,
  `RequestTile`, `PaginationBar`, `ListShimmer`, `EmptyState` y `ErrorView`.
- Detalle con `LargeTitleBar`, tarjetas de datos (`InfoRow`), sección de
  documentación y sección de hijos para padres.
- Acciones con `PillButton` para aceptar y botón outlined para rechazar.
- Selector de curso en `showModalBottomSheet` usando
  `requestClassroomOptionsProvider` (búsqueda en servidor con debounce).
- Confirmaciones con `AlertDialog`.
- Después de una acción exitosa: `Navigator.pop(context, true)`, invalidar el
  detalle y refrescar la lista. Si el detalle del hijo se abrió desde un padre,
  también se invalida el detalle del padre al volver.

### Rutas y menú

- `/requests` -> `RequestListScreen`.
- `/requests/:kind/:id` -> `RequestDetailScreen`.
- `MenuSection.requests` visible solo para `admin`/`branch`.
- Actualizar los tests de matriz del menú (13 secciones en total).

### i18n

- Todas las etiquetas nuevas en ES/EN.
- Reutilizar `studentsInfo*`, `studentsSectionPersonal`,
  `studentsStatus*`, `studentsFilterAll`, `commonCancel` y `paginationShowing`
  cuando corresponda.

## Verificación

- Backend: `php -l` y `./vendor/bin/pint`; tests en CI o base descartable.
- Mobile: `flutter gen-l10n`, `flutter analyze`, `flutter test`.
- Prueba manual:
  - admin ve Solicitudes en el menú; padre/alumno/profesor no.
  - admin ve todas las sedes; sede solo ve las solicitudes de su sede.
  - lista pendiente combinada, búsqueda por nombre/email/DNI y filtros.
  - el filtro “Rechazadas” muestra solicitudes rechazadas aunque el usuario esté
    soft-deleted.
  - aprobar alumno con curso; verificar vínculo al aula.
  - aprobar tutor y luego aprobar un hijo; al volver, el detalle del tutor está
    actualizado.
  - rechazar alumno y tutor; verificar borrado de accesos.
  - solicitud ya aprobada no muestra acciones; una acción repetida responde
    `changed: false`.
  - el selector de curso encuentra cursos fuera de la primera página.
  - URLs de documentación abren correctamente.

## Decisiones dejadas al builder

- Nombres exactos de los métodos internos de los servicios backend, siempre que
  las firmas públicas coincidan con este documento.
- Composición visual fina de las tarjetas de detalle, respetando los widgets y
  el tema existentes.
- Textos exactos de los diálogos, respetando el tono y el contenido descrito.
