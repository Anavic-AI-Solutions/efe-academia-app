# Parent Home Resumen 1-Item Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar en `ParentHomeScreen` 3 secciones 1-ítem Documentos/Eventos/Novedades con Ver-todo.

**Architecture:** Nuevo `ParentSummarySections` (ConsumerWidget) debajo de `ParentQuickActions` que reutiliza `homeDocumentsProvider`, `homeCalendarProvider`, `newsListProvider` con `take(1)`; `ParentHomeScreen` solo lo inserta y extiende su `RefreshIndicator`. Sin backend, sin router nuevo, sin l10n nuevo.

**Tech Stack:** Flutter 3.x, Riverpod 2, go_router 14.8.1, phosphor_flutter, intl, AppColors/AppTypography/AppCard/SectionHeader/LoadingShimmer.

**Spec:** `docs/superpowers/specs/2026-10-13-padres-home-design.md` + decisiones de brainstorm: opción C, 1 ítem por sección, tap ítem abre detalle solo si existe (`/documents/:id`), Ver-todo siempre abre lista.

## Global Constraints

- No cambiar `efe-app` ni añadir rutas go_router; usar `/documents`, `/events`, `/news` existentes con `context.push`.
- Reutilizar claves l10n existentes verbatim: `documentsTitle`, `homeCalendar`, `homeNews`, `homeSeeAll` ("Ver todo"/"See all"), `documentsEmpty`, `homeCalendarEmpty`, `homeNewsEmpty`, `eventsEmptyTitle`.
- Seguir `HomeSummaryGrid` como patrón: fallback compacto por sección, nunca tumbar mora/hijos/otras secciones; `AppColors.backgroundFor(isDark)`, `AppCard`, `SectionHeader` con `padding: EdgeInsets.zero`.
- `flutter analyze` 0 issues, `flutter test` verde, l10n es/en sin claves nuevas.
- Commits por tarea, en español o inglés consistente con repo, un commit por tarea completada.

## Review Focus

- Padre sin hijos + secciones vacías: secciones siguen visibles con fallback compacto, no crashean por `relations` vacío.
- Backend viejo sin datos o lista vacía: `take(1)` sobre lista vacía muestra fallback, nunca index-out-of-range.
- Una fuente caída (ej. `/events` 500): solo esa sección muestra error acotado con retry, mora/hijos/otras secciones intactas.
- Tap en evento/news (sin detalle): debe ir a la lista, nunca a ruta inexistente `/events/:id` o `/news/:id`.
- Modo oscuro/claro: contraste y `accentFor/mutedFor` correctos en las 3 previews.

---

### Task 1: ParentSummarySections widget 1-ítem

**Files:**
- Create: `lib/features/dashboard/screens/widgets/parent_summary_sections.dart`
- Test: `test/dashboard/parent_summary_sections_test.dart`

**Interfaces:**
- Consumes: `homeDocumentsProvider` (`FutureProvider.autoDispose<List<DocumentModel>>`), `homeCalendarProvider` (`FutureProvider.autoDispose<List<EventModel>>`), `newsListProvider` (`StateNotifierProvider<NewsListNotifier, NewsListState>` con `pagination.data: List<NewsModel>`).
- Produces: `class ParentSummarySections extends ConsumerWidget { const ParentSummarySections({super.key}); }` usado por Task 2. Sin parámetros.

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('muestra 1 doc, 1 evento, 1 news con Ver-todo', (tester) async {
  await tester.pumpWidget(testableParentHome(overrides: [...]));
  await tester.pumpAndSettle();
  expect(find.text('Documentos'), findsOneWidget);
  expect(find.text('Calendario'), findsOneWidget);
  expect(find.text('Novedades'), findsOneWidget);
  expect(find.text('Ver todo'), findsNWidgets(3));
  expect(find.text('Contrato 2026'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dashboard/parent_summary_sections_test.dart -v`
Expected: FAIL with "ParentSummarySections not found / Unresolved"

- [ ] **Step 3: Implement `ParentSummarySections` en `lib/features/dashboard/screens/widgets/parent_summary_sections.dart`**

Estructura exacta: `Column` con 3 bloques; cada bloque `SectionHeader(title: l10n.documentsTitle/homeCalendar/homeNews, actionLabel: l10n.homeSeeAll, onAction: () => context.push('/documents|/events|/news'), padding: EdgeInsets.zero)` + `SizedBox(height: 8)` + body + `SizedBox(height: 16)`.
Body documentos: `homeDocumentsProvider.when(loading: shimmer h68, error: compact error con retry via ref.invalidate(homeDocumentsProvider), data: items.isEmpty ? Text(l10n.documentsEmpty) : DocumentTile(document: items.first, onTap: () => context.push('/documents/${items.first.id}')))`.
Body eventos: mismo patrón con `homeCalendarProvider`; preview `AppCard` con icono `calendarBlank`, título + fecha `DateFormat('MMM d, yyyy • HH:mm')`; `onTap: () => context.push('/events')` (sin detalle).
Body news: `ref.watch(newsListProvider)`; si `isLoading && empty` shimmer, si `empty` `Text(l10n.homeNewsEmpty)`, si no preview `AppCard` título + contenido maxLines 2; `onTap: () => context.push('/news')`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/dashboard/parent_summary_sections_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/screens/widgets/parent_summary_sections.dart test/dashboard/parent_summary_sections_test.dart
git commit -m "feat(parent-home): add 1-item summary sections"
```

### Task 2: Integrar en ParentHomeScreen + refresh

**Files:**
- Modify: `lib/features/dashboard/screens/parent_home_screen.dart:154-160`
- Modify: `test/dashboard/parent_home_screen_test.dart`

**Interfaces:**
- Consumes: `ParentSummarySections` de Task 1.
- Produces: Home padre con secciones visibles tras `ParentQuickActions`; refresh extendido.

- [ ] **Step 1: Write the failing integration test**

```dart
testWidgets('parent home muestra resumen tras acciones y refresca', (tester) async {
  await tester.pumpWidget(testableParentHome());
  await tester.pumpAndSettle();
  expect(find.byType(ParentSummarySections), findsOneWidget);
  await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
  await tester.pumpAndSettle();
  expect(find.byType(ParentSummarySections), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dashboard/parent_home_screen_test.dart -v -k "resumen"`
Expected: FAIL, no encuentra `ParentSummarySections`

- [ ] **Step 3: Implement integración en `lib/features/dashboard/screens/parent_home_screen.dart`**

Tras `ParentQuickActions(...)` añadir `const SizedBox(height: 8)` + `const ParentSummarySections()` + mantener `SizedBox(height: 24)`. Import: `import 'widgets/parent_summary_sections.dart';`. Extender `RefreshIndicator.onRefresh` a:
```dart
ref.invalidate(homeDocumentsProvider);
ref.invalidate(homeCalendarProvider);
await Future.wait([dashboard.refresh, relations.refresh, newsList.refresh]);
```
Añadir imports de `document_provider`, `event_provider`, `news_provider`. Sin tocar header, mora, hijos, navegación existente.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/dashboard/parent_home_screen_test.dart test/dashboard/parent_summary_sections_test.dart -v`
Expected: PASS

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/screens/parent_home_screen.dart test/dashboard/parent_home_screen_test.dart
git commit -m "feat(parent-home): integrate summary sections with refresh"
```
