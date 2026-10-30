# Estados normalizados y materiales del profesor — Diseño

**Fecha:** 2026-10-07
**Repos:** `efe_mobile` (Flutter 3.x, Riverpod 2, go_router 14) y `efe-app` (Laravel 11, API `/api/v1`)

## 1. Contexto

Dos correcciones sobre EFE Mobile:

1. El estado del alumno llega crudo desde la API (`approved`, `pending`, `rejected`) y se muestra tal cual ("approved") en la lista de alumnos, la pestaña Alumnos del aula y el hero del detalle. Lo mismo pasa con cuotas (`paid`, `partial`, `pending`) y el estado de faltas.
2. Los profesores no pueden cargar materiales en sus aulas: la pestaña Materiales del detalle de aula es de solo lectura (listado paginado sin acciones).

Hallazgos relevantes:

- El backend ya expone `GET /classrooms/{id}/materials`, `POST /materials`, `PATCH /materials/{id}`, `POST /materials/{id}/upload`, `GET /materials/{id}`, `DELETE /materials/{id}`, pero:
  - `StoreMaterialRequest` acepta un solo `file`, no acepta `student_ids` y limita a 10 MB.
  - `MaterialPolicy` deja crear/editar a cualquier profesor (sin acotar a aulas asignadas), permite `view` a cualquier profesor y **solo admin/branch pueden borrar**.
  - `destroy` no limpia la colección de media (deja archivos huérfanos).
- La creación web (`Materials/Create.jsx`) usa: nombre, categoría (6 valores fijos de `Material::CATEGORIES`), descripción, `files[]` (hasta 10), visibilidad `all|specific` con `student_ids`, y `available_until`. Su edición no está implementada (la ruta `classrooms.materials.update` apunta a un método inexistente); no es parte de este trabajo.
- La app ya tiene `file_picker`, `open_file` y `ApiClient.upload(FormData)`; no hacen falta dependencias nuevas.
- Patrones propios del producto a reutilizar: `CreateQualificationSheet` (bottom sheet de formulario con validación y `pop(true)`), barra inferior de acción de la pantalla de Notas, `AppCard` + `StatusBadge`, `PagedTabList` + `PagedListNotifier`, `ApiException`, fakes manuales de repositorio en tests.
- El listado de aulas del profesor ya está acotado a sus aulas asignadas en la API, y `ClassroomsPolicy::view` ya valida la asignación para el detalle.

## 2. Objetivo

- **Parte A:** mostrar los estados de alumnos, cuotas y faltas normalizados y localizados (ES/EN), con color coherente, sin cambiar los datos que devuelve la API.
- **Parte B:** permitir que un profesor cree, edite, elimine y suba archivos de material en la pestaña Materiales de sus aulas asignadas (mismo alcance para admin/branch), con paridad de campos respecto de la creación web.

## 3. Alcance y no-objetivos

**Dentro del alcance**

- Helper compartido de etiquetas de estado y su uso en: alumnos (`StudentCard`, `StudentTile`, `StudentDetailHeader`), cuotas (`FeeCard`, `FeeTile`, `FeeDetailScreen`) y faltas (`AbsenceTile`). Centralización de `classroomStatusLabel`.
- Backend: policy de materiales acotada por asignación y borrado permitido al profesor; requests y controlador con `files[]`, `student_ids`, categorías válidas, visibilidad y `available_until`.
- Mobile: `MaterialApi` + `MaterialRepository` + modelo con `studentIds`; pestaña Materiales con CTA de carga, menú por ítem (editar/eliminar), formulario completo (crear/editar) y confirmación de borrado.

**Fuera del alcance (explícito)**

- Notificación a los alumnos al publicar un material (la web las manda por su controlador; el API no). Otra iteración.
- Descargar o abrir el material desde la app (el tile no abre nada hoy).
- Biblioteca global de materiales (`/library`), asignaciones/tareas derivadas de un material.
- Panel web de `efe-app` (incluida su edición rota de materiales).
- Buscador/filtros por categoría dentro de la pestaña Materiales (la web los tiene; no fueron pedidos).

## 4. Parte A — Estados normalizados

### 4.1 Helper

Nuevo `lib/core/utils/status_labels.dart` con funciones puras que reciben `AppLocalizations`:

