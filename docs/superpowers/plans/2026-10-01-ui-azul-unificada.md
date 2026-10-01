# UI azul unificada Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Toda la app usa un único sistema visual azul (el actual de la sección profesor): mismos tokens, headers, cards, labels, botones y estados en todas las pantallas, en tema claro y oscuro.

**Architecture:** Primero la fuente única (tokens en `AppColors` + `ThemeData`), después los widgets base de `core/widgets`, después la migración pantalla por pantalla eliminando las ramas `isProfessor`. Ninguna tarea cambia rutas, providers, modelos ni copy.

**Tech Stack:** Flutter 3.44 / Dart, flutter_riverpod, go_router, phosphor_flutter, shimmer, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-01-ui-azul-unificada-design.md`

## Global Constraints

- Flutter binario: `/opt/flutter/bin/flutter`. Tests: `/opt/flutter/bin/flutter test <path>`. Análisis: `/opt/flutter/bin/flutter analyze`.
- TDD: primero el test en rojo, después el código mínimo, después verde. Un commit por tarea: `feat(ui): <qué>`.
- Sin dependencias nuevas, sin claves l10n nuevas, sin cambios de rutas ni de comportamiento.
- Toda pantalla migrada debe respetar tema claro Y oscuro.
- Valores exactos del spec: `primary #3F6EA8`, `primarySoft #5F92C9`, `accent #83B0E0`, `ink #2F4A6B`, `muted #71799A`, `sectionLabel #8792B5`, `surface/background claro #F5F6FA`, `onPrimary #FFFFFF`, `onPrimaryMuted #C4CDEC`, `navInactive #9AA2BD`, `overlay 0x1FFFFFFF`, `overlayStrong 0x2EFFFFFF`, `present/gradeHigh #2FA36C`, `absent/gradeLow #E05353`, `gradeMid #4A5AA0`, `gradeWarn #E0912F`, `gradeEmptyBackground #EEF0F6`, `primaryLight #EBF0F6`, `headerGradient [primarySoft→accent]`, `primaryGradientDark [primary→primarySoft]`, gutters 16, card r16/padding 14, botones r13/h46, section label 10/w800/ls0.6.
- `primarySoft` nunca lleva texto blanco encima (contraste 3.3:1); la pill selectora del nav es `primary`.
- Al final de cada tarea: `flutter analyze` del/los archivos tocados sin warnings nuevos.

## Review Focus

1. Modo oscuro roto (texto ilegible o superficies claras coladas): cada tarea de pantallas incluye un test que pumpea la pantalla en `Brightness.dark` y espera los tokens oscuros (fondo `darkBackground`, títulos `darkTextPrimary`, acento `accent`).
2. Overflow en teléfono chico (320×568): las pantallas migradas con tabs mantienen el test de overflow existente y se agrega uno para el home de padres (Task 8).
3. Listados que muestran spinner crudo o `accentColor` índigo heredado: los tests de listados afirman `findsNothing` para `CircularProgressIndicator` en estado de carga y `accentColor` por defecto (null → `accentFor`) en `EmptyState`/`ErrorView` (Tasks 9–12).
4. Estados seleccionados que pierden el borde `primarySoft` 1.5px o la pill del nav que sigue azul-clara: tests en Tasks 5 y 6.
5. Roles no-profesor (parent/student/admin) que renderizan otro sistema: el test del home de padres (Task 8) y el de nav por rol (Task 6) afirman el mismo sistema visual que el profesor.

---

## File Structure

- `lib/app/theme/app_colors.dart` — única paleta + helpers `accentFor/inkFor/mutedFor/backgroundFor/chipFor(isDark)` + escala `gradeColor/formatGrade`.
- `lib/app/theme/app_theme.dart` — `AppTheme.light/dark` con seed azul, botones r13/h46, inputs, appBar, divider.
- `lib/app/theme/professor_colors.dart` — SE ELIMINA (sus tokens viven en `AppColors`).
- `lib/core/widgets/gradient_header.dart` (nuevo) — `GradientHeader` + `ScreenHeader`.
- `lib/core/widgets/home_header.dart` (nuevo) — `HomeHeader`.
- `lib/core/widgets/header_stats_row.dart` (nuevo) — `HeaderStatsRow` + `HeaderStat`.
- `lib/core/widgets/{app_card,section_header,stat_card,large_title_bar,detail_hero,empty_state,error_view,pill_button,pagination_bar,loading_shimmer,avatar,badge_counter}.dart` — restyle in place, APIs compatibles salvo defaults.
- `lib/features/professor/widgets/` — SE ELIMINA tras migrar sus 3 archivos a core.
- `lib/app/router.dart` — `CustomBottomNav` con acento único.
- Pantallas (solo presentación): `dashboard_screen`, `student_list_screen`, `news_list_screen`, `event_list_screen`, `notification_list_screen`, `chat_list_screen`, `chat_detail_screen`, `search_screen`, `profile_screen`, `login_screen`, `forgot_password_screen`, `fee_list/detail_screen`, `qualification_list_screen`, más la remoción de `isProfessor` en `classroom_list/detail` + `student_detail` y sus widgets.

