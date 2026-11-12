# Selector de modo por rol — Diseño

**Fecha:** 2026-11-12
**Estado:** Aprobado
**Repos:** `efe_mobile` (Flutter) + `efe-app` (Laravel API)

## Intención

Un usuario con varios roles reales —por ejemplo profesor y padre— puede elegir
con qué rol usar la app. El modo cambia **el alcance de los datos y la UI**, no
los permisos. Es el equivalente móvil del `RoleSwitcher` de la web, pero
genérico para cualquier rol que el usuario tenga realmente.

## Objetivos

- Mostrar el selector solo cuando el usuario tiene **2 o más roles reales**.
- Al cambiar de modo, usar el rol activo en home, tab central, menú, perfil,
  aulas, alumnos, cuotas, chat, estadísticas y búsqueda.
- Persistir el modo mientras dure el token: reiniciar la app lo mantiene.
  Cerrar sesión vuelve al rol primario.
- No cambiar el comportamiento de la web.

## No objetivos

- No crear homes nuevos para admin, branch o alumno: usan el dashboard genérico
  existente.
- No convertir el modo en una frontera de seguridad. Las policies y los
  chequeos de permiso siguen usando los roles reales.
- No auto-cambiar de modo al tocar un push en esta versión.
- No rediseñar pantallas fuera del selector.

## Anti-objetivos

- Que un padre vea “Modo Alumno” por el rol fantasma de `current_selected_id`.
- Que un cambio de modo en el móvil borre el hijo seleccionado que usa la web.
- Que el modo profesor muestre datos de padre o viceversa.

## Enfoque elegido

**Modo activo por token.** Se agrega `active_role` a `personal_access_tokens` y
`User::activeRole()` resuelve token → sesión web → rol primario. El modo queda
atado a la sesión de ese dispositivo, sobrevive reinicios y todas las requests
lo usan sin plomería extra.

Alternativas descartadas:

- **Header `X-Active-Role` por request:** sin migración, pero cada request
  (subidas, websocket, etc.) debe llevarlo y un olvido cae al rol primario.
- **Columna `active_role` en `users`:** mezcla el modo del móvil con la web y
  puede filtrar un cambio de un dispositivo a otro.

## Decisiones

1. El selector ofrece solo roles reales. El alumno fantasma de los padres queda
   afuera del selector y de `roles` en la API móvil. La web no cambia.
2. Cambiar a profesor, admin o branch **no limpia** `current_selected_id`.
   Cambiar a padre setea el primer hijo solo si la selección actual es inválida.
   Cambiar a alumno setea el registro propio del usuario.
3. Admin, branch y alumno usan el dashboard genérico. No se construyen homes
   nuevos.
4. Los push no cambian de modo en esta versión. La lista de notificaciones sigue
   siendo del usuario, no del modo.
5. El modo vive en el token: sobrevive reinicios, pero cerrar sesión vuelve al
   rol primario.

## Backend

### Fundación

- Migración: `active_role` nullable en `personal_access_tokens`.
- `App\Models\PersonalAccessToken` con los `$fillable` base de Sanctum más
  `active_role`, registrado con `Sanctum::usePersonalAccessTokenModel()`.
- `User::activeRole()`:
  - token real y persistido con `active_role` válido → ese rol;
  - si no, sesión web con `active_role` válido → ese rol;
  - si no, `role()` primario.
  - Ignora `TransientToken` y los tokens mock de tests.
- `User::getSwitchableRoles()`: solo roles reales.
  - `professor` si existe `professorData`.
  - `parent` si existe `parentData`.
  - `admin` / `branch` si `userData.role` es uno de esos.
  - `student` si existe `StudentData` con `user_id = user.id`.
  - Excluye `user` y el alumno fantasma.
- `User::realStudentData()`: `StudentData::where('user_id', $user->id)->first()`.

### Endpoint

`POST /api/v1/user-data/switch-role` (ya existe; se modifica):

- Valida `role` contra `getSwitchableRoles()`; si no, 422.
- Guarda `active_role` en el token actual y, si existe sesión, en la sesión.
- Ajusta `current_selected_id` según la decisión 2.
- Devuelve `{role, roles, selected_student_id}`.