- `String studentStatusLabel(String status, AppLocalizations l10n)`
- `String feeStatusLabel(String status, AppLocalizations l10n)`
- `String absenceStatusLabel(String status, String justified, AppLocalizations l10n)`
- `String classroomStatusLabel(String status, AppLocalizations l10n)` — se muda desde `classroom_filter_sheet.dart` (mismos textos).

Reglas comunes: se compara en minúsculas; un valor desconocido devuelve el valor crudo; un valor vacío devuelve `''` (los widgets ocultan el badge).

### 4.2 Mapeos

| Origen  | Valor API     | ES            | EN         | Color          |
|---------|---------------|---------------|------------|----------------|
| Alumno  | `approved`    | Aprobado      | Approved   | success        |
| Alumno  | `pending`     | Pendiente     | Pending    | warning        |
| Alumno  | `rejected`    | Rechazado     | Rejected   | error          |
| Cuota   | `paid`        | Pagado        | Paid       | success        |
| Cuota   | `partial`     | Parcial       | Partial    | warning        |
| Cuota   | `pending`     | Pendiente     | Pending    | warning        |
| Cuota   | `overdue`     | Vencido       | Overdue    | error          |
| Falta   | `pending`     | Pendiente     | Pending    | warning        |
| Falta   | `justified`   | Justificada   | Justified  | success        |
| Falta   | `unjustified` | Sin justificar| Unjustified| error          |
| Aula    | `active`      | Activo        | Active     | success        |
| Aula    | `archived`    | Archivado     | Archived   | error          |

- `absenceStatusLabel`: si `status` está vacío, cae al heurístico actual sobre `justified` (`studentsAbsenceJustified` / `studentsAbsenceUnjustified`).
- Nota: `pending` comparte la palabra "Pendiente" entre alumnos, cuotas y faltas; se usan claves ARB distintas por dominio para permitir ajustes futuros.

### 4.3 Widgets

- `StatusBadge` suma `String? label`: el texto mostrado es `label ?? status`, y el color se calcula con el valor **crudo** (`colorFor(status)`), extendido con `rejected` → error. Los llamadores existentes no cambian.
- `StudentCard`: elimina su `_StatusBadge` privado; usa `StatusBadge(status: student.status, label: studentStatusLabel(...))` y oculta el badge si el estado está vacío.
- `StudentTile` y `StudentDetailHeader`: pasan la etiqueta normalizada (`DetailHero.status` recibe el texto ya localizado).
- `FeeCard`: elimina su `_StatusBadge` privado; usa el compartido con etiqueta.
- `FeeTile` y `FeeDetailScreen` (`_InfoRow` de estado): etiqueta normalizada.
- `AbsenceTile`: reemplaza `_isJustified` por `absenceStatusLabel(absence.status, absence.justified, l10n)` con color por estado (pendiente ámbar, justificada verde, sin justificar rojo).
- `classroom_filter_chips.dart`, `professor_classroom_list_card.dart` y `classroom_filter_sheet.dart`: actualizan el import de `classroomStatusLabel`.

### 4.4 l10n (ARB es/en + `flutter gen-l10n`)

Nuevas: `studentsStatusApproved`, `studentsStatusPending`, `studentsStatusRejected`, `feesStatusPaid`, `feesStatusPartial`, `feesStatusPending`, `feesStatusOverdue`, `studentsAbsencePending`.
Reutilizadas: `studentsAbsenceJustified`, `studentsAbsenceUnjustified`, `classroomsStatusActive`, `classroomsStatusArchived`.

## 5. Parte B — Materiales del profesor

### 5.1 Backend (`efe-app`)

**Policy `MaterialPolicy`** (profesor = solo aulas asignadas vía `classroom_professor`):

| Acción   | admin/branch | profesor                                                    | alumno/padre (sin cambios) |
|----------|--------------|-------------------------------------------------------------|----------------------------|
| `view`   | todo         | material de aula asignada                                   | ya acotado por aula        |
| `create` | todo         | `classroom_id` de aula asignada                             | no                         |
| `update` | todo         | material de aula asignada                                   | no                         |
| `delete` | todo         | material de aula asignada                                   | no                         |

- Para `create` se agrega un argumento extra al authorize: `$this->authorize('create', [Material::class, $validated['classroom_id']])` y `create(User $user, ?string $classroomId = null)`.

**Requests del API**

`StoreMaterialRequest`:

- `name`: `required|string|max:255`
- `description`: `nullable|string|max:1000` (alineado con la web)
- `type`: `nullable|string|max:255`
- `category`: `nullable|string|in:` + `Material::CATEGORIES`
- `classroom_id`: `required|string|exists:classrooms,id`
- `visibility`: `nullable|in:all,specific`
- `available_until`: `nullable|date|after:now`
- `student_ids`: `required_if:visibility,specific|array`; `student_ids.*`: `exists:student_data,id`
- `files`: `nullable|array|max:10`; `files.*`: `file|max:51200` (50 MB); `file`: legado `nullable|file|max:51200`

`UpdateMaterialRequest`: mismos campos en modo `sometimes`/`nullable`, sin `classroom_id`; `student_ids` `nullable|array`.

**Controlador `Api\Materials\MaterialController`**

- `store`: crea el material (clase + campos), adjunta todos los `files[]` (o el `file` legado) a la colección `materials`, `public_url` = URL del primer archivo, y sincroniza `student_ids` si `visibility=specific`. Devuelve 201 con el resource.
- `update`: actualiza metadatos; si `visibility=all`, desvincula alumnos (`detach`); si `visibility=specific` y vienen `student_ids`, sincroniza; si no vienen, mantiene los actuales.
- `upload`: acepta `file` o `files[]`; limpia la colección y adjunta el set; actualiza `public_url`.
- `destroy`: `clearMediaCollection('materials')` + `delete()`.
- Sin notificaciones (fuera de alcance).
- **Listado del aula** (`ClassroomController@materials`): precarga `students:id` (sin columnas extra) para que cada material del listado exponga sus `studentIds` y el tile pueda mostrar el conteo de destinatarios.

**Tests backend (Pest, escritos y no ejecutados en este entorno)**

- Policy: profesor asignado/no asignado para `view`, `create`, `update`, `delete`; admin sin restricción.
- `store` con `files[]` + `student_ids`; `update` de `visibility` a `all` desvincula; `destroy` limpia media.
- Verificación: `./vendor/bin/pint` y `php -l`. El repo prohíbe `php artisan test`/Pest (borran la base de desarrollo).

### 5.2 Mobile

**Modelo**

- `MaterialModel` (freezed): agrega `@Default([]) List<String> studentIds`, parseado tanto de `relationships.students.data[].id` (respuesta de `GET /materials/{id}`) como de un array `students` (listado del aula). Requiere `dart run build_runner build --delete-conflicting-outputs`.
- Nuevo `materialTypeFor(String fileName)`: deriva `type` de la extensión (`pdf`, `image`, `video`, `audio`, `link`, `other`) para que `MaterialTile` muestre el ícono correcto.

**Datos**

- Nuevo `lib/features/classrooms/data/material_api.dart`:
  - `createMaterial(FormData)` → `POST /materials`
  - `updateMaterial(String id, Map<String, dynamic> data)` → `PATCH /materials/{id}`
  - `replaceFiles(String id, FormData)` → `POST /materials/{id}/upload`
  - `deleteMaterial(String id)` → `DELETE /materials/{id}`
  - `getMaterial(String id)` → `GET /materials/{id}`
- Nuevo `lib/features/classrooms/data/material_repository.dart`: mapea a `MaterialModel`, maneja `DioException` → `ApiException` como el resto de los repositorios.
- Nuevo provider `materialRepositoryProvider` (en `lib/features/classrooms/providers/material_provider.dart`).
- La lista sigue usando `ClassroomRepository.getClassroomMaterials` y `classroomMaterialsProvider` (no se toca ningún fake existente).

**UI**