---
### Task 1: Paleta única en `AppColors` + helpers

**Files:**
- Modify: `lib/app/theme/app_colors.dart`
- Test: `test/theme/app_colors_test.dart` (nuevo)

**Interfaces:**
- Consumes: nada nuevo.
- Produces: `AppColors.primary/primarySoft/accent/lightInk/lightMuted/sectionLabel/navInactive/onPrimary/onPrimaryMuted/overlay/overlayStrong/present/absent/gradeHigh/gradeMid/gradeWarn/gradeLow/gradeEmptyBackground/primaryLight/lightBackground/primaryGradient/primaryGradientDark/roleProfessor`, `static Color accentFor(bool)/inkFor(bool)/mutedFor(bool)/backgroundFor(bool)/chipFor(bool)`, `static Color gradeColor(double?)`, `static String formatGrade(double?)` — usados por Tasks 2–13.

- [ ] **Step 1: Escribir el test que falla**

```dart
test('unified blue tokens match the spec', () {
  expect(AppColors.primary, const Color(0xFF3F6EA8));
  expect(AppColors.primarySoft, const Color(0xFF5F92C9));
  expect(AppColors.accent, const Color(0xFF83B0E0));
  expect(AppColors.lightBackground, const Color(0xFFF5F6FA));
  expect(AppColors.roleProfessor, AppColors.primary);
  expect(AppColors.accentFor(false), AppColors.primary);
  expect(AppColors.accentFor(true), AppColors.accent);
  expect(AppColors.inkFor(false), AppColors.lightInk);
  expect(AppColors.backgroundFor(false), AppColors.lightBackground);
  expect(AppColors.backgroundFor(true), AppColors.darkBackground);
  expect(AppColors.gradeColor(9.2), AppColors.gradeHigh);
  expect(AppColors.gradeColor(5.0), AppColors.gradeWarn);
  expect(AppColors.gradeColor(null), AppColors.muted);
  expect(AppColors.formatGrade(null), '—');
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/theme/app_colors_test.dart`
Expected: FAIL (`AppColors.primary` aún es índigo).

- [ ] **Step 3: Implementar los tokens y helpers en `lib/app/theme/app_colors.dart` con los valores exactos de Global Constraints** (mover `gradeColor/formatGrade` y la escala de grilla desde `professor_colors.dart`; `roleProfessor = primary`; eliminar `primaryDark`; no tocar `secondary` salvo que `analyze` lo exija).

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `/opt/flutter/bin/flutter test test/theme/app_colors_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_colors.dart test/theme/app_colors_test.dart
git commit -m "feat(ui): paleta azul unificada en AppColors"
```

---
### Task 2: `AppTheme` claro/oscuro en azul

**Files:**
- Modify: `lib/app/theme/app_theme.dart`
- Test: `test/theme/app_theme_test.dart` (nuevo)

**Interfaces:**
- Consumes: `AppColors` + helpers (Task 1).
- Produces: `AppTheme.light/dark` con botones r13/h46 — usado por Tasks 4–13.

- [ ] **Step 1: Escribir el test que falla**

```dart
test('light theme uses the unified blue system', () {
  final t = AppTheme.light;
  expect(t.colorScheme.primary, AppColors.primary);
  expect(t.scaffoldBackgroundColor, AppColors.lightBackground);
  expect(t.appBarTheme.backgroundColor, AppColors.primary);
  expect(t.appBarTheme.titleTextStyle?.color, Colors.white);
});
testWidgets('buttons render r13 and h46 from the theme', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: Scaffold(body: ElevatedButton(onPressed: () {}, child: const Text('CTA')))));
  expect(tester.getSize(find.byType(ElevatedButton)).height, 46);
  final style = tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style!;
  expect(style.shape!.resolve(const <WidgetState>{}),
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)));
});
test('dark theme keeps blue accents on dark surfaces', () {
  final t = AppTheme.dark;
  expect(t.colorScheme.primary, AppColors.primary);
  expect(t.scaffoldBackgroundColor, AppColors.darkBackground);
});
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/theme/app_theme_test.dart`
Expected: FAIL (seed índigo, botones r24/h52).

