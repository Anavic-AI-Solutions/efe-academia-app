# Pantalla Pagos de padres (etapa 2 de la experiencia de padres) — Diseño

**Fecha:** 2026-10-15
**Repos:** `efe_mobile` (Flutter, Riverpod 2, go_router 14.8.1) y `efe-app` (Laravel 11, API `/api/v1`)
**Estado:** diseño aprobado en conversación; pendiente de revisión de este spec.

## 1. Contexto

El mockup del usuario rediseña la pantalla Pagos (pestaña de padres creada en la etapa 1). Hoy:

- La pestaña Pagos (`/payments`, `lib/app/router.dart:287-290`) renderiza la `FeeListScreen` genérica: `LargeTitleBar` “Cuotas”, selector de hijo para padres y búsqueda; detalle (`/fees/:id`) de solo lectura con filas de información.
- El flujo del tutor ya existe en backend: `FeeController@uploadProof` (`app/Http/Controllers/Api/Fees/FeeController.php:244`) acepta jpg/jpeg/png/pdf ≤10 MB, marca `proof_status = under_review` y **notifica a administración** (“El tutor de … subió un comprobante”). `pay` (`:212`) es de caja (efectivo/depósito, `RECIBO|CAJA`) y `invoice` (`:262`) descarga el PDF del ingreso asociado (solo cuotas pagadas; 404 si falta).
- “Vencida” **no es un estado guardado**: se deriva (`SystemCollectionsFees::scopeInMora`, `app/Models/SystemCollectionsFees.php:235`: status `pending|partial` + `total > paid` + mes/año anteriores al actual).
- `GET /fees` filtra por rol (padre → cuotas de sus hijos, `applyRoleFilter`) pero **no tiene orden explícito** (paginación por cursor).
- **Hallazgo de seguridad:** los endpoints API de cuotas (`show`, `pay`, `update`, `uploadProof`, `invoice`, etc.) **no autorizan** — cualquier autenticado puede operar sobre cualquier cuota. El web usa rutas propias (`routes/web.php:187-188`), así que agregar autorización en la API no lo afecta.
- Móvil ya tiene `file_picker ^6.0.0`, `url_launcher ^6.3.1`, subida multipart (`lib/features/classrooms/data/material_repository.dart:152-155`) y sheet con picker inyectable para tests (`material_form_sheet.dart:35-54`).
- Plomería vieja de ids (etapa 1 §13): `fee_list_screen.dart` y `classroom_list_screen.dart` comparten `parentSelectedStudentProvider` (id de cuenta) y lo mandan como `student_id` (semánticamente incorrecto). El rediseño elimina ese filtro de cuotas.

## 2. Decisiones del usuario

| Pregunta | Respuesta |
|---|---|
| Acción del padre | **Ver + subir comprobante** (foto/PDF) → queda en revisión y administración aprueba. Incluye la policy de autorización. |
| Mockup | El provisto (header con Mora total, lista con estados, CTA “Subir comprobante”), con las adaptaciones de §7. |
| “Pagar” / CTA global | “Pagar” → **detalle** de la cuota; CTA global → **selector de cuota** (solo si hay 2+). |
| Factura | **Sí**: ver/descargar el PDF en cuotas pagadas. |

## 3. Objetivo

Que el padre vea todas las cuotas de sus hijos en una sola pantalla ordenada (vencidas → pendientes → pagadas) con la mora total, pueda subir/reemplazar el comprobante de pago desde la lista o el detalle (quedando en revisión para administración) y descargar la factura de las cuotas pagadas — con autorización correcta y sin cambios para otros roles.

## 4. Alcance y no-objetivos

**Dentro del alcance**

- Backend: `SystemCollectionsFeesPolicy` + aplicación en las rutas de la API; `is_overdue` en `FeeResource`; orden determinístico de `/fees`; `invoice-link` firmado + `invoice-file` público con `signed`; tests Pest (escritos, no ejecutados por AGENTS.md).
- Móvil: `ParentFeesScreen` (`/payments`), `ParentFeeDetailScreen` (`/payments/:id`), sheet de subida con picker + multipart, selector de cuota, modelo/API/repo/providers, l10n ES/EN, tests.
- Limpieza: ramas de padre del `FeeListScreen` (selector + listener + búsqueda para padres) y retiro de sus tests específicos.