- `ClassroomMaterialsTab({classroomId, canManage})`: si `canManage`, agrega barra inferior "Cargar material" (mismo patrón que `_LoadGradeBar` de Notas), visible también con lista vacía.
- `MaterialTile({material, canManage, onEdit, onDelete})`: para `canManage`, botón "⋮" con menú **Editar**/**Eliminar**; chip "N alumnos" cuando `visibility == 'specific'` (usa `studentIds.length` que ahora viene en el listado).
- `MaterialFormSheet` (nuevo, bottom sheet como `CreateQualificationSheet`):
  - Título "Nuevo material" / "Editar material".
  - Nombre (obligatorio), Categoría (dropdown con las 6 de `Material::CATEGORIES`), Descripción.
  - Archivos: `file_picker` con `allowMultiple: true` (bytes en web); chips de nombre + tamaño; en crear, mínimo 1 archivo; en editar, opcional (si se eligen, se reemplaza el set completo).
  - Visibilidad: "Todos" / "Alumnos específicos"; al elegir específicos, lista de alumnos del aula con checkbox (se traen todas las páginas del endpoint de alumnos, patrón de la grilla de notas).
  - "Disponible hasta": fecha + hora opcional, con acción para limpiar.
  - Validación cliente: 1–10 archivos, 50 MB por archivo; errores inline y error de envío al pie; guardar con spinner; éxito → `pop(true)`.
- Editar: el sheet carga `GET /materials/{id}` para obtener metadatos y `studentIds` (spinner mientras carga).
- Flujos:
  - Crear: `POST /materials` (multipart, `files[]`) → `invalidate(classroomMaterialsProvider)` + snackbar "Material publicado".
  - Editar: `PATCH` (JSON) y, si hay archivos nuevos, `POST /materials/{id}/upload` (`files[]`) → snackbar "Material actualizado". Al reemplazar archivos se recalcula `type` con el primer archivo nuevo.
  - Eliminar: `AlertDialog` de confirmación ("también se borran sus archivos") → `DELETE` → snackbar "Material eliminado".
  - Errores de red o 403 → snackbar de error con el mensaje del `ApiException`.
- Permisos de UI: `canManage = role == 'professor' || roles.contains('admin') || roles.contains('branch')` (se expone como extensión de `UserModel`). El backend es la fuente de verdad.
- Textos nuevos en ARB es/en (`materialForm*`, `materials*`, acciones y confirmación).

### 5.3 Contratos

```
POST   /api/v1/materials                multipart: name, description?, type?, category?,
                                         classroom_id, visibility?, available_until?,
                                         student_ids[]?, files[] (1..10, ≤50MB)
PATCH  /api/v1/materials/{id}           JSON: name?, description?, type?, category?,
                                         visibility?, available_until?, student_ids[]?
POST   /api/v1/materials/{id}/upload    multipart: files[] (reemplaza el set) o file (legado)
DELETE /api/v1/materials/{id}           borra material y su media
GET    /api/v1/materials/{id}           detalle con students vinculados
```

## 6. Testing y verificación

**Mobile**

- Unit: etiquetas de estado (todos los valores + desconocidos + vacío + fallback de faltas), `materialTypeFor`.
- Widget: alumno/cuota/falta muestran etiquetas normalizadas; pestaña Materiales (profesor ve CTA y menú, alumno no), validaciones del sheet, visibilidad específica, crear/editar/eliminar contra un fake de `MaterialRepository` con refresco de lista y snackbars.
- Comandos: `flutter gen-l10n`, `flutter analyze` (0 issues), `flutter test` (suite completa en verde).

**Backend**

- Pest escrito (no ejecutado por la regla del repo), `./vendor/bin/pint`, `php -l`.
- Prueba funcional manual contra la API dev con usuario profesor (crear, editar, reemplazar archivos, eliminar; 403 en aula no asignada).

## 7. Riesgos y decisiones tomadas

- **PHP no parsea multipart en PATCH**: la edición separa metadatos (PATCH JSON) de archivos (`POST /upload`).
- **Timeouts de Dio (15 s)**: el request de subida usa `Options` con timeout mayor.
- **Sin deshacer en el borrado**: se mitiga con diálogo de confirmación.
- **Tests Pest no ejecutables acá**: se compensa con revisión, `pint`/`php -l` y prueba manual.
- **Límite de archivos**: 50 MB por archivo y 10 archivos (paridad con el diseño de API y la web).
- **Notificaciones a alumnos**: explícitamente fuera de alcance.
- **Edición web rota**: no se arregla; el CRUD queda operativo desde la app.

## 8. Criterios de éxito

1. En la app no vuelve a verse "approved"/"paid"/"pending" crudos: todos los estados listados se ven en el idioma activo con el color correcto, y un valor desconocido se ve tal cual sin romper.
2. Un profesor puede publicar un material con varios archivos, categoría, visibilidad general o específica, y disponible hasta; editarlo; reemplazar sus archivos; y eliminarlo, todo desde la pestaña Materiales de una de sus aulas.
3. Un alumno/padre sigue viendo la pestaña sin acciones de administración.
4. Un profesor recibe 403 si intenta crear/editar/borrar material de un aula que no tiene asignada.
5. `flutter analyze` limpio y `flutter test` en verde con los tests nuevos.