- [ ] **Step 3: Implementar en `app_theme.dart`**: `seedColor: AppColors.primary`, `primary: AppColors.primary` en ambos schemes; scaffold `lightBackground/darkBackground`; `appBarTheme` fondo `primary`, título blanco 20/w800, `systemOverlayStyle` light, elevación 0; `elevatedButtonTheme` y `outlinedButtonTheme` r13 + `minimumSize Size(0,46)`, texto 12/w800; `textButtonTheme` color `primary`; inputs con fill `lightSearchFill/darkSearchFill`, r12, focused border `primary` (light) / `accent` (dark); divider `lightDivider/darkDivider`; `bottomNavigationBarTheme.selectedItemColor = primary` (tema muerto pero coherente).

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `/opt/flutter/bin/flutter test test/theme/app_theme_test.dart test/theme/app_colors_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(ui): ThemeData claro/oscuro en azul unificado"
```

---
### Task 3: Eliminar `ProfessorColors` y migrar sus 26 imports

**Files:**
- Delete: `lib/app/theme/professor_colors.dart`, `test/theme/professor_colors_test.dart`
- Modify: los 26 archivos de `lib` que importan `professor_colors` (mapeo 1:1: `ProfessorColors.X` → `AppColors.X`; `headerGradient` → `AppColors.primaryGradient` / `primaryGradientDark` según `isDark`)
- Test: `test/theme/app_colors_test.dart` (extender con los casos de `gradeColor/formatGrade` ya cubiertos en Task 1 — sin archivo nuevo)

**Interfaces:**
- Consumes: `AppColors` (Task 1).
- Produces: cero referencias a `professor_colors` — requerido por Tasks 5–7.

- [ ] **Step 1: Escribir la verificación que falla** (script, no test): `grep -rn "professor_colors" lib test | wc -l` debe dar 0; hoy da 29.

- [ ] **Step 2: Migrar los 26 imports** (solo renombrado, sin restyle): cada `ProfessorColors.foo` → `AppColors.foo`. Excepción: `ProfessorColors.headerGradient` en pantallas con rama oscura → `isDark ? AppColors.primaryGradientDark : AppColors.primaryGradient`. Actualizar los tests que importan `professor_colors` (`bottom_nav_test`, `professor_home_screen_test`, `student_detail_screen_test`) al nuevo import; NO cambiar aún sus expectativas de color (eso es Task 5–7).

- [ ] **Step 3: Borrar `lib/app/theme/professor_colors.dart` y `test/theme/professor_colors_test.dart`**.

- [ ] **Step 4: Verificar**

Run: `grep -rn "professor_colors" lib test | wc -l` Expected: `0`. Luego `/opt/flutter/bin/flutter test test/theme test/dashboard/professor_home_screen_test.dart test/app/bottom_nav_test.dart` Expected: PASS (los tests del home/nav siguen verdes porque los valores son idénticos, solo cambió el import).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): eliminar ProfessorColors, tokens en AppColors"
```

---
### Task 4: Cards, labels y stats unificados

**Files:**
- Modify: `lib/core/widgets/app_card.dart`, `lib/core/widgets/section_header.dart`, `lib/core/widgets/stat_card.dart`
- Test: `test/core/unified_cards_test.dart` (nuevo)

**Interfaces:**
- Consumes: `AppColors` + helpers (Task 1).
- Produces: `AppCard(selected:)`, `SectionHeader`, `StatCard` finales — usados por Tasks 5, 8–12.

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('SectionHeader renders uppercase micro label', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SectionHeader(title: 'Mis aulas'))));
  final text = tester.widget<Text>(find.text('MIS AULAS'));
  expect(text.style?.fontSize, 10);
  expect(text.style?.fontWeight, FontWeight.w800);
  expect(text.style?.letterSpacing, 0.6);
  expect(text.style?.color, AppColors.sectionLabel);
});
testWidgets('AppCard uses r16 padding 14 and selected border', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppCard(selected: true, child: Text('x')))));
  final box = tester.widget<Container>(find.byType(Container).first);
  final deco = box.decoration as BoxDecoration;
  expect(deco.borderRadius, BorderRadius.circular(16));
  expect(deco.border, Border.all(color: AppColors.primarySoft, width: 1.5));
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/core/unified_cards_test.dart`
Expected: FAIL (título 16/w600, card padding 16 sin borde `selected`).

