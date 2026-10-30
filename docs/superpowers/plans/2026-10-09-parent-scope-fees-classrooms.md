# Parent Scope (Hijos + Cuotas + Aulas) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La vista padre muestra sus hijos y opera filtrada por hijo seleccionado; cuotas navegan y aulas ya no muestran todas.

**Architecture:** Reutilizar flujos existentes sin backend nuevo: `relations` como fuente de hijos, `StateProvider` para hijo seleccionado, `student_id` como scope en fees/classrooms, y rutas `/fees` faltantes en `GoRouter`.

**Tech Stack:** Flutter + flutter_riverpod ^2.5.0 + go_router ^14.0.0 + dio ^5.4.0 + flutter_test

**Spec:** Diseño en chat aprobado 2026-10-09: (1) Hijos + ficha hijo, (2) cuotas no navega, (3) aulas filtrar por hijo. Sin spec file separado (bounded).

## Global Constraints

- Dart SDK `>=3.5.0 <4.0.0`, `flutter generate: true` para l10n.
- No nuevas dependencias; solo `flutter_riverpod`, `go_router`, `dio` ya declaradas.
- Copy en español vía `AppLocalizations` (`context.l10n`), no strings hardcodeados visibles.
- Reutilizar sistema UI existente: `HomeHeader`, `EmptyState`, `ErrorView`, `ListShimmer`, `AppSearchBar`, `ProfessorClassroomListCard`, `FeeCard`.
- Seguir patrones de providers existentes (`StateNotifierProvider`, `FutureProvider.family`, `StateNotifierProvider.family`).

## Review Focus

- Padre con 0 hijos ve empty neutro en español y no rompe quick actions; espera CTA a soporte o reintentar.
- Padre con N hijos cambia de hijo y listas (aulas/cuotas) recargan sin mezclar datos del hijo anterior.
- Tap en cuota con id inexistente muestra `feesDetailLoadError` con reintentar, no pantalla gris.
- Tap en aula desde contexto padre no fuga a lista global ni a detalle de otro hijo.
- Sin conexión en home padre / aulas / cuotas muestra `ErrorView` con reintentar y `tester.takeException()` es null.

---

### Task 1: Rutas /fees faltantes

**Files:**
- Modify: `lib/app/router.dart:32-59`
- Test: `test/app/fees_routes_test.dart`

**Interfaces:**
- Consumes: `FeeListScreen()` de `lib/features/fees/screens/fee_list_screen.dart:16`, `FeeDetailScreen({required String feeId})` de `lib/features/fees/screens/fee_detail_screen.dart:13`
- Produces: `GoRoute(path: '/fees')` + `GoRoute(path: ':id')` visibles en `routerProvider.configuration.routes` para Task 2/3

- [ ] **Step 1: Write the failing test**

```dart
test('router exposes /fees and /fees/:id', () {
  final router = container.read(routerProvider);
  final paths = collectRoutePaths(router);
  expect(paths, contains('/fees'));
  expect(paths, contains('/fees/:id'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/fees_routes_test.dart -v`
Expected: FAIL with `Expected: contains '/fees' / Actual: [...]`

- [ ] **Step 3: Implement routes in `lib/app/router.dart`**

Añadir imports de `fee_list_screen.dart` y `fee_detail_screen.dart`, y al nivel de `/students`, `/notifications` agregar `GoRoute(path: '/fees', builder: FeeListScreen, routes: [GoRoute(path: ':id', builder: (ctx,st) => FeeDetailScreen(feeId: st.pathParameters['id']!))])`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/fees_routes_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart test/app/fees_routes_test.dart
git commit -m "fix: add missing /fees and /fees/:id routes"
```

### Task 2: Home padre = hijos + ficha hijo

**Files:**
- Create: `lib/features/relations/providers/selected_child_provider.dart`
- Create: `lib/features/dashboard/screens/widgets/parent_children_section.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart:30-60,114-190`
- Test: `test/dashboard/parent_children_section_test.dart`

**Interfaces:**
- Consumes: `relationsProvider` (`RelationsState.pagination.data: List<RelationModel>`) de `lib/features/relations/providers/relations_provider.dart:116`, `RelationModel{id, fullname, role, userId}`
- Produces: `parentSelectedStudentProvider = StateProvider<String?>((ref) => null)` en `selected_child_provider.dart`; `ParentChildrenSection({required void Function(RelationModel child) onSelect})` usado por `DashboardScreen` cuando `user?.role == 'parent'`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('parent home lists children from relations and opens student detail', (tester) async {
  await pumpParentHomeWithRelations(tester, children: [RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11)]);
  expect(find.text('Ana Pérez'), findsOneWidget);
  await tester.tap(find.text('Ana Pérez'));
  await tester.pumpAndSettle();
  expect(find.byType(StudentDetailScreen), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dashboard/parent_children_section_test.dart -v`
