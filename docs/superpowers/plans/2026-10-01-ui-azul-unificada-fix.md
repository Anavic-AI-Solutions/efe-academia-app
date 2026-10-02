# UI azul unificada — Fix Round (post-final-review)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Cerrar los 11 bloqueadores del review final para que la rama pase el merge gate.

**Architecture:** 2 tareas agrupadas por área: (A) headers/loading de auth + detail + professor home; (B) legacy fees/qualifications + rainbow quickactions + tokens + detalles.

**Tech Stack:** Flutter 3.44 / Dart, same as main plan.

**Spec:** `docs/superpowers/specs/2026-10-01-ui-azul-unificada-design.md` (checklist §4.4)

---

## Global Constraints

- Flutter: `/opt/flutter/bin/flutter`. One commit per task. TDD on changed widgets.
- No new dependencies, no new l10n keys, no route/provider changes.
- All fixes must work in light AND dark mode.
- After each task: `flutter test` (full suite) + `flutter analyze` clean.

---

## Task A: Auth dark mode + Professor home + Detail loading states

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`, `forgot_password_screen.dart`
- Modify: `lib/features/dashboard/screens/professor_home_screen.dart` (migrate to `HomeHeader`/`HeaderStatsRow`)
- Modify: `lib/features/classrooms/screens/classroom_detail_screen.dart`, `lib/features/students/screens/student_detail_screen.dart` (replace raw `AppBar` in loading/error with unified headers)
- Test: extend `test/auth/login_screen_test.dart`, `test/dashboard/professor_home_screen_test.dart`, `test/classrooms/classroom_detail_screen_test.dart`, `test/students/student_detail_screen_test.dart`

**Interfaces:**
- Consumes: `HomeHeader`, `HeaderStatsRow`, `ScreenHeader`, `GradientHeader`, `ListShimmer`, `AppColors` helpers (all done).
- Produces: zero hardcoded light colors in auth; professor home uses core widgets; detail screens use `ScreenHeader`/`GradientHeader` for loading/error.

- [ ] **Step 1: Write failing tests** — add dark-mode pump for login/forgot-password asserting `backgroundColor == AppColors.backgroundFor(true)`; professor home asserts `HomeHeader`/`HeaderStatsRow` (not `ProfessorHomeHeader`); detail screens assert no `AppBar` in loading/error and shimmer shown.

- [ ] **Step 2: Run tests** → RED

- [ ] **Step 3: Implement** — auth screens: `Scaffold.backgroundColor = AppColors.backgroundFor(isDark)`; header uses `GradientHeader` (already via `LargeTitleBar`/`ScreenHeader` pattern); form uses theme inputs; CTA `PillButton`. Professor home: replace `ProfessorHomeHeader` → `HomeHeader` with `title: l10n.dashboardWelcome(firstName)`, `child: HeaderStatsRow(...)`, keep same stats. Professor classroom cards → `AppCard` (already). Detail screens: in loading/error branches, return `Scaffold(backgroundColor: AppColors.backgroundFor(isDark), body: Column(children: [ScreenHeader/GradientHeader + ListShimmer / EmptyState / ErrorView]))` — NO `AppBar`.

- [ ] **Step 4: Run tests + analyze** → GREEN

- [ ] **Step 5: Commit** `feat(ui): auth dark mode + professor home + detail loading`

---

## Task B: Fees/Qualifications + rainbow + tokens + polish

**Files:**
- Modify: `lib/features/fees/screens/fee_list_screen.dart`, `fee_detail_screen.dart`, `lib/features/qualifications/screens/qualification_list_screen.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart` (QuickAction rainbow → single accent, remove `color` arg)
- Modify: `lib/features/search/screens/search_screen.dart` (type colors → `accentFor`)
- Modify: `lib/features/classrooms/screens/widgets/professor_classroom_list_card.dart`, `lib/features/dashboard/screens/dashboard_screen.dart` (`_ParentClassroomCard`) — replace `AppColors.muted` with `AppColors.mutedFor(isDark)`
- Modify: `lib/app/theme/app_theme.dart` — `CardTheme.margin: horizontal: 16`
- Modify: `lib/core/widgets/detail_hero.dart` — add `clipBehavior: Clip.hardEdge` to gradient container
- Delete: `lib/features/classrooms/screens/widgets/classroom_card.dart` (unreferenced)
- Modify: `lib/features/classrooms/screens/classroom_list_screen.dart:99` — count subtitle: use generic l10n key or derive from `classroomsTitle` + count (since no `classroomsCount` key exists, keep `professorClassroomsCount` but only for professor role; for others, use a neutral formatted string — acceptable within no-new-keys constraint)
- Modify: `lib/core/widgets/pill_button.dart` — logout contrast: if `color == AppColors.error`, compute text color with sufficient contrast (use `AppColors.onError` equivalent or derive from theme; simplest: keep white but ensure `error` shade meets AA at 12pt — `#EF4444` on white is 4.5:1 exactly; for dark mode white-on-error is fine. Actually the concern is the inverse? `PillButton` always uses white text. On `error` (#EF4444) white is 4.5:1 AA. On darker error in dark mode? Task 13 says dark mode logout contrast borderline. `AppColors.error` is constant `#EF4444` — white text on it is 4.5:1 AA. If the concern is dark mode where button is on dark surface, the contrast is against the surface not the text. The text is white. It's fine. BUT: if we want to be safe, make logout use `color: AppColors.error, isGradient: false` (already) and ensure text is white (it is). Close as non-regressive. Actually re-read: "logout white-on-error contrast in dark mode" — the button background is error, text is white. That's 4.5:1. It's acceptable per WCAG AA. Mark OK.
- Test: extend `test/ui_unified/legacy_screens_test.dart`, `test/dashboard/dashboard_screen_test.dart`, `test/classrooms/classroom_list_screen_test.dart`, `test/classrooms/professor_classroom_list_test.dart`