- [ ] **Step 3: Implementar**: `AppCard` con padding 14, sombra `Color(0x59232D3C)` opacidad .12 (oscuro .3) blur 24 offset(0,10) spread −14, param `selected` → borde 1.5 `primarySoft`; `SectionHeader` con `title.toUpperCase()`, 10/w800/ls0.6 `sectionLabel`, acción 11/w800 `accentFor(isDark)`, padding h16; `StatCard` con sombra de `AppCard`, chip 40 r12 bg `chipFor(isDark)`, valor 22/w800 `inkFor(isDark)`, label 12 `mutedFor(isDark)` (`iconColor` sigue obligatorio).

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/core/unified_cards_test.dart test/students/student_detail_screen_test.dart test/classrooms/classroom_detail_screen_test.dart`
Expected: PASS (los detalles usan `StatCard`/`SectionHeader` y deben seguir verdes).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_card.dart lib/core/widgets/section_header.dart lib/core/widgets/stat_card.dart test/core/unified_cards_test.dart
git commit -m "feat(ui): AppCard, SectionHeader y StatCard unificados"
```

---
### Task 5: Headers del sistema + migración de las pantallas del profesor

**Files:**
- Create: `lib/core/widgets/gradient_header.dart` (`GradientHeader`, `ScreenHeader`), `lib/core/widgets/home_header.dart` (`HomeHeader`), `lib/core/widgets/header_stats_row.dart` (`HeaderStatsRow`, `HeaderStat`)
- Modify: `professor_home_screen.dart`, `professor_home_header.dart` (delegar en `HomeHeader`), `professor_stats_row.dart` (delegar en `HeaderStatsRow`), `professor_classroom_card.dart` (usar `AppCard`), `professor_classrooms_header.dart`, `professor_classroom_list_card.dart`, `attendance_screen.dart`, `classroom_grades_screen.dart` (usar `ScreenHeader`)
- Delete: `lib/features/professor/widgets/` (3 archivos) al quedar sin usos
- Test: `test/core/headers_test.dart` (nuevo); actualizar `test/dashboard/professor_home_screen_test.dart` (imports; pill del nav → `AppColors.primary`, resto de valores idénticos)

**Interfaces:**
- Consumes: `AppColors` (Task 1), `AppCard` (Task 4).
- Produces: `GradientHeader({child})`, `ScreenHeader({title, subtitle, onBack, child})`, `HomeHeader({name, avatarUrl, unreadCount, onNotifications, onSearch, child})`, `HeaderStat({value, label, highlighted})` + `HeaderStatsRow({stats})`.