**Fuera del alcance (diferido)**

- Pago online real / pasarela (no existe en el sistema).
- Notificaciones al padre (solo queda la notificación a administración que ya existe).
- Instrucciones/datos bancarios en la app (no existen en el sistema).
- Filtros o búsqueda en la pantalla Pagos (el mockup no los trae; multi-hijo se cubre con el nombre en la card).
- Listado de aulas de padres (queda como está; ya no es alcanzable por UI).
- Etapa 3 (Boletín).

## 5. Contrato backend

### 5.1 `SystemCollectionsFeesPolicy` (nueva)

| Ability | admin/branch | parent | student |
|---|---|---|---|
| `view` | ✓ todo | cuota de un hijo vinculado (misma relación que `applyRoleFilter`: `student` → padres → `ParentData.user_id`) | cuota propia (`student.student_app_id` → `StudentData.user_id`) |
| `uploadProof` | ✓ | ✓ (sus hijos) | ✗ |
| `downloadInvoice` | ✓ | ✓ (sus hijos) | ✓ (propia) |
| `update` / `pay` | ✓ | ✗ | ✗ |
| `manage` (generate, bulkUpdate, sendReminders, export) | ✓ | ✗ | ✗ |

Aplicación: `$this->authorize(...)` en `show`, `uploadProof`, `invoice`, `update`, `pay`, `generate`, `bulkUpdate`, `sendReminders`, `export`. Sin cambios en `index`/`stats`/`studentFees` (ya filtrados por rol).

### 5.2 `is_overdue`

- Método de instancia `SystemCollectionsFees::isInMora(): bool` con la misma regla del scope (status + total>paid + mes/año), calculado en PHP (sin SQL extra por fila).
- `FeeResource` expone `is_overdue` (bool).

### 5.3 Orden de `GET /fees`

Orden determinístico para la paginación: **vencidas (0) → pendientes/parciales no vencidas (1) → pagadas (2)**, luego `year` desc, `month` desc, `id` desc (desempate estable del cursor). Cambio deliberado del endpoint compartido (para admin, “pendientes primero” también es mejor); documentado en código.

### 5.4 Factura por URL firmada

- `GET /fees/{fee}/invoice-link` (autenticado + `downloadInvoice`): responde `{url}` con `URL::temporarySignedRoute('api.fees.invoice-file', now()->addMinutes(10), ['fee' => $fee->id])`.
- `GET /fees/{fee}/invoice-file` (público, middleware `signed`): streamea el PDF reusando la lógica actual de `invoice` (404 “Factura no disponible” si no está pagada o falta el PDF).
- `GET /fees/{fee}/invoice` queda como está (compatibilidad), ahora con policy.

### 5.5 Tests backend (Pest, escritos y **no ejecutados** — AGENTS.md)

Policy (padre solo sus hijos en `show`/`uploadProof`/`invoice`; 403 ajenos; alumno; admin), `is_overdue` (vencida/pendiente/pagada), orden de `/fees`, `invoice-link` firmado (URL con firma) e `invoice-file` (firma válida / firma manipulada → 403). Verificación local: `php -l`, `pint`, tinker.

## 6. Datos en Flutter

- `FeeModel` suma `proofStatus` (`proof_status`), `isOverdue` (`is_overdue`) y `owe` (para “Parcial · debe $X”).
- `FeeApi`/`FeeRepository`: `uploadProof(feeId, {bytes|path, filename})` → multipart campo `proof` a `POST /fees/{feeId}/upload-proof`; `getInvoiceLink(feeId)` → `GET /fees/{feeId}/invoice-link` (devuelve `url`).
- Provider nuevo `parentFeesProvider` (cursor, sin filtros ni búsqueda) para la pantalla de padres; `feeListProvider` queda para los demás roles.
- `FeeListScreen`: se eliminan las ramas de padre (listener de `parentSelectedStudentProvider`, selector de hijo, estado vacío especial) y su búsqueda queda solo para los otros roles. `parentSelectedStudentProvider` queda únicamente para el listado de aulas (no se toca).

## 7. UI — Pantalla Pagos (`ParentFeesScreen`)

