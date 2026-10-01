# Unificación visual: la UI del profesor como sistema único de la app

**Fecha:** 2026-10-01
**Estado:** diseño aprobado (enfoque C — híbrido), pendiente de revisión del plan de implementación.

## 1. Objetivo

Que toda la app de EFE Mobile tenga la interfaz que hoy tiene la sección de profesores: fondo
`#F5F6FA`, headers en gradiente azul con radio inferior 24, cards blancas con sombra difusa,
section labels en versalitas, botones r13/h46 y un único acento azul. La app deja de tener dos
identidades visuales paralelas (azul del profesor vs índigo del resto) y pasa a una sola.

## 2. Decisiones del usuario

| Pregunta | Respuesta |
|---|---|
| Color: ¿azul del profesor o índigo actual? | **Azul para toda la app** (reemplaza al índigo en tema, gradiente, nav, botones y estados) |
| Alcance de pantallas | **Todas**, incluido login/forgot-password y las pantallas legacy `fees` y `qualifications` |
| Modo oscuro | **Azul en claro y oscuro**: se definen las dos variantes y todas las pantallas respetan ambos |
| Enfoque técnico | **C — híbrido**: tokens en `ThemeData` + promover primitivos del profesor a `core/widgets` + migración pantalla por pantalla con checklist |

## 3. Revisión de la interfaz actual (hallazgos)

**Sección profesor (referencia, ya implementada):** gradiente `#5F92C9→#83B0E0` con radio inferior 24;
section label `10/w800/ls0.6 #8792B5`; `ProfessorCard` r16 / padding 13 / sombra `0x59232D3C@.12 blur 24
offset(0,10) spread −14`; filas r13; botones r13 h44-46; fondo `#F5F6FA`; acento `primarySoft` en
empty/error/filtros.

**Sección padres / resto (a unificar):** `LargeTitleBar` plano o nada, `AppCard` con sombra
`black@.04 blur 12`, `SectionHeader` 16/w600, `StatCard` con chips de iconos multicolor, gradiente
índigo `#4F46E5→#7C3AED`, gutters 20, botones r24/h52, estados de carga con `CircularProgressIndicator`
centrado (news, events, notifications, chat) y pantallas legacy con `AppBar` crudo + `Colors.grey`.

Problemas estructurales detectados:

1. `ProfessorColors` vive **fuera** del `ThemeData`; 26 archivos lo importan a mano. El tema sigue con
   seed índigo, así que `Theme.of(context).colorScheme.primary` es índigo incluso dentro de pantallas azules.
2. La rama de rol ramifica la UI en 8 archivos (`isProfessor` en `classroom_list`, `classroom_detail`,
   `student_detail` y 7 widgets propios), duplicando gutters, cards y acentos.
3. `isDark ? const Color(0xFF6366F1) : AppColors.primary` está hardcodeado en 15 archivos.
4. `PaginationBar` tiene el índigo hardcodeado: el listado de aulas del profesor muestra un índice de
   página índigo dentro del diseño azul.
5. El nav inferior cambia de acento por rol (`router.dart:42-44`) y nunca usa `navInactive`.
6. Dos sistemas de badge viven juntos en `core/widgets` (`GradeBadge` azul y `StatusBadge` índigo).
7. `roleProfessor = #3B82F6` no coincide con el azul de marca `#3F6EA8`.
8. No hay test del home de padres (`dashboard_screen`) y el botón `/fees` empuja una ruta inexistente.

## 4. Contrato de diseño

### 4.1 Tokens — `lib/app/theme/app_colors.dart` es la única paleta

Se reemplazan los valores índigo por los del profesor y se incorporan los tokens que hoy están en
`ProfessorColors` (que se elimina):