Firmas exactas:
```dart
const GradientHeader({super.key, required this.child});
const ScreenHeader({super.key, required this.title, this.subtitle, this.onBack, this.child});
const HomeHeader({super.key, required this.name, this.avatarUrl, required this.unreadCount, this.onNotifications, this.onSearch, this.child});
class HeaderStat { const HeaderStat({required this.value, required this.label, this.highlighted = false}); }
const HeaderStatsRow({super.key, required this.stats});
```

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('GradientHeader renders blue gradient with bottom radius 24', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GradientHeader(child: Text('x')))));
  final box = tester.widget<Container>(find.byType(Container).first);
  final deco = box.decoration as BoxDecoration;
  expect(deco.gradient, AppColors.primaryGradient);
  expect(deco.borderRadius, const BorderRadius.vertical(bottom: Radius.circular(24)));
});
testWidgets('ScreenHeader shows back, 14/w800 title and 11 subtitle', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ScreenHeader(title: 'Asistencia', subtitle: '1G'))));
  final title = tester.widget<Text>(find.text('Asistencia'));
  expect(title.style?.fontSize, 14);
  expect(title.style?.fontWeight, FontWeight.w800);
  expect(title.style?.color, AppColors.onPrimary);
  expect(find.text('1G'), findsOneWidget);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/core/headers_test.dart`
Expected: FAIL (no existen los widgets).

- [ ] **Step 3: Crear los 3 archivos core** con la spec 4.3 del diseño (gradiente por brightness, radio inferior 24, padding `fromLTRB(16, statusBar+12, 16, 16)`, botones 40×40 r12 bg overlay, stats r14 valor 24/w900).

- [ ] **Step 4: Migrar las pantallas del profesor** a los nuevos widgets (cambio mecánico, mismos valores) y borrar `lib/features/professor/widgets/`. Actualizar `professor_home_screen_test.dart`: import → `AppColors`; expectativa de la pill del nav `primarySoft` → `AppColors.primary`.

- [ ] **Step 5: Correr tests**

Run: `/opt/flutter/bin/flutter test test/core/headers_test.dart test/dashboard/professor_home_screen_test.dart test/qualifications/classroom_grades_screen_test.dart test/attendance/attendance_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(ui): headers del sistema en core, pantallas profesor migradas"
```

---
### Task 6: Estados, botones, paginación + nav con acento único

**Files:**
- Modify: `lib/core/widgets/empty_state.dart`, `lib/core/widgets/error_view.dart`, `lib/core/widgets/pill_button.dart`, `lib/core/widgets/pagination_bar.dart`, `lib/core/widgets/loading_shimmer.dart`, `lib/core/widgets/large_title_bar.dart`, `lib/core/widgets/detail_hero.dart`, `lib/core/widgets/avatar.dart`, `lib/core/widgets/badge_counter.dart`, `lib/app/router.dart`
- Test: actualizar `test/app/bottom_nav_test.dart` (ambos roles → `AppColors.primary`); extender `test/core/pagination_bar_test.dart` (acento `accentFor` en claro/oscuro)

**Interfaces:**
- Consumes: `AppColors` + helpers (Task 1), tema (Task 2).
- Produces: defaults azules en estados/botones/paginación; `CustomBottomNav` sin rama por rol.

- [ ] **Step 1: Escribir/actualizar los tests que fallan**

```dart
// pagination_bar_test.dart — agregar:
testWidgets('uses the unified accent in light and dark', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: Scaffold(body: PaginationBar(currentPage: 2, totalPages: 5, onPageChanged: (_) {}))));
  // el círculo de página activa usa AppColors.primary en claro
  expect(find.byWidgetPredicate((w) =>
      w is Container && (w.decoration as BoxDecoration?)?.color == AppColors.primary), findsOneWidget);
});
```

```dart
// bottom_nav_test.dart — cambiar el test 'active destination uses the accent pill':
// pumpear con rol 'parent' ADEMÁS de 'professor' y esperar AppColors.primary en ambos.
```

- [ ] **Step 2: Correr y verificar que fallan**

Run: `/opt/flutter/bin/flutter test test/core/pagination_bar_test.dart test/app/bottom_nav_test.dart`
Expected: FAIL (paginación índigo, nav `primarySoft`/índigo por rol).

- [ ] **Step 3: Implementar**: `EmptyState`/`ErrorView` default `accentFor(isDark)`, CTA r13 h44 11/w800; `PillButton` r13 h46 texto 12/w800 gradiente `primaryGradient`; `PaginationBar` acento `accentFor(isDark)`; `ListShimmer` defaults padding 16 / itemHeight 68 / radius 16; `LargeTitleBar` con gradiente + radio inferior 24 + título 24/w800 blanco + back blanco + gutters 16 (API intacta); `DetailHero` gradiente por defecto `primaryGradient/Dark` + radio inferior 24; `AppAvatar` anillo con gradiente azul (ya lo es por token); `BadgeCounter` color `primary`; `router.dart`: acento `AppColors.primary` para todos los roles, inactivo `navInactive` (claro) / `darkTextSecondary` (oscuro); quitar `accentColor: primarySoft` explícitos donde el default ya lo cubre.

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/core/pagination_bar_test.dart test/app/bottom_nav_test.dart test/dashboard/professor_home_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): estados, botones, paginacion y nav con acento unico"
```

---
### Task 7: Eliminar las ramas `isProfessor` de aulas y alumnos