Expected: FAIL with `ParentChildrenSection not found / Ana Pérez not found` (dashboard actual muestra `classrooms`, no hijos)

- [ ] **Step 3: Implement `ParentChildrenSection` + provider**

Crear `lib/features/relations/providers/selected_child_provider.dart` con `final parentSelectedStudentProvider = StateProvider<String?>((ref) => null);` y el widget `ParentChildrenSection` en `lib/features/dashboard/screens/widgets/parent_children_section.dart`

Widget `ConsumerWidget` con firma `ParentChildrenSection({required ValueChanged<RelationModel> onSelect})`; estados: `isLoading && empty -> ListShimmer`, `error && empty -> ErrorView(message: l10n.studentsLoadError)`, `empty -> EmptyState(icon: users, title: l10n.studentsEmptyTitle)`; lista usa `AppCard` + `caretRight`; `onTap` llama `onSelect(child)` y `DashboardScreen` hace `ref.read(parentSelectedStudentProvider.notifier).state = child.id` + `context.push('/students/${child.userId}')` (usar `userId` como `studentId` porque `StudentDetailScreen` espera `studentId` de `studentDetailProvider`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/dashboard/parent_children_section_test.dart test/dashboard/dashboard_screen_test.dart -v`
Expected: PASS, `takeException() isNull` a 320x568

- [ ] **Step 5: Commit**

```bash
git add lib/features/relations/providers/selected_child_provider.dart lib/features/dashboard/screens/widgets/parent_children_section.dart lib/features/dashboard/screens/dashboard_screen.dart test/dashboard/parent_children_section_test.dart
git commit -m "feat: parent home lists children and opens child detail"
```

### Task 3: Cuotas filtradas por hijo

**Files:**
- Modify: `lib/features/relations/providers/selected_child_provider.dart`
- Modify: `lib/features/fees/providers/fee_provider.dart:25-108`
- Modify: `lib/features/fees/screens/fee_list_screen.dart:48-114`
- Test: `test/fees/fee_list_notifier_test.dart`

**Interfaces:**
- Consumes: `parentSelectedStudentProvider` de Task 2; `FeeRepository.getFees({String? studentId, String? search, String? cursor})`, `FeeRepository.getStudentFees(String studentAppId, {int page})`
- Produces: `parentSelectedStudentProvider = StateProvider<String?>((ref) => null)`; `FeeListNotifier.setStudent(String? studentId)` + campo `FeeListState.studentId`

- [ ] **Step 1: Write the failing test**

```dart
test('load forwards selected studentId to repository and search keeps it', () async {
  final notifier = FeeListNotifier(fakeRepository);
  await notifier.setStudent('stu-11');
  expect(fakeApi.lastQuery?['studentId'], 'stu-11');
  await notifier.search('marzo');
  expect(fakeApi.lastQuery?['studentId'], 'stu-11');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/fees/fee_list_notifier_test.dart -v`
Expected: FAIL with `setStudent not defined / studentId was null`

- [ ] **Step 3: Implement `setStudent` + scope en `lib/features/fees/providers/fee_provider.dart`**

Añadir `String? studentId` a `FeeListState` + `copyWith`; en `load/refresh/loadMore` pasar `studentId: state.studentId`; añadir `Future<void> setStudent(String? id)` que resetea `search`? No — conserva `search`, setea `studentId` y llama `load()`; crear `selected_child_provider.dart` con `StateProvider<String?>`.

- [ ] **Step 4: Wire selector en `lib/features/fees/screens/fee_list_screen.dart`**

Si `authProvider.user?.role == 'parent'`, mostrar arriba `ParentChildSelector` (dropdown/chips desde `relationsProvider`, valor `parentSelectedStudentProvider`); `onChanged` llama `ref.read(parentSelectedStudentProvider.notifier).state = id` + `ref.read(feeListProvider.notifier).setStudent(id)`; si `studentId == null` mostrar `EmptyState(title: l10n.feesEmptyTitle)` en vez de lista global.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/fees/fee_list_notifier_test.dart test/fees/fee_repository_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/fees/providers/fee_provider.dart lib/features/fees/screens/fee_list_screen.dart test/fees/fee_list_notifier_test.dart
git commit -m "fix: scope fee list by selected child"
```

### Task 4: Aulas solo del hijo seleccionado

**Files:**
- Modify: `lib/features/classrooms/data/classroom_api.dart:8-25`
- Modify: `lib/features/classrooms/data/classroom_repository.dart:17-45`
- Modify: `lib/features/classrooms/providers/classroom_provider.dart:38-149`
- Modify: `lib/features/classrooms/screens/classroom_list_screen.dart:84-139`
- Test: `test/classrooms/parent_classroom_scope_test.dart`

**Interfaces:**
- Consumes: `parentSelectedStudentProvider` de Task 3; `StudentModel.classroomNames: List<String>` de `lib/features/students/domain/student_model.dart:17`
- Produces: `ClassroomApi.getClassrooms({..., String? studentId})` con query `student_id`; `ClassroomRepository.getClassrooms({..., String? studentId})`; `ClassroomListNotifier.setStudent(String? id)`

- [ ] **Step 1: Write the failing test**

```dart
test('parent scope forwards student_id and filters to child classrooms', () async {
  final notifier = ClassroomListNotifier(fakeRepo);
  await notifier.setStudent('stu-11');
  expect(fakeRepo.calls.last['studentId'], 'stu-11');
  expect(notifier.state.studentId, 'stu-11');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/classrooms/parent_classroom_scope_test.dart -v`
Expected: FAIL with `setStudent not defined / studentId was null`

- [ ] **Step 3: Implement `studentId` en api/repository/notifier**

En `classroom_api.dart` añadir `String? studentId` y query `if (studentId != null) 'student_id': studentId`; en `classroom_repository.dart` y `classroom_provider.dart` propagar el param; añadir campo `studentId` a `ClassroomListState` + `setStudent(String? id)` que reconstruye estado conservando `search` y llama `load(page: 1)`; `copyWith` debe preservar `studentId`, `branch/level/year/status`.

- [ ] **Step 4: Wire UI padre en `lib/features/classrooms/screens/classroom_list_screen.dart`**

Si `role == 'parent'`: ocultar `ClassroomFilterButton`/`ClassroomFilterChips` globales, mostrar selector de hijo (mismo provider de Task 3); `onChanged` setea `parentSelectedStudentProvider` + `classroomListProvider.notifier.setStudent(id)`; si `studentId == null` mostrar `EmptyState(title: l10n.classroomsEmptyTitle)`; el `subtitle` del header usa `listState.page.total` ya filtrado; mantener `ProfessorClassroomListCard` y `PaginationBar` sin cambios (operate.md: no rediseñar).

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/classrooms/parent_classroom_scope_test.dart test/classrooms/classroom_list_notifier_test.dart test/classrooms/classroom_list_screen_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/classrooms/data/classroom_api.dart lib/features/classrooms/data/classroom_repository.dart lib/features/classrooms/providers/classroom_provider.dart lib/features/classrooms/screens/classroom_list_screen.dart test/classrooms/parent_classroom_scope_test.dart
git commit -m "fix: scope classroom list to selected child"
```