1. **Header** (gradiente, `GradientHeader` con contenido propio): título “Cuotas” (14/w800 `onPrimary`) **sin flecha de volver** (raíz de pestaña) + tile centrado “Mora total” (10 `onPrimaryMuted`) + monto (22/w900 `onPrimary`) sobre `overlay` blanco 12%, radius 14. El tile se **oculta si la mora es 0**. Dato: `dashboardProvider` (`ParentHomeData.moraTotal`); el pull-to-refresh refresca cuotas y dashboard.
2. **Lista** (orden del server), card por cuota (r13, padding 11/13, patrón `AppCard`):
   - Título “Julio 2026” (12/w800 `inkFor`).
   - Línea 1 (10/w700, etiquetas existentes del sistema): **Vencido · $monto** (`dangerInk`) · **Pendiente · $monto** (`mutedFor`) · **Parcial · debe $X** (`dangerInk` si vencida, `mutedFor` si no) · **En revisión · $monto** (`primary`, sin acción) · **Pagado** (`present`).
   - Línea 2 (10 `mutedFor`): nombre del hijo.
   - Acción: pill **Pagar** (`dangerInk` claro / `darkDangerInk` oscuro, texto blanco/`darkDangerSoft`, r9) para vencida/pendiente/parcial; **✓** `present` para pagada; nada para en revisión.
   - Tap en card o pill → `/payments/{id}`.
3. **CTA inferior** “Subir comprobante” (`PillButton` `primary`, r13/h46) fija al pie del body: 1 cuota accionable → sheet de subida directo; 2+ → selector de cuota; 0 → no se muestra. “Accionable” = status `pending`/`partial` y `proof_status != under_review`.
4. **Estados**: shimmer (header + 3 cards), `ErrorView(feesLoadError)` + retry, vacío `EmptyState(feesEmptyTitle)`, load-more al scrollear, pull-to-refresh.
5. Montos con `AppFormatters.formatCurrency` (R9: `1.300.000,00 $`).

**Adaptaciones documentadas vs mockup**: sin flecha (raíz de pestaña); tile de mora oculto con 0; pill Pagar en `dangerInk` (contraste ≥4.5:1; el `#E05353` del mockup no pasa con texto blanco); CTA con `PillButton` `primary` (el `#5F92C9` del mockup no pasa con texto blanco); nombre del hijo en la card (multi-hijo); estados Pendiente/En revisión/Parcial diseñados por nosotros (el mockup solo muestra Vencida y Pagada); **etiquetas de estado del sistema (“Vencido”/“Pagado”, no “Vencida”/“Pagada” del mockup) por consistencia con los badges de cuotas del resto de la app**.

## 8. UI — Detalle y sheets

**`ParentFeeDetailScreen` (`/payments/:id`, empujada dentro del branch — la barra sigue en Pagos)**
- `ScreenHeader` con volver + `feesDetailTitle(number)`.
- Card: hijo, mes/año, estado (badge), montos (a pagar / pagado / total / debe si parcial), estado del comprobante (fila “Comprobante: En revisión” si `under_review`), método/fecha si pagada.
- Acciones: **Subir comprobante** (no pagada) / **Reemplazar comprobante** (`under_review`; el backend borra el anterior no aprobado) y **Ver factura** (pagada; `invoice-link` → `url_launcher` externo; 404 → snackbar `feesInvoiceUnavailable`).

**`ParentFeeProofSheet`** (modal)
- Contexto de la cuota (mes · hijo · monto) + “Elegir archivo” (FilePicker jpg/jpeg/png/pdf; validación cliente ≤10 MB; picker inyectable para tests) + preview (nombre y tamaño) + botón Subir con spinner.
- Éxito: pop + invalidate de `feeDetailProvider`/`parentFeesProvider` + snackbar con `feesProofSuccess` (copy propio; no se muestra el mensaje crudo del backend). 422 → mensaje inline; error de red → mensaje con reintentar.

**Selector de cuota** (solo CTA con 2+): filas hijo · mes/año · monto/estado → abre el sheet de subida.

## 9. Navegación

- `/payments` → `ParentFeesScreen` (branch 1, `initialLocation` de padres ya existe desde la etapa 1). `/payments/:id` anidada bajo `/payments` (push dentro del branch).
- `/fees` y `/fees/:id` quedan para los demás roles sin cambios. El home ya navega a la pestaña (`go('/payments')`).

## 10. i18n