**Files:**
- Modify: `lib/features/classrooms/screens/classroom_list_screen.dart`, `classroom_detail_screen.dart`, `lib/features/students/screens/student_detail_screen.dart`, widgets: `classroom_detail_header.dart`, `classroom_summary_tab.dart`, `classroom_related_tabs.dart`, `student_detail_header.dart`, `student_info_tab.dart`, `student_related_tabs.dart`, `student_grades_grid.dart`, más `classroom_filter_button/chips/sheet.dart`, `material_tile.dart`, `classroom_card.dart`, `student_card.dart`, `student_tile.dart`, `absence_tile.dart`, `fee_tile.dart`, `professor_tile.dart` (quitar `isProfessor`, usar tokens/helpers únicos, gutters 16)
- Test: actualizar `classroom_detail_screen_test.dart`, `student_detail_screen_test.dart`, `classroom_list_screen_test.dart`, `student_list_screen_test.dart`, `classroom_filter_sheet_test.dart` (expectativas únicas: `EmptyState.accentColor` null, iconos de stats `AppColors.primary`, tabs con acento `primary`)

**Interfaces:**
- Consumes: todo lo de Tasks 1–6.
- Produces: cero `isProfessor` en UI (solo queda el getter en `user_model.dart`).

- [ ] **Step 1: Actualizar los tests para que fallen**: en `student_detail_screen_test.dart` el test `generic student detail keeps the default accents` hoy espera `empty.accentColor isNull` y `iconColor 0xFF3B82F6`; cambiar a afirmar sistema único (icono `AppColors.primary`, tabs con indicador `primary`). En `classroom_detail_screen_test.dart`, unificar las expectativas de ambas ramas en una sola.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `/opt/flutter/bin/flutter test test/students/student_detail_screen_test.dart test/classrooms/classroom_detail_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**: borrar el param `isProfessor` de los 7 widgets y las 3 pantallas; una sola rama con `LargeTitleBar`/`DetailHero` azules, fondo `backgroundFor`, gutters 16, `accentFor` en tabs/filtros/chips, `PagedTabList` sin `accentColor` explícito.

- [ ] **Step 4: Verificar**

Run: `grep -rn "isProfessor" lib | grep -v "user_model" | wc -l` Expected: `0`. Luego `/opt/flutter/bin/flutter test test/students test/classrooms` Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): eliminar ramas isProfessor en aulas y alumnos"
```

---
### Task 8: Home de padres con el sistema unificado (+ test faltante)

**Files:**
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`, `lib/features/dashboard/screens/widgets/quick_action_grid.dart` (chips con `chipFor` + icono `primary`; quitar arcoíris), `lib/features/dashboard/screens/widgets/stat_card.dart` (re-export o delegación a core `StatCard`)
- Test: `test/dashboard/dashboard_screen_test.dart` (nuevo: hoy no existe)

**Interfaces:**
- Consumes: `HomeHeader`, `HeaderStatsRow` (Task 5), `SectionHeader`, `StatCard` (Task 4).
- Produces: home de padres con header en gradiente + stats overlay + `SectionHeader` + `AppCard`.

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('parent home uses the unified header system', (tester) async {
  await _pumpParentHome(tester); // rol 'parent', DashboardData con 2 aulas
  expect(find.byType(HomeHeader), findsOneWidget);
  expect(find.byType(HeaderStatsRow), findsOneWidget);
  // section label en versalitas del sistema
  final label = tester.widget<Text>(find.text('MIS AULAS'));
  expect(label.style?.color, AppColors.sectionLabel);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
testWidgets('parent home renders in dark mode', (tester) async {
  await _pumpParentHome(tester, brightness: Brightness.dark);
  final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
  expect(scaffold.backgroundColor, AppColors.darkBackground);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/dashboard/dashboard_screen_test.dart`
Expected: FAIL (no hay `HomeHeader`; el home es plano con `StatCard` multicolor).