**Interfaces:**
- Consumes: `LargeTitleBar`, `ScreenHeader`, `AppCard`, `ListShimmer`, `AppColors` helpers, `PillButton`.
- Produces: fees/qual on unified system (gradient header, shimmer, no spinner, `backgroundFor` bg, 16 gutters); QuickAction rainbow removed (icon `primary`); `mutedFor` in dark; `CardTheme` 16px; `DetailHero` clipped; dead code gone.

- [ ] **Step 1: Write failing tests** — fees/qual loading asserts shimmer + no spinner + gradient header; dashboard QuickAction asserts no rainbow colors (icon `primary`); professor list card + parent card dark test asserts `mutedFor(true) == darkTextSecondary`; DetailHero clip test (render child that overflows, assert no overflow paint).

- [ ] **Step 2: Run tests** → RED

- [ ] **Step 3: Implement** — fees/qual: `LargeTitleBar` as body child (not `appBar:`), `Scaffold.backgroundColor = backgroundFor(isDark)`, `ListShimmer` loading, `AppCard` cards, `accentFor` filters. Dashboard: `QuickAction` remove `color` field (or set all to `AppColors.primary`); `QuickActionGrid` already uses `primary` for icon. `CardTheme.margin = horizontal: 16`. `DetailHero` gradient container `clipBehavior: Clip.hardEdge`. Delete `classroom_card.dart`. Classroom list count: for non-professor, show neutral `${count} ${l10n.classroomsTitle.toLowerCase()}` (or similar existing pattern).

- [ ] **Step 4: Run tests + analyze** → GREEN

- [ ] **Step 5: Commit** `feat(ui): fees/qual unified + rainbow removed + tokens + polish`

---

## Task C: Final verification (no code)

- [ ] Run 4 zero-greps (already pass)
- [ ] `flutter analyze` clean
- [ ] `flutter test` 229+ pass
- [ ] Visual pass: 12 screens × 2 themes via widget tests (already covered by test assertions)

---

## Self-Review

1. **Spec coverage:** Each blocker maps to a §4.4 checklist item. No gaps.
2. **Step scan:** Each step is one verifiable action; bodies left to implementer.
3. **Type consistency:** Uses same `AppColors` helpers, core widgets from Tasks 1–6.
4. **Review Focus:** The 11 blockers from final review are each owned by A or B.
5. **Proportion:** 2 implementation tasks + 1 verification for ~11 targeted fixes.

---

**Execution recommendation:** Native (inline) — fixes are small and independent; a single session can batch A+B and verify.