Nuevas claves ES/EN: `feesUploadProofAction` (“Subir comprobante” / “Upload receipt”), `feesReplaceProofAction` (“Reemplazar comprobante” / “Replace receipt”), `feesInvoiceAction` (“Ver factura” / “View invoice”), `feesInvoiceUnavailable` (“Factura no disponible” / “Invoice unavailable”), `feesChooseFeeTitle` (“Elegí la cuota” / “Choose the installment”), `feesProofStatusReview` (“Comprobante en revisión” / “Receipt under review”), `feesProofPickFile` (“Elegir archivo” / “Choose file”), `feesProofHint` (“JPG, PNG o PDF · hasta 10 MB” / “JPG, PNG or PDF · up to 10 MB”), `feesProofSuccess` (“Comprobante subido. Un administrador lo revisará.” / “Receipt uploaded. An administrator will review it.”), `feesProofError` (fallback de error de subida). Se reutilizan `feesTitle`, `parentMoraTotal`, `parentPayAction`, `feesStatusPaid/Pending/Partial`, `feesDetail*`, `feesLoadError`, `feesEmptyTitle`, `commonRetry`.

## 11. Testing y verificación

**Flutter**
- Unit: parseo `proofStatus`/`isOverdue`/`owe`; `uploadProof` multipart (método, URL, campo `proof`, filename); `getInvoiceLink`.
- Widget: `ParentFeesScreen` (orden vencidas→pendientes→pagadas; 5 variantes de card; nombre del hijo; mora con/sin; CTA 1→directo / 2+→selector / 0→oculta; tap card y pill → detalle; vacío/error/loading; load-more); `ParentFeeDetailScreen` (acciones según estado; reemplazar en revisión; factura solo pagada; 404 → snackbar); `ParentFeeProofSheet` (picker inyectable; validación tipo/tamaño; éxito → pop + invalidaciones; 422 inline); selector; navegación `/payments/:id` con shell real (nav queda en Pagos).
- Actualizar/retirar `test/fees/fee_parent_scope_widget_test.dart` (y lo que aplique de `fee_list_notifier_test`/`fee_repository_test`).
- Comandos: `flutter gen-l10n`, `flutter analyze` (sin issues nuevos), `flutter test` verde.

**Backend (`efe-app`)**
- Pest por §5.5 (escritos, **no ejecutados**). Verificación: `php -l`, `pint`, y tinker contra `dev-efe` (policy con un padre real; `is_overdue` del resource; orden de la query; link firmado).

## 12. Riesgos y decisiones

- **Autorización**: se cierra el hueco de los endpoints de cuotas (hoy sin policy). El web no se toca (rutas propias).
- **Orden compartido de `/fees`**: cambia para admin (pendientes primero). Deliberado; se documenta en código y tests.
- **`is_overdue` duplica la regla del scope** en PHP (una consulta por fila menos); comentario cruzado y test Pest que pinnea ambos.
- **Factura firmada**: depende de `APP_URL` correcta en producción (ya configurada para notificaciones); firma de 10 minutos, uso inmediato.
- **Reemplazo de comprobante**: re-subir con `under_review` es válido (el backend borra el anterior no aprobado).
- **Pest no ejecutable localmente**: los tests quedan para CI; verificación local con tinker.

## 13. Criterios de éxito

1. El padre ve todas las cuotas de sus hijos ordenadas vencidas → pendientes → pagadas, con hijo y estado por card y la mora total en el header (oculta con 0).
2. “Pagar” abre el detalle; el detalle permite subir/reemplazar comprobante y ver la factura de las pagadas.
3. La CTA global pide cuota solo si hay más de una accionable; con una sola va directo.
4. El comprobante subido queda “en revisión”, administración recibe la notificación, y la app refleja el estado al refrescar.
5. Policy activa: un padre no puede ver/subir/facturar cuotas ajenas; admin/sucursal sin cambios; alumno solo las propias.
6. Otros roles y `/fees` intactos; `flutter analyze` sin issues nuevos y `flutter test` verde; ES/EN; claro/oscuro.

## 14. Etapa siguiente (fuera de este spec)

- **Etapa 3 — Boletín:** pantalla de boletín por hijo/aula (`GET /qualifications/boletin/{studentId}/{classroomId}`) con notas y promedios; la acción “Boletín” del home pasa a abrirla.