- [ ] **Step 3: Implementar**: `HomeHeader` (saludo + nombre + botones notificaciones/búsqueda) con `HeaderStatsRow` como `child`; sección `SectionHeader` + cards de aula con `AppCard`; fondo `backgroundFor`; gutters 16; loading con skeleton (header + `ListShimmer`); error/vacío sin `accentColor`; rol badge conserva `roleParent` (paleta de roles intacta). Overflow 320×568 verificado con el layout de columna única.

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/dashboard/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): home de padres con el sistema unificado"
```

---
### Task 9: Listados — alumnos, noticias, eventos, notificaciones

**Files:**
- Modify: `lib/features/students/screens/student_list_screen.dart` (+ `student_card.dart`), `lib/features/news/screens/news_list_screen.dart`, `lib/features/events/screens/event_list_screen.dart`, `lib/features/notifications/screens/notification_list_screen.dart`
- Test: extender `student_list_screen_test.dart`; nuevo `test/ui_unified/list_screens_test.dart` (news/events/notifications: header gradiente, shimmer en carga, sin spinner)

**Interfaces:**
- Consumes: `LargeTitleBar` (Task 6), `AppCard`/`SectionHeader` (Task 4), `AppSearchBar` (sin cambios salvo acentos).

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('news list uses gradient header and shimmer while loading', (tester) async {
  await _pumpNewsLoading(tester);
  expect(find.byType(LargeTitleBar), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(LoadingShimmer), findsWidgets);
});
```

(repetir esquema para events y notifications; en `student_list_screen_test.dart` agregar caso oscuro: fondo `darkBackground`, chips con `accentFor(true)`.)

- [ ] **Step 2: Correr y verificar que fallan**

Run: `/opt/flutter/bin/flutter test test/ui_unified/list_screens_test.dart test/students/student_list_screen_test.dart`
Expected: FAIL (spinners centrados, `LargeTitleBar` plano, gutters 20).

- [ ] **Step 3: Implementar** por pantalla según checklist 4.4: `LargeTitleBar` en gradiente, fondo `backgroundFor`, gutters 16, cards con `AppCard`, filtros/chips con `accentFor`, loading con `ListShimmer`, vacío/error sin `accentColor`, fechas/meta con `mutedFor`.

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/ui_unified/list_screens_test.dart test/students/student_list_screen_test.dart test/classrooms/classroom_list_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): listados de alumnos, noticias, eventos y notificaciones"
```

---
### Task 10: Chat, búsqueda y perfil

**Files:**
- Modify: `lib/features/chat/screens/chat_list_screen.dart`, `chat_detail_screen.dart` (`ScreenHeader` en vez de `AppBar` crudo), `lib/features/search/screens/search_screen.dart`, `lib/features/profile/screens/profile_screen.dart` (`HomeHeader`-compacto o `LargeTitleBar` en gradiente + grupos con `AppCard` + `SectionHeader`; logout con botón r13/h46 `error`)
- Test: nuevo `test/ui_unified/chat_search_profile_test.dart` (header gradiente en las 3, sin `AppBar` crudo en chat detail, logout con radio 13)

**Interfaces:**
- Consumes: Tasks 1–6.

- [ ] **Step 1: Escribir el test que falla** (afirmar `find.byType(LargeTitleBar)/ScreenHeader` y `findsNothing` para `AppBar` en chat detail; `SectionHeader` en versalitas en perfil).

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/ui_unified/chat_search_profile_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** según checklist 4.4 (burbujas del chat conservan su color actual; solo cambian header, fondo, tiles y acentos; perfil usa avatar 80 con anillo azul + grupos r16 con sombra del sistema).

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/ui_unified/chat_search_profile_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): chat, busqueda y perfil unificados"
```

---
### Task 11: Auth — login y forgot-password

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`, `lib/features/auth/screens/forgot_password_screen.dart`
- Test: extender `test/auth/login_screen_test.dart` (header con `primaryGradient`, botón `PillButton` r13/h46)

**Interfaces:**
- Consumes: `PillButton` (Task 6), tema (Task 2).

- [ ] **Step 1: Escribir el test que falla** (el header usa `AppColors.primaryGradient` —ya azul por token— con radio inferior 24; el CTA tiene altura 46 y radio 13).

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/auth/login_screen_test.dart`
Expected: FAIL (botón h52/r24, header sin radio).