| Token | Valor | Nota |
|---|---|---|
| `primary` | `#3F6EA8` | era `#4F46E5` |
| `primarySoft` | `#5F92C9` | nuevo |
| `accent` | `#83B0E0` | nuevo |
| `primaryLight` | `#EBF0F6` | era `#EEF2FF`; tinte sólido de chips |
| `lightBackground` | `#F5F6FA` | era `#FAFAF9`; único fondo claro |
| `lightInk` | `#2F4A6B` | títulos de card/fila |
| `lightMuted` | `#71799A` | meta 11px |
| `sectionLabel` | `#8792B5` | sirve en claro **y** oscuro |
| `navInactive` | `#9AA2BD` | |
| `onPrimary` / `onPrimaryMuted` | `#FFFFFF` / `#C4CDEC` | texto sobre gradiente |
| `overlay` / `overlayStrong` | `0x1FFFFFFF` / `0x2EFFFFFF` | tiles de stats sobre gradiente |
| `present` / `absent` | `#2FA36C` / `#E05353` | |
| `gradeHigh/Mid/Warn/Low` + `gradeEmptyBackground` + `gradeColor()` + `formatGrade()` | escala del mockup | |
| `primaryGradient` | `[primarySoft, accent]` | gradiente de header (claro) |
| `primaryGradientDark` | `[primary, primarySoft]` | gradiente de header (oscuro) |
| `roleProfessor` | `= primary` | el resto de role colors no cambia |

Se **eliminan** `primaryDark` (sin usos) y `ProfessorColors`. `secondary`/`secondaryLight` quedan
tocados solo si `flutter analyze` lo pide.

### 4.2 Helpers de brightness (matar el índigo hardcodeado)

```dart
static Color accentFor(bool isDark) => isDark ? accent : primary;      // texto e iconos sobre superficie
static Color inkFor(bool isDark)    => isDark ? darkTextPrimary : lightInk;
static Color mutedFor(bool isDark)  => isDark ? darkTextSecondary : lightMuted;
static Color backgroundFor(bool isDark) => isDark ? darkBackground : lightBackground;
static Color chipFor(bool isDark)   => isDark ? darkSurfaceElevated : primaryLight;
```

Regla: los 15 sitios con `isDark ? Color(0xFF6366F1) : AppColors.primary` pasan a `accentFor(isDark)`.

### 4.3 Widgets base (los del profesor, con nombre neutral)

| Widget | Especificación |
|---|---|
| `GradientHeader` (nuevo, `core/widgets/gradient_header.dart`) | full-width, `primaryGradient` / `primaryGradientDark`, `borderRadius: vertical(bottom: 24)`, padding `fromLTRB(16, statusBar+12, 16, 16)`. Reemplaza a `ProfessorGradientHeader`. |
| `ScreenHeader` (mismo archivo) | `GradientHeader` + back `caretLeft` 18 `onPrimary`, título **14/w800 `onPrimary`**, subtítulo 11 `onPrimaryMuted`, `child` opcional con gap 12. Reemplaza a `ProfessorScreenHeader`. |
| `HomeHeader` (nuevo, `core/widgets/home_header.dart`) | `GradientHeader` + fila `[AppAvatar 48 showBorder, saludo 12 onPrimaryMuted + nombre 20 w800 onPrimary, 2 botones 40×40 r12 bg overlay]` + `child`. Extraído de `ProfessorHomeHeader`. |
| `HeaderStatsRow` (nuevo, `core/widgets/header_stats_row.dart`) | fila de `Expanded` tiles, gap 10, r14, bg `overlay` (`overlayStrong` si `highlighted`), valor **24/w900 `onPrimary`**, label 11 `onPrimaryMuted`. Extraído de `ProfessorStatsRow`; recibe `List<HeaderStat{value,label,highlighted}>`. |
| `LargeTitleBar` (restyle in place, API intacta) | fondo = gradiente, radio inferior 24, título **24/w800 blanco**, back blanco 18, `SystemUiOverlayStyle.light`, gutters 16. Se usa como `body: Column` en todos lados (nadie lo usa como `appBar:`), así que `preferredSize` no afecta layout. |
| `AppCard` (fusiona `ProfessorCard`) | r16, **padding 14**, sombra `Color(0x59232D3C)` `.12` (oscuro `.3`) blur 24 offset(0,10) spread −14, bg surface, param opcional `selected` → borde 1.5 `primarySoft`. |
| `SectionHeader` (restyle in place) | título `toUpperCase()` interno, **10/w800/ls0.6** `sectionLabel`; acción 11/w800 `accentFor(isDark)`; padding horizontal **16**. |
| `StatCard` | r16 + sombra `AppCard`, chip 40 r12 bg `chipFor(isDark)`, icono `iconColor` (param obligatorio), valor 22/w800 `inkFor`, label 12 `mutedFor`. |
| `DetailHero` | gradiente por defecto = `primaryGradient`/`Dark` (ya azul por token) + **radio inferior 24**. |
| `EmptyState` / `ErrorView` | `accentColor` por defecto = `accentFor(isDark)`; botón **r13 h44 11/w800**. Las pantallas dejan de pasar `accentColor`. |
| `PillButton` | **r13, height 46**, texto 12/w800, gradiente = `primaryGradient`. |
| `PaginationBar` | acento = `accentFor(isDark)` (fin del índigo hardcodeado). |
| `ListShimmer` / `LoadingShimmer` | defaults: padding 16, itemHeight 68, radius 16. |
| `StatusBadge` / `GradeBadge` | sin cambios (semánticos y ya azules). |