### Respuestas de autenticación

- `/auth/me`, `/profile` (show y update), login y register devuelven `role`
  efectivo y `roles` = `getSwitchableRoles()`.
- `/auth/refresh` conserva `active_role` en el token nuevo.

### Scoping

Pasan a `activeRole()` (esto es alcance de datos, no autorización):

- `StatisticsController::dashboard` y `::fees`
- `ClassroomController::scopeToRole`
- `StudentController::applyRoleFilter`
- `FeeController::index` (rama parent) y `applyRoleFilter`
- `MaterialController` (dos bloques de scope)
- `ObservationController`
- `QualificationController` (visibilidad y scopes de listado)
- `ParentController`
- `HomeworkController`
- `AbsenceController`
- `ProfessorController`
- `BirthdayService` (default)
- `ChatQueryService`: el bypass de admin para listar chats y sugerencias pasa a
  `activeRole()`.

`ChatController` / `MessageController` conservan el bypass de admin: el modo no
es una frontera de seguridad.

### Policies

Solo se corrige el bug de multi-rol: en `ClassroomsPolicy::view` y
`MaterialPolicy::view`, la rama profesor devuelve `true` únicamente si está
asignado; si no, continúa con las ramas parent/student en vez de cortar con
`false`. El resto de las policies sigue con roles reales.

## App

### Estado

- `RoleModeApi` + `RoleModeRepository`, separados de `AuthRepository` para no
  romper los fakes existentes.
- `RoleSwitchController` con estado propio `idle / switching / error`. No
  contamina `AuthState`.
- `AuthNotifier.applyActiveRole(role, roles)` actualiza solo el usuario.
- `UserModel.canManageMaterials` mira solo el rol activo.

### UI

- Chip “Modo X” en `HomeHeader` (nuevo parámetro `badge`), cableado en los tres
  homes: profesor, padre y dashboard genérico. Va debajo de la fila del título.
- Sección “Modo” en Perfil con el modo actual y “Cambiar modo”.
- Ambos abren una hoja con todos los roles reales, check en el actual,
  descripción corta por rol, estados de carga/error y bloqueo de doble tap.
- Éxito: cerrar la hoja, snackbar “Ahora estás en modo X” y
  `context.go('/dashboard')`.
- Error: la hoja queda abierta con el mensaje y permite reintentar.
- Strings es/en y regeneración de localizaciones.

### Navegación

- `routerProvider` observa solo `AuthStatus`, no todo `AuthState`, para que el
  switch no recree el `GoRouter` ni reinicie push/FCM.
- Se elimina `isParent` del branch 1. El tab central va explícitamente a
  `/payments` o `/classrooms` al tocarlo, según el rol activo.
- `classroom_history_screen` resetea su `_didInitialLoad` cuando cambia el rol.
- Orden del switch: API → actualizar auth → resetear hijo → invalidar providers
  → navegar.

### Providers a invalidar

relations, aulas (lista, filtros, detalle, alumnos, profesores, materiales),
alumnos (lista, detalle, aulas, ausencias, cuotas), cuotas (lista, padre,
detalle), calificaciones/boletín, chat (lista, no leídos, mensajes),
notificaciones/no leídos, documentos, eventos, noticias y búsqueda.

### Errores

`ErrorInterceptor` debe leer `data['error']['detail']` del `ApiResponder` para
mostrar el motivo real del 422.

## Casos borde

- Un solo rol o rol desconocido: no aparece el chip ni la sección.
- El rol guardado en el token deja de existir: `activeRole()` cae al primario.
- 401 durante el switch: snackbar y se mantiene el modo actual.
- Varios dispositivos: el modo es por token; `current_selected_id` no se borra.
- Push y deep links no cambian de modo en esta versión.

## Verificación

- Backend: migración, `pint` y prueba HTTP real con una cuenta multi-rol.
  Los tests de persistencia usan token real, no `Sanctum::actingAs`.
- App: `flutter analyze`, `flutter test` y prueba manual en 320 px.
- Tests nuevos para el controller, el chip, la hoja y el cambio de home.