- [ ] **Step 3: Implementar**: header con radio inferior 24 + `SystemUiOverlayStyle.light`; formulario con inputs del tema; CTA vía `PillButton` (r13/h46); logo blanco y textos `onPrimary/onPrimaryMuted` intactos.

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/auth/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): login y recupero con el sistema unificado"
```

---
### Task 12: Pantallas legacy — fees y qualifications (solo restyle)

**Files:**
- Modify: `lib/features/fees/screens/fee_list_screen.dart`, `fee_detail_screen.dart`, `lib/features/fees/screens/widgets/fee_card.dart` (quitar `Colors.grey` → `mutedFor`), `lib/features/qualifications/screens/qualification_list_screen.dart`, `lib/features/qualifications/screens/widgets/qualification_card.dart`
- Test: nuevo `test/ui_unified/legacy_screens_test.dart` (pumpeo directo con repos fake: header del sistema, sin `Colors.grey`, sin `OutlineInputBorder` crudo)

**Interfaces:**
- Consumes: Tasks 1–6. Sin rutas nuevas (fuera de alcance del spec).

- [ ] **Step 1: Escribir el test que falla** (cada pantalla muestra `LargeTitleBar` o `ScreenHeader`; ningún `Text` con `Colors.grey`; búsqueda con fill del tema).

- [ ] **Step 2: Correr y verificar que falla**

Run: `/opt/flutter/bin/flutter test test/ui_unified/legacy_screens_test.dart`
Expected: FAIL (`AppBar` crudo + grises hardcodeados).

- [ ] **Step 3: Implementar** checklist 4.4 mínimo: header del sistema, `AppCard`, shimmer/vacío/error del sistema, acentos `accentFor`, grises → `inkFor/mutedFor`.

- [ ] **Step 4: Correr tests**

Run: `/opt/flutter/bin/flutter test test/ui_unified/legacy_screens_test.dart test/fees/ test/qualifications/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(ui): fees y qualifications con el sistema unificado"
```

---
### Task 13: Auditoría final y verificación visual

**Files:** ninguno (verificación) — salvo fixes menores que surjan, cada uno con su test.

- [ ] **Step 1: Greps de/origen cero**

Run: `grep -rn "0xFF4F46E5\|0xFF6366F1\|0xFF7C3AED\|0xFFEEF2FF\|0xFFFAFAF9\|0xFF8B5CF6" lib | wc -l` Expected: `0`.
Run: `grep -rn "professor_colors" lib test | wc -l` Expected: `0`.
Run: `grep -rn "isProfessor" lib | grep -v user_model | wc -l` Expected: `0`.
Run: `grep -rn "CircularProgressIndicator" lib/features/news lib/features/events lib/features/notifications lib/features/chat | wc -l` Expected: `0`.

- [ ] **Step 2: Análisis y suite completa**

Run: `/opt/flutter/bin/flutter analyze` Expected: sin errores ni warnings nuevos.
Run: `/opt/flutter/bin/flutter test` Expected: All tests passed.

- [ ] **Step 3: Verificación visual en claro y oscuro** (las 12 pantallas del checklist 4.4: home padres, aulas, detalle aula, alumnos, detalle alumno, noticias, eventos, notificaciones, chat, búsqueda, perfil, login): pumpear cada una en ambos brightness con `flutter test --plain-name` o revisión en dispositivo; corregir clipping/overflow si aparece.

- [ ] **Step 4: Commit final (solo si el Step 3 generó cambios)**

```bash
git add -A
git commit -m "fix(ui): ajustes finales de la unificacion visual"
```

---

## Self-Review

1. **Spec coverage:** tokens+helpers (T1) · tema claro/oscuro (T2) · eliminar `ProfessorColors` (T3) · cards/labels/stats (T4) · headers + migración profesor (T5) · estados/botones/paginación/nav (T6) · fin de `isProfessor` (T7) · home padres (T8) · listados (T9) · chat/búsqueda/perfil (T10) · auth (T11) · legacy (T12) · greps cero + suite verde (T13). §5 fuera de alcance respetado (sin rutas, sin l10n, sin cambios de providers). Sin gaps.
2. **Step scan:** cada step es una acción con resultado comprobable (test rojo / test verde / comando con salida esperada / commit). Los bodies de implementación se dejan al implementador salvo valores exactos del spec.
3. **Type consistency:** `accentFor/inkFor/mutedFor/backgroundFor/chipFor(bool)` definidos en T1 y usados igual en T4–T12; `HeaderStat/HeaderStatsRow/HomeHeader/ScreenHeader/GradientHeader` definidos en T5 y consumidos en T8/T10; `AppColors.primary` como acento único en T2/T6/T7.
4. **Review Focus:** los 5 riesgos tienen test en su tarea dueña (oscuro en T8/T9, overflow 320px en T8, spinner/acento en T9–T12, seleccionados en T5/T6, paridad por rol en T6/T8).
5. **Proportion:** el plan documenta decisiones, firmas, valores y tests; no transcribe cuerpos de widgets. Longitud proporcional a 13 tareas sobre ~60 archivos.