### 4.4 Reglas por pantalla (checklist de migración)

1. `Scaffold.backgroundColor = AppColors.backgroundFor(isDark)`.
2. Raíz de sección / listado → `LargeTitleBar` (gradiente); sub-pantalla empujada → `ScreenHeader`;
   home → `HomeHeader`. Ninguna pantalla con `AppBar` crudo.
3. Gutters **16** (no 20).
4. Títulos de sección → `SectionHeader` (versalitas), nunca texto suelto.
5. Cards → `AppCard` (r16/14/sombra del sistema).
6. `EmptyState`/`ErrorView` **sin** `accentColor` explícito.
7. Loading → skeleton `ListShimmer`; **prohibido** `CircularProgressIndicator` centrado en listados.
8. Acentos (tabs, filtros, chips, índice de paginación) → `accentFor(isDark)`; **ninguna rama por rol**.
9. Botones → r13/h46 (vía tema).

### 4.5 Accesibilidad

`primary #3F6EA8` sobre blanco = 5.2:1 ✓; `accent #83B0E0` sobre `#0F172A` = 7.6:1 ✓;
`primarySoft #5F92C9` con texto blanco = 3.3:1 ✗ → **`primarySoft` solo para rellenos decorativos**
(nunca para texto pequeño ni para rellenos con texto blanco encima). Por eso la pill del nav
selectora pasa de `primarySoft` a `primary`.

### 4.6 Modo oscuro

Mismos patrones, tokens oscuros: fondo `darkBackground`, cards `darkSurface`, títulos
`darkTextPrimary`, meta `darkTextSecondary`, sectionLabel `#8792B5` (sirve en ambos), acento `accent`,
gradiente `primaryGradientDark`, chips `darkSurfaceElevated`, `SystemUiOverlayStyle.light` en headers.

## 5. Fuera de alcance

- **Rutas/navegación:** no se agregan ni cambian rutas. La acción `/fees` del dashboard sigue sin ruta
  (bug conocido, elegido como fuera de alcance); `FeeListScreen`/`QualificationListScreen` se restylean
  igual porque alguien podrá enlazarlas después.
- **Contenido, copy, l10n:** sin claves nuevas; se usan las existentes.
- **Arquitectura:** sin cambios de providers, repos, modelos ni dependencias.
- **Funcionalidad:** sin cambios de comportamiento; solo presentación.

## 6. Criterios de aceptación

1. `grep -rn "0xFF4F46E5\|0xFF6366F1\|0xFF7C3AED\|0xFFEEF2FF\|0xFFFAFAF9\|0xFF8B5CF6" lib` → 0 resultados.
2. `grep -rn "professor_colors" lib test` → 0 resultados; el archivo no existe.
3. `grep -rn "isProfessor" lib` → 0 resultados en UI (solo `user_model.dart` conserva el getter).
4. `flutter analyze` sin errores ni warnings nuevos; `flutter test` verde.
5. Cada pantalla cumple el checklist 4.4, en tema claro y oscuro.
6. Los tests de rol prueban que profesor y padres renderizan **el mismo** sistema visual.
