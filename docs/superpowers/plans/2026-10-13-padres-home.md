# Rediseño del Home de Padres (etapa 1) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** El inicio del rol padre es el del mockup — “Hola / Familia X”, alerta de mora con “Pagar”, una tarjeta por hijo con Promedio/Asistencia, acciones Cuotas/Boletín/Chat y pestaña Pagos — con datos reales de `GET /statistics/dashboard` en un solo request.

**Architecture:** El backend agrega `myChildrenSummary` a `StatisticsService::getParentData`; el repo móvil parsea un `ParentHomeData` embebido en `DashboardData`; `DashboardScreen` delega por rol en una `ParentHomeScreen` nueva (patrón `ProfessorHomeScreen`) compuesta por 3 widgets nuevos; el branch 1 del shell suma `/payments` con `initialLocation` por rol; la ficha del alumno suma una sección “Aulas”.

**Tech Stack:** Flutter 3.x + Riverpod 2 + go_router 14.8.1 + freezed 2.4.4 (build_runner) + l10n ARB; Laravel 11 (`efe-app`, contenedor `dev-efe`).

**Spec:** `docs/superpowers/specs/2026-10-13-padres-home-design.md`

## Global Constraints

- Home de padres = **un solo request** (`GET /api/v1/statistics/dashboard`); prohibido N+1 desde el home.
- No cambiar comportamiento de otros roles (profesor/admin/estudiante) ni los arrays existentes (`myChildrenAbsenceRate`, `myChildrenGrades`, `gradeComparison`, `myFamilyAccountStatus`).
- Textos ES+EN en `lib/l10n/app_es.arb` + `app_en.arb` + `flutter gen-l10n`; sin strings de usuario hardcodeados.
- Claro y oscuro; contraste ≥4.5:1; `primarySoft` solo relleno decorativo (nunca texto pequeño).
- Dato faltante ⇒ “—” y campos ocultos; nunca 0 inventado.
- **efe-app: NO ejecutar Pest / `php artisan test`** (AGENTS.md borra la DB de desarrollo). Verificación backend: `php -l`, `./vendor/bin/pint`, tinker en el contenedor `dev-efe`.
- Al cerrar cada tarea Flutter: `flutter analyze` limpio + `flutter test` en verde.
- Commits por tarea; mensajes `feat:`/`fix:`/`docs:` en español, estilo del repo.

## Review Focus

1. Padre con hijos pero **sin ningún** `myChildrenSummary` (backend viejo) ⇒ tarjetas con “—” y sin subtítulo, sin excepción. (Task 8)
2. `user.name` de **una sola palabra o vacío** ⇒ no inventar “Familia X”. (Task 8)
3. Payload con números **como string** (`"total_owed": "1300000"`, `"average_grade": "7.9"`) ⇒ el parser los tolera. (Task 3)
4. Orden distinto entre `/relations` y `details.myChildrenSummary` ⇒ join por `userId`, nunca por índice. (Task 8)
5. Pantalla angosta **320px** con alerta + tarjetas + acciones ⇒ sin overflow. (Task 8)

---

### Task 1: Backend — `myChildrenSummary` por hijo (efe-app)

**Files:**
- Modify: `/opt/dev/efe-app/app/Services/StatisticsService.php` (`getParentData`, ~L85-191)
- Test (escribir, **no ejecutar**): `/opt/dev/efe-app/tests/Feature/Api/StatisticsTest.php`

**Interfaces:**
- Consumes: `$parent->students()->with('classrooms')`, `Absences`, `Qualifications` (ya importados en el archivo).
- Produces: `details.myChildrenSummary` = lista de `{student_id: string(uuid), user_id: int|null, child_name: string, classroom_name: string, classrooms_count: int, year: string, average_grade: float|null, attendance_rate: float|null}`.

- [ ] **Step 1: Escribir el test Pest (no ejecutar)**

Agregar a `tests/Feature/Api/StatisticsTest.php` (usa `RefreshDatabase`; los tests corren en SQLite `:memory:` según `phpunit.xml`; **no ejecutar** por regla de AGENTS.md):

```php
test('parent dashboard exposes myChildrenSummary per child', function () {
    $user = User::factory()->create();
    $user->studentData()->delete();
    $user->professorData()->delete();
    $user->userData()->delete();
    $parent = \App\Models\ParentData::factory()->create(['user_id' => $user->id]);

    // Hijo con aula, nota numérica y una inasistencia
    $childUser = User::factory()->create();
    $child = \App\Models\StudentData::factory()->create([
        'user_id' => $childUser->id,
        'fullname' => 'Hijo Uno',
        'year' => '3',
    ]);
    $parent->students()->attach($child->id);
    $classroom = \App\Models\Classrooms::factory()->create(['name' => '3G X']);
    $child->classrooms()->attach($classroom->id);
    \App\Models\Qualifications::create([
        'student_id' => $child->id, 'classroom_id' => $classroom->id,
        'score' => '8', 'type' => 'Escrito', 'period' => '1',
    ]);
    \App\Models\Absences::create([
        'student_id' => $child->id, 'classroom_id' => $classroom->id,
        'date' => now()->toDateString(), 'quantity' => 1,
    ]);

    // Hijo sin datos
    $child2 = \App\Models\StudentData::factory()->create(['fullname' => 'Hijo Dos']);
    $parent->students()->attach($child2->id);

    Sanctum::actingAs($user);

    $response = $this->getJson('/api/v1/statistics/dashboard');

    $response->assertStatus(200)
        ->assertJsonPath('data.details.myChildrenSummary.0.student_id', $child->id)
        ->assertJsonPath('data.details.myChildrenSummary.0.user_id', $childUser->id)
        ->assertJsonPath('data.details.myChildrenSummary.0.child_name', 'Hijo Uno')
        ->assertJsonPath('data.details.myChildrenSummary.0.classroom_name', '3G X')
        ->assertJsonPath('data.details.myChildrenSummary.0.year', '3')
        ->assertJsonPath('data.details.myChildrenSummary.0.average_grade', 8)
        ->assertJsonPath('data.details.myChildrenSummary.1.average_grade', null)
        ->assertJsonPath('data.details.myChildrenSummary.1.attendance_rate', null);
});
```

- [ ] **Step 2: Implementar `myChildrenSummary` en `getParentData`**

Reglas (spec §5): promedio = media de notas **numéricas** filtradas en PHP (`is_numeric`, sin regex PG para que el test corra en SQLite); asistencia = `clamp(100 − inasistencias/clases×100, 0, 100)` con el mismo cálculo de `myChildrenAbsenceRate`, `null` si no hay clases; `classroom_name` = primera aula (`$child->classrooms->first()?->name ?? ''`).

Insertar el bloque **después** de `$myChildrenAbsenceRate`:

```php
$myChildrenSummary = $children->map(function ($child) use ($dateStart, $dateEnd) {
    $totalAbsences = (int) Absences::where('student_id', $child->id)
        ->whereBetween('date', [$dateStart, $dateEnd])
        ->sum(DB::raw('CAST(quantity AS INTEGER)'));

    $classroomIds = $child->classrooms->pluck('id');
    $totalClasses = $classroomIds->isNotEmpty()
        ? (int) Absences::whereIn('classroom_id', $classroomIds)
            ->whereBetween('date', [$dateStart, $dateEnd])
            ->distinct('date')->count('date')
        : 0;

    $scores = Qualifications::where('student_id', $child->id)
        ->pluck('score')
        ->filter(fn ($score) => is_numeric($score));

    return [
        'student_id' => $child->id,
        'user_id' => $child->user_id,
        'child_name' => $child->fullname,
        'classroom_name' => $child->classrooms->first()?->name ?? '',
        'classrooms_count' => $child->classrooms->count(),
        'year' => $child->year ?? '',
        'average_grade' => $scores->isNotEmpty() ? round((float) $scores->avg(), 2) : null,
        'attendance_rate' => $totalClasses > 0
            ? round(max(0, min(100, 100 - (($totalAbsences / $totalClasses) * 100))), 2)
            : null,
    ];
})->values()->toArray();
```

Además, envolver los bloques PG-only (`$myChildrenGrades` y `$gradeComparison`, que usan `score ~ '^[0-9]+…'`) en `try { … } catch (QueryException $e) { … = []; }` (importar `Illuminate\Database\QueryException`) para que el resumen sobreviva también en el SQLite de tests. En PostgreSQL el resultado es idéntico al actual. Agregar `'myChildrenSummary' => $myChildrenSummary,` al `return` (los arrays existentes quedan igual).

- [ ] **Step 3: Verificar sintaxis**

Run: `php -l app/Services/StatisticsService.php`
Expected: `No syntax errors detected`

- [ ] **Step 4: Formatear y verificar estilo**

Run: `./vendor/bin/pint app/Services/StatisticsService.php tests/Feature/Api/StatisticsTest.php && ./vendor/bin/pint --test app/Services/StatisticsService.php tests/Feature/Api/StatisticsTest.php`
Expected: PASS

- [ ] **Step 5: Verificación live (tinker dentro del contenedor; NO Pest)**

Run:
```bash
docker exec dev-efe php artisan tinker --execute '
$parent = App\Models\ParentData::whereHas("students")->first();
auth()->setUser($parent->user);
$out = app(App\Services\StatisticsService::class)->getParentData($parent, ["date_start" => null, "date_end" => null]);
echo json_encode(["summary" => $out["myChildrenSummary"] ?? "NO_KEY"], JSON_UNESCAPED_UNICODE);
'
```
Expected: `{"summary":[...]}` con `student_id`, `classroom_name`, `average_grade`, `attendance_rate` por hijo (antes de este cambio devuelve `"NO_KEY"`; receta validada el 2026-10-13).

- [ ] **Step 6: Commit**

```bash
git add app/Services/StatisticsService.php tests/Feature/Api/StatisticsTest.php
git commit -m "feat(api): myChildrenSummary por hijo en estadisticas de padres"
```

---

### Task 2: Tokens de mora + claves l10n

**Files:**
- Modify: `lib/app/theme/app_colors.dart`
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
- Regenerar: `lib/l10n/app_localizations*.dart` (vía `flutter gen-l10n`)

**Interfaces:**
- Produces: tokens `dangerSoft`, `dangerInk`, `dangerInkMuted`, `darkDangerSoft`, `darkDangerInk`, `darkDangerInkMuted`; getters l10n `parentGreeting`, `parentFamilyTitle(String surname)`, `parentOverdueFeesCount(int count)`, `parentMoraTotal`, `parentPayAction`, `navPayments`, `parentActionBoletin`, `parentChooseChild`.

- [ ] **Step 1: Agregar tokens en `lib/app/theme/app_colors.dart`**

Después del bloque `// Attendance`:

```dart
// Parent home — mora (rojos con contraste ≥4.5:1)
static const Color dangerSoft = Color(0xFFFDEAEA);
static const Color dangerInk = Color(0xFFB53434);
static const Color dangerInkMuted = Color(0xFF8F4A4A);
static const Color darkDangerSoft = Color(0xFF3A2327);
static const Color darkDangerInk = Color(0xFFF0A9A9);
static const Color darkDangerInkMuted = Color(0xFFE0A0A0);
```

- [ ] **Step 2: Agregar claves en `app_es.arb` y `app_en.arb`**

ES (con metadata de placeholders como el resto del archivo):

```json
"parentGreeting": "Hola",
"parentFamilyTitle": "Familia {surname}",
"@parentFamilyTitle": { "placeholders": { "surname": { "type": "String" } } },
"parentOverdueFeesCount": "{count, plural, =1{1 cuota vencida} other{{count} cuotas vencidas}}",
"@parentOverdueFeesCount": { "placeholders": { "count": { "type": "int" } } },
"parentMoraTotal": "Mora total",
"parentPayAction": "Pagar",
"navPayments": "Pagos",
"parentActionBoletin": "Boletín",
"parentChooseChild": "Elegí un hijo",
```

EN: mismos keys con `"Hi"`, `"The {surname} Family"`, `"{count, plural, =1{1 overdue installment} other{{count} overdue installments}}"`, `"Total overdue"`, `"Pay"`, `"Payments"`, `"Report Card"`, `"Choose a child"`.

- [ ] **Step 3: Regenerar y verificar**

Run: `flutter gen-l10n && grep -c "parentFamilyTitle\|parentOverdueFeesCount" lib/l10n/app_localizations.dart`
Expected: ≥2 (getters generados)

- [ ] **Step 4: Análisis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_colors.dart lib/l10n/
git commit -m "feat(ui): tokens de mora y copy del home de padres (es/en)"
```

---

### Task 3: Modelo `ParentHomeData` + parseo del dashboard

**Files:**
- Create: `lib/features/dashboard/domain/parent_home_data.dart`
- Modify: `lib/features/dashboard/domain/dashboard_data.dart`
- Modify: `lib/features/dashboard/data/dashboard_repository.dart`
- Test: `test/dashboard/dashboard_repository_test.dart`
- Regenerar: `dart run build_runner build --delete-conflicting-outputs`

**Interfaces:**
- Consumes: payload de Task 1 (`metrics.fees_overdue`, `metrics.total_owed`, `details.myChildrenSummary`).
- Produces: `ParentChildSummary.fromJson(Map<String, dynamic>)`, `ParentHomeData`, `DashboardData.parentHome` (nullable, solo rol padre). Consumido por Tasks 5/6/8.

- [ ] **Step 1: Escribir los tests que fallan**

Agregar al `group('DashboardRepository')` de `test/dashboard/dashboard_repository_test.dart`:

```dart
test('maps parent home data from metrics and details', () async {
  final repository = DashboardRepository(
    _FakeDashboardApi({
      'data': {
        'role': 'parent',
        'metrics': {'children_count': 2, 'fees_overdue': 2, 'total_owed': '1300000'},
        'details': {
          'myChildrenSummary': [
            {
              'student_id': 'uuid-1', 'user_id': 11, 'child_name': 'Ana Pérez',
              'classroom_name': '3G X', 'classrooms_count': 1, 'year': '3',
              'average_grade': '7.9', 'attendance_rate': 95.0,
            },
            {
              'student_id': 'uuid-2', 'user_id': 12, 'child_name': 'Bruno Pérez',
              'classroom_name': '', 'classrooms_count': 0, 'year': '',
              'average_grade': null, 'attendance_rate': null,
            },
          ],
        },
      },
    }),
  );

  final data = await repository.getDashboard();

  expect(data.parentHome, isNotNull);
  expect(data.parentHome!.overdueFeesCount, 2);
  expect(data.parentHome!.moraTotal, 1300000.0); // string numérico tolerado
  expect(data.parentHome!.children, hasLength(2));
  expect(data.parentHome!.children.first.studentId, 'uuid-1');
  expect(data.parentHome!.children.first.userId, 11);
  expect(data.parentHome!.children.first.averageGrade, 7.9);
  expect(data.parentHome!.children[1].averageGrade, isNull);
  expect(data.parentHome!.children[1].attendanceRate, isNull);
});

test('leaves parentHome null for non-parent roles', () async {
  final repository = DashboardRepository(
    _FakeDashboardApi({'data': {'role': 'professor', 'metrics': {}, 'details': {}}}),
  );
  final data = await repository.getDashboard();
  expect(data.parentHome, isNull);
});

test('parent payload without myChildrenSummary degrades to empty list', () async {
  final repository = DashboardRepository(
    _FakeDashboardApi({'data': {'role': 'parent', 'metrics': {}, 'details': {}}}),
  );
  final data = await repository.getDashboard();
  expect(data.parentHome, isNotNull);
  expect(data.parentHome!.children, isEmpty);
});
```

- [ ] **Step 2: Correr los tests y verificar que fallan**

Run: `flutter test test/dashboard/dashboard_repository_test.dart`
Expected: FAIL de compilación (`parentHome` no existe)

- [ ] **Step 3: Crear `parent_home_data.dart`**

Freezed sin json_serializable, con `fromJson` manual (patrón `RelationModel`/`NewsModel`):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parent_home_data.freezed.dart';

@freezed
class ParentChildSummary with _$ParentChildSummary {
  const factory ParentChildSummary({
    @Default(0) int userId,
    @Default('') String studentId,
    @Default('') String name,
    @Default('') String classroomName,
    @Default(0) int classroomsCount,
    @Default('') String year,
    double? averageGrade,
    double? attendanceRate,
  }) = _ParentChildSummary;

  factory ParentChildSummary.fromJson(Map<String, dynamic> json) =>
      ParentChildSummary(
        userId: _asInt(json['user_id']),
        studentId: json['student_id']?.toString() ?? '',
        name: json['child_name']?.toString() ?? '',
        classroomName: json['classroom_name']?.toString() ?? '',
        classroomsCount: _asInt(json['classrooms_count']),
        year: json['year']?.toString() ?? '',
        averageGrade: _asDouble(json['average_grade']),
        attendanceRate: _asDouble(json['attendance_rate']),
      );
}

@freezed
class ParentHomeData with _$ParentHomeData {
  const factory ParentHomeData({
    @Default(0) int overdueFeesCount,
    @Default(0.0) double moraTotal,
    @Default([]) List<ParentChildSummary> children,
  }) = _ParentHomeData;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
```

- [ ] **Step 4: Conectar `DashboardData` y el repository**

En `lib/features/dashboard/domain/dashboard_data.dart`: importar `parent_home_data.dart` y agregar el campo (anotado para que json_serializable no lo intente parsear; el repository lo llena a mano):

```dart
@JsonKey(includeFromJson: false, includeToJson: false)
ParentHomeData? parentHome,
```

En `lib/features/dashboard/data/dashboard_repository.dart`: tras calcular `role`, agregar `final parentHome = role == 'parent' ? _parseParentHome(m, d) : null;`, pasarlo al `DashboardData(...)` y agregar:

```dart
ParentHomeData _parseParentHome(Map<String, dynamic> m, Map<String, dynamic> d) {
  final raw = d['myChildrenSummary'];
  final children = raw is List
      ? raw
          .whereType<Map<String, dynamic>>()
          .map(ParentChildSummary.fromJson)
          .toList()
      : <ParentChildSummary>[];
  return ParentHomeData(
    overdueFeesCount: _asInt(m['fees_overdue']),
    moraTotal: _asDouble(m['total_owed']),
    children: children,
  );
}
```

Nota: si freezed rechaza `@JsonKey(includeFromJson: false, includeToJson: false)` en el campo, alternativa sin riesgo: quitar `part 'dashboard_data.g.dart'` y el json_serializable de ese modelo, pasando a `fromJson` manual (patrón del repo). El build_runner debe terminar sin errores.

- [ ] **Step 5: Regenerar y correr**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/dashboard/dashboard_repository_test.dart`
Expected: PASS (3 tests nuevos + 3 existentes)

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/features/dashboard/domain/ lib/features/dashboard/data/dashboard_repository.dart test/dashboard/dashboard_repository_test.dart
git commit -m "feat(dashboard): ParentHomeData parseado de metrics+details para padres"
```

---

### Task 4: `HomeHeader` — saludo override + lupa opcional

**Files:**
- Modify: `lib/core/widgets/home_header.dart`
- Test: `test/core/headers_test.dart`

**Interfaces:**
- Produces: `HomeHeader({String? greeting, VoidCallback? onSearch, …})` — `greeting` pisa el saludo por hora; con `onSearch == null` no se renderiza la lupa. Aditivo: profesor/pantallas genéricas pasan `onSearch` y quedan igual.

- [ ] **Step 1: Escribir el test que falla**

Agregar en `test/core/headers_test.dart` (importar `package:phosphor_flutter/phosphor_flutter.dart`):

```dart
testWidgets('HomeHeader uses greeting override and hides search when null',
    (tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: HomeHeader(
        name: 'María López',
        greeting: 'Hola',
        unreadCount: 0,
        onNotifications: () {},
      ),
    ),
  ));
  expect(find.text('Hola'), findsOneWidget);
  expect(find.byIcon(PhosphorIconsRegular.magnifyingGlass), findsNothing);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/headers_test.dart`
Expected: FAIL (no existe `greeting`; la lupa se renderiza igual)

- [ ] **Step 3: Implementar**

En `home_header.dart`: agregar `final String? greeting;` + parámetro en el constructor; `_greeting(BuildContext)` devuelve `greeting ?? _timeGreeting(context)` (renombrar el cuerpo actual). Envolver el segundo `_HeaderIconButton` (lupa) en `if (onSearch != null) ...` manteniendo el `SizedBox(width: 10)` dentro del condicional.

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/headers_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/home_header.dart test/core/headers_test.dart
git commit -m "feat(ui): HomeHeader acepta saludo custom y oculta la lupa sin onSearch"
```

---

### Task 5: Widget alerta de mora

**Files:**
- Create: `lib/features/dashboard/screens/widgets/parent_overdue_fees_card.dart`
- Test: `test/dashboard/parent_overdue_fees_card_test.dart`

**Interfaces:**
- Consumes: tokens de Task 2, `AppFormatters.formatCurrency(double)`, l10n `parentOverdueFeesCount/parentMoraTotal/parentPayAction`.
- Produces: `ParentOverdueFeesCard({required int count, required double total, required VoidCallback onPay})` (usado por Task 8).

- [ ] **Step 1: Escribir el test que falla**

Crear `test/dashboard/parent_overdue_fees_card_test.dart` (usar `../helpers/localized_app.dart`):

```dart
testWidgets('renders count, formatted total and triggers pay', (tester) async {
  var paid = false;
  await tester.pumpWidget(localizedApp(
    home: Scaffold(
      body: ParentOverdueFeesCard(count: 2, total: 1300000, onPay: () => paid = true),
    ),
  ));
  expect(find.text('2 cuotas vencidas'), findsOneWidget);
  expect(find.text(r'Mora total $1.300.000,00'), findsOneWidget);
  await tester.tap(find.text('Pagar'));
  expect(paid, isTrue);
});

testWidgets('singular copy and danger tokens in light/dark', (tester) async {
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: ParentOverdueFeesCard(count: 1, total: 50000, onPay: () {})),
  ));
  expect(find.text('1 cuota vencida'), findsOneWidget);
  final light = tester.widget<Container>(find.byKey(const Key('parent-mora-card')));
  expect((light.decoration as BoxDecoration).color, AppColors.dangerSoft);

  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: Brightness.dark),
    home: Scaffold(body: ParentOverdueFeesCard(count: 1, total: 50000, onPay: () {})),
  ));
  final dark = tester.widget<Container>(find.byKey(const Key('parent-mora-card')));
  expect((dark.decoration as BoxDecoration).color, AppColors.darkDangerSoft);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/dashboard/parent_overdue_fees_card_test.dart`
Expected: FAIL (widget no existe)

- [ ] **Step 3: Implementar el widget**

`Container(key: Key('parent-mora-card'))` con `dangerSoft`/`darkDangerSoft`, radio 14, sombra rojiza suave (blur 20, offset (0,8), spread −14, `AppColors.absent.withOpacity(.25)`), `Padding(11,13)`, `Row`: `Expanded(Column(título 11/w800 dangerInk, subtítulo 11 dangerInkMuted con "Mora total $…"))` + botón `GestureDetector`→`Material/InkWell` con `Container` (radio 9, padding h12 v6, fondo `dangerInk` claro / `darkDangerInk` oscuro, texto `parentPayAction` 11/w800 blanco claro / `darkDangerSoft` oscuro). El conteo se formatea con `l10n.parentOverdueFeesCount(count)` y el monto con `AppFormatters.formatCurrency(total)`.

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/dashboard/parent_overdue_fees_card_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze`

```bash
git add lib/features/dashboard/screens/widgets/parent_overdue_fees_card.dart test/dashboard/parent_overdue_fees_card_test.dart
git commit -m "feat(ui): alerta de mora del home de padres"
```

---

### Task 6: Widget tarjeta de hijo

**Files:**
- Create: `lib/features/dashboard/screens/widgets/parent_child_card.dart`
- Test: `test/dashboard/parent_child_card_test.dart`

**Interfaces:**
- Consumes: `ParentChildSummary` (Task 3), `AppAvatar`, `AppColors.formatGrade`, l10n `gradesGridAverage`/`dashboardAttendance`.
- Produces: `ParentChildCard({required String name, ParentChildSummary? summary, required VoidCallback onTap})` (usado por Task 8).

- [ ] **Step 1: Escribir el test que falla**

```dart
const _ana = ParentChildSummary(
  userId: 11, studentId: 's-ana', name: 'Ana Pérez', classroomName: '3G X',
  classroomsCount: 1, year: '3', averageGrade: 7.9, attendanceRate: 95.0,
);

testWidgets('renders name, subtitle and stats', (tester) async {
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: ParentChildCard(name: 'Ana Pérez', summary: _ana, onTap: () {})),
  ));
  expect(find.text('Ana Pérez'), findsOneWidget);
  expect(find.text('3G X · 3° año'), findsOneWidget);
  expect(find.text('7.9'), findsOneWidget);
  expect(find.text('95%'), findsOneWidget);
  expect(find.text('Promedio'), findsOneWidget);
  expect(find.text('Asistencia'), findsOneWidget);
});

testWidgets('shows dashes and hides subtitle without summary data', (tester) async {
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: ParentChildCard(name: 'Bruno Pérez', summary: null, onTap: () {})),
  ));
  expect(find.text('—'), findsNWidgets(2));
  expect(find.textContaining('·'), findsNothing);
});

testWidgets('tapping triggers the callback', (tester) async {
  var taps = 0;
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: ParentChildCard(name: 'Ana Pérez', summary: _ana, onTap: () => taps++)),
  ));
  await tester.tap(find.text('Ana Pérez'));
  expect(taps, 1);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/dashboard/parent_child_card_test.dart`
Expected: FAIL (widget no existe)

- [ ] **Step 3: Implementar el widget**

`AppCard(onTap)` con `Row`: `AppAvatar(name: name, size: 34)` + `Expanded(Column(nombre 13/w800 `inkFor(isDark)`, subtítulo 10 `mutedFor(isDark)`))`. Subtítulo: `classroomName` + `year` → `'$classroomName · $year° año'`; solo uno → ese; ninguno → no renderizar. Tiles: `Row` de 2 `Expanded` con fondo `chipFor(isDark)`, radio 11, padding 9; valor 16/w900 `accentFor(isDark)` (`averageGrade` → `AppColors.formatGrade`; `attendanceRate` → `'${value.round()}%'`; null → `'—'`), label 9 `mutedFor(isDark)` (`gradesGridAverage`, `dashboardAttendance`). No caret.

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/dashboard/parent_child_card_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/dashboard/screens/widgets/parent_child_card.dart test/dashboard/parent_child_card_test.dart
git commit -m "feat(ui): tarjeta de hijo con promedio y asistencia"
```

---

### Task 7: Widget acciones rápidas

**Files:**
- Create: `lib/features/dashboard/screens/widgets/parent_quick_actions.dart`
- Test: `test/dashboard/parent_quick_actions_test.dart`

**Interfaces:**
- Produces: `ParentQuickActions({required VoidCallback onFees, required VoidCallback onBoletin, required VoidCallback onChat})` (usado por Task 8).

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('renders the three actions and fires their callbacks', (tester) async {
  var fees = 0, boletin = 0, chat = 0;
  await tester.pumpWidget(localizedApp(
    home: Scaffold(body: ParentQuickActions(
      onFees: () => fees++, onBoletin: () => boletin++, onChat: () => chat++,
    )),
  ));
  expect(find.text('Cuotas'), findsOneWidget);
  expect(find.text('Boletín'), findsOneWidget);
  expect(find.text('Chat'), findsOneWidget);
  await tester.tap(find.text('Cuotas'));
  await tester.tap(find.text('Boletín'));
  await tester.tap(find.text('Chat'));
  expect([fees, boletin, chat], [1, 1, 1]);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/dashboard/parent_quick_actions_test.dart`
Expected: FAIL (widget no existe)

- [ ] **Step 3: Implementar el widget**

`Row` de 3 `Expanded` (gap 8): `Material/InkWell` + `Container` fondo `lightSurface`/`darkSurface`, radio 13, padding v12 h8, texto centrado 11/w800 `accentFor(isDark)` (solo texto, sin iconos, como el mockup). Labels `feesTitle`, `parentActionBoletin`, `navChat`.

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/dashboard/parent_quick_actions_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze + commit**

```bash
git add lib/features/dashboard/screens/widgets/parent_quick_actions.dart test/dashboard/parent_quick_actions_test.dart
git commit -m "feat(ui): acciones rapidas del home de padres"
```

---

### Task 8: `ParentHomeScreen` + delegación por rol + limpieza

**Files:**
- Create: `lib/features/dashboard/screens/parent_home_screen.dart`
- Modify: `lib/features/dashboard/screens/dashboard_screen.dart`
- Delete: `lib/features/dashboard/screens/widgets/parent_children_section.dart`
- Delete: `test/dashboard/parent_children_section_test.dart`
- Rewrite: `test/dashboard/dashboard_screen_test.dart`
- Create: `test/dashboard/parent_home_screen_test.dart`

**Interfaces:**
- Consumes: `ParentHomeData`/`ParentChildSummary` (T3), `HomeHeader.greeting` (T4), `ParentOverdueFeesCard` (T5), `ParentChildCard` (T6), `ParentQuickActions` (T7), `relationsProvider`, `dashboardProvider`, `unreadCountProvider`.
- Produces: `ParentHomeScreen` (rol padre en `DashboardScreen`). Rutas que navega: `/students/{student_id}`, `/payments`, `/chat`, `/notifications` (T9 crea `/payments` real; en tests se pumpea una ruta dummy).

- [ ] **Step 1: Escribir los tests que fallan**

`test/dashboard/parent_home_screen_test.dart` — scaffold (fakes y helpers):

```dart
// Fakes: _FakeParentAuthRepository({String name = 'María López'}), _FakeDashboardRepository({DashboardData? data, bool fails})
// y _FakeRelationsRepository({List<RelationModel> children, bool fails}) — mismos moldes que
// test/dashboard/parent_children_section_test.dart (copiar antes de borrarlo en el Step 4)
// + parámetro opcional de nombre/falla.

const _ana = RelationModel(id: 'r1', fullname: 'Ana Pérez', role: 'student', userId: 11);
const _bruno = RelationModel(id: 'r2', fullname: 'Bruno Pérez', role: 'student', userId: 12);

DashboardData _parentData({
  int overdue = 2,
  List<ParentChildSummary> children = const [
    ParentChildSummary(userId: 11, studentId: 's-ana', name: 'Ana Pérez',
        classroomName: '3G X', classroomsCount: 1, year: '3',
        averageGrade: 7.9, attendanceRate: 95.0),
    ParentChildSummary(userId: 12, studentId: 's-bruno', name: 'Bruno Pérez'),
  ],
}) => DashboardData(role: 'parent', parentHome: ParentHomeData(
      overdueFeesCount: overdue, moraTotal: 1300000, children: children));

Future<void> _pumpHome(
  WidgetTester tester, {
  DashboardData? data,
  List<RelationModel> children = const [_ana, _bruno],
  bool relationsFail = false,
  bool dashboardFails = false,
  String parentName = 'María López',
  Brightness brightness = Brightness.light,
}) async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(_FakeParentAuthRepository(name: parentName)),
    dashboardRepositoryProvider.overrideWithValue(
        _FakeDashboardRepository(data: data ?? _parentData(), fails: dashboardFails)),
    relationsRepositoryProvider.overrideWithValue(
        _FakeRelationsRepository(children: children, fails: relationsFail)),
    unreadCountProvider.overrideWith((ref) async => 0),
  ]);
  addTearDown(container.dispose);

  final router = GoRouter(initialLocation: '/dashboard', routes: [
    GoRoute(path: '/dashboard', builder: (_, __) => const ParentHomeScreen()),
    GoRoute(path: '/students/:id', builder: (_, s) => Text('student:${s.pathParameters['id']}')),
    GoRoute(path: '/payments', builder: (_, __) => const Text('payments')),
    GoRoute(path: '/chat', builder: (_, __) => const Text('chat')),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('es', 'AR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
    ),
  ));
  await tester.pumpAndSettle();
}
```

Casos (nombre + aserciones):

1. `header shows Hola + Familia <apellido>` → `find.text('Hola')`, `find.text('Familia López')`, `find.byIcon(PhosphorIconsRegular.magnifyingGlass)` `findsNothing`.
2. `shows mora alert with count and total` → `find.text('2 cuotas vencidas')`, `find.text(r'Mora total $1.300.000,00')`; tap `'Pagar'` → `find.text('payments')`.
3. `hides the alert when there are no overdue fees` → `_parentData(overdue: 0)` → `find.text('Pagar')` `findsNothing`.
4. `renders one card per child with stats and dashes` → `'7.9'`, `'95%'`, `'3G X · 3° año'`, `find.text('—')` `findsNWidgets(2)` (Bruno sin datos).
5. `joins summaries by user id regardless of order` → `children: [_bruno, _ana]`:
   ```dart
   final anaCard = find.ancestor(of: find.text('Ana Pérez'), matching: find.byType(AppCard));
   expect(find.descendant(of: anaCard, matching: find.text('7.9')), findsOneWidget);
   ```
6. `degrades when no summary matches any child` → `data: DashboardData(role: 'parent', parentHome: const ParentHomeData())` → tarjetas con `'—'` ×2, sin subtítulo, `tester.takeException()` null.
7. `single-token parent name shows without Familia` → `parentName: 'Rocío'` → `find.text('Rocío')`, `find.textContaining('Familia')` `findsNothing`.
8. `relations error keeps the alert and shows bounded error` → `relationsFail: true` → `find.text('No se pudieron cargar los estudiantes')` y `find.text('Pagar')` `findsOneWidget`.
9. `empty children shows the neutral empty state` → `children: const []`, `data: _parentData(children: const [])` → `find.text('No se encontraron estudiantes')`.
10. `tapping a child navigates with the student id` → tap `'Ana Pérez'` → `find.text('student:s-ana')`.
11. `boletin with a single child navigates directly` → `children: [_ana]`; tap `'Boletín'` → `find.text('student:s-ana')`.
12. `boletin with two children asks which one` → tap `'Boletín'` → `find.text('Elegí un hijo')`; tap scopeado en la sheet: `await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Bruno Pérez')));` → `find.text('student:s-bruno')`.
13. `chat action opens the chat tab` → tap `'Chat'` → `find.text('chat')`.
14. `dashboard failure shows retry error` → `dashboardFails: true` → `find.byType(ErrorView)`.
15. `renders on a 320px screen without overflow` → `tester.view.physicalSize = Size(320*3, 568*3)`; drag ListView −400 y `takeException()` null.

`test/dashboard/dashboard_screen_test.dart` (reescritura):
- 1 test: `parent delegates to ParentHomeScreen` → `find.byType(ParentHomeScreen)`; `find.byType(HomeHeader)`; `find.byType(HeaderStatsRow)` `findsNothing`.
- 1 test dark mode: `Scaffold.backgroundColor == AppColors.darkBackground`.
- 1 test 320x568: `ParentHomeScreen` presente, `takeException()` null.
- Eliminar los tests de badge “Tutor”, `ParentChildrenSection` y `HeaderStatsRow` para padre.

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/dashboard/parent_home_screen_test.dart`
Expected: FAIL (pantalla no existe)

- [ ] **Step 3: Implementar `ParentHomeScreen`**

`ConsumerWidget` con: helper `_familyTitle(String name, AppLocalizations l10n)` (0 tokens → `commonUser`; 1 token → token; ≥2 → `l10n.parentFamilyTitle(último)`); helper `_summaryFor(List<ParentChildSummary>, int userId)` (loop, no `firstWhereOrNull`); `_studentRouteId(RelationModel, ParentHomeData?)` (`summary.studentId` si no vacío, si no `child.userId.toString()`); `_openBoletin(...)` con `showModalBottomSheet` (handle + título `parentChooseChild` + filas `AppAvatar` + nombre + `caretRight`, patrón `classroom_filter_sheet.dart`) y push; `_buildLoading` (shimmer estilo `ProfessorHomeScreen._buildLoading` con alerta + 2 tarjetas); y `_buildContent` con `RefreshIndicator` (refresca dashboard **y** relations) + `ListView`:

1. `HomeHeader(greeting: l10n.parentGreeting, title: _familyTitle(...), avatarUrl: user?.avatarUrl, unreadCount, onNotifications, onSearch: null)`.
2. `Padding(fromLTRB(16,14,16,0))` → `Column`: alerta si `overdueFeesCount > 0` (+ gap 14); bloque de hijos (relations: loading → 2 shimmers; error → `ErrorView(studentsLoadError, onRetry: relations.refresh)`; vacío → `EmptyState(users, studentsEmptyTitle)`; data → `ParentChildCard` por hijo con gap 11; tap → `context.push('/students/$id')`); gap 14; `ParentQuickActions(onFees/onBoletin/onChat)`; gap 24.

Error total de dashboard sin datos → `Scaffold` + `ErrorView(dashboardLoadError, retry)` (patrón profesor).

En `dashboard_screen.dart`: agregar `if (user?.role == 'parent') return const ParentHomeScreen();` (después de la rama profesor), eliminar la rama inline de padres (`ParentChildrenSection` + import + `parentSelectedStudentProvider` si queda sin uso) y conservar el resto igual.

- [ ] **Step 4: Eliminar el widget viejo**

```bash
git rm lib/features/dashboard/screens/widgets/parent_children_section.dart test/dashboard/parent_children_section_test.dart
```

- [ ] **Step 5: Correr y verificar**

Run: `flutter test test/dashboard/ && flutter analyze`
Expected: PASS (parent_home_screen_test + dashboard_screen_test + repository) y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(parent-home): pantalla de inicio de padres con mora, hijos y acciones"
```

---

### Task 9: Router — pestaña “Pagos” por rol

**Files:**
- Modify: `lib/app/router.dart` (branch 1 + `CustomBottomNav`)
- Modify: `test/app/bottom_nav_test.dart`

**Interfaces:**
- Consumes: `FeeListScreen` (existente), `navPayments` (T2), `ParentHomeScreen` (T8) vía dashboard.
- Produces: ruta `/payments` en el branch 1 y 2ª pestaña con label/icono por rol (`go_router 14.8.1` soporta `StatefulShellBranch.initialLocation` — verificarlo en el archivo instalado si hay dudas).

- [ ] **Step 1: Escribir/actualizar los tests que fallan**

En `test/app/bottom_nav_test.dart`: el `_pumpApp` suma el override para que `FeeListScreen` no toque red —

```dart
feeListProvider.overrideWith((ref) => FeeListNotifier(_FakeFeeRepository())),
```

con `_FakeFeeRepository implements FeeRepository` devolviendo `CursorPagination.empty()` en `getFees` y `UnimplementedError` en el resto. Tests nuevos:

```dart
testWidgets('parent nav shows Pagos and opens the fee list', (tester) async {
  await _pumpApp(tester, 'parent');
  expect(navLabel('Pagos'), findsOneWidget);
  expect(navLabel('Aulas'), findsNothing);
  await tester.tap(navLabel('Pagos'));
  await tester.pumpAndSettle();
  expect(find.byType(FeeListScreen), findsOneWidget);
});

testWidgets('professor nav keeps Aulas', (tester) async {
  await _pumpApp(tester, 'professor');
  expect(navLabel('Aulas'), findsOneWidget);
  expect(navLabel('Pagos'), findsNothing);
});
```

(El test existente de rol `student` sigue igual: Inicio/Aulas/Chat/Perfil.)

- [ ] **Step 2: Correr y verificar que fallan**

Run: `flutter test test/app/bottom_nav_test.dart`
Expected: FAIL (`Pagos` no existe)

- [ ] **Step 3: Implementar en `lib/app/router.dart`**

En `routerProvider`: `final isParent = authState.user?.role == 'parent';` y en el branch 1:

```dart
StatefulShellBranch(
  initialLocation: isParent ? '/payments' : null,
  routes: [
    // …la ruta '/classrooms' existente, sin cambios…
    GoRoute(
      path: '/payments',
      builder: (context, state) => const FeeListScreen(),
    ),
  ],
),
```

En `CustomBottomNav`: `final isParent = ref.watch(authProvider).user?.role == 'parent';` y el `_NavItem` de índice 1 con `icon: isParent ? PhosphorIconsRegular.wallet : PhosphorIconsRegular.chalkboardTeacher`, `selectedIcon: …Fill.wallet / …Fill.chalkboardTeacher`, `label: isParent ? l10n.navPayments : l10n.navClasses`. `/fees` y `/fees/:id` quedan intactos.

- [ ] **Step 4: Correr y verificar**

Run: `flutter test test/app/bottom_nav_test.dart && flutter analyze`
Expected: PASS y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart test/app/bottom_nav_test.dart
git commit -m "feat(nav): pestana Pagos para padres en la barra inferior"
```

---

### Task 10: Ficha del hijo — sección “Aulas”

**Files:**
- Modify: `lib/features/students/data/student_api.dart`
- Modify: `lib/features/students/data/student_repository.dart`
- Modify: `lib/features/students/providers/student_provider.dart`
- Create: `lib/features/students/screens/widgets/student_classrooms_section.dart`
- Modify: `lib/features/students/screens/widgets/student_info_tab.dart`
- Modify (fakes que implementan `StudentRepository`): `test/students/student_detail_screen_test.dart`, `test/students/student_list_screen_test.dart`, `test/students/student_list_notifier_test.dart`
- Test: `test/students/student_classrooms_section_test.dart`

**Interfaces:**
- Consumes: `GET /students/{id}/classrooms` (existente; responde `{data: [classroom…]}`), `ClassroomModel.fromJson` (soporta map crudo).
- Produces: `StudentApi.getClassrooms(String studentId)`, `StudentRepository.getClassrooms(String studentId) → Future<List<ClassroomModel>>`, `studentClassroomsProvider` (family por studentId), `StudentClassroomsSection({required String studentId})`.

- [ ] **Step 1: Escribir el test que falla**

`test/students/student_classrooms_section_test.dart` (fakes propios; `_FakeStudentRepository` con `classrooms`, `fails` y los métodos existentes; pump con GoRouter dummy `/classrooms/:id` → `Text('classroom:${id}')`):

```dart
testWidgets('lists classrooms and navigates to detail', (tester) async {
  await _pumpSection(
    tester,
    classrooms: const [ClassroomModel(id: 'c1', name: '3G X')],
  );
  expect(find.text('Aulas'), findsOneWidget);
  expect(find.text('3G X'), findsOneWidget);
  await tester.tap(find.text('3G X'));
  await tester.pumpAndSettle();
  expect(find.text('classroom:c1'), findsOneWidget);
});

// 2) vacío: classrooms: [] → find.text('Aulas') findsNothing
// 3) error: fails: true → find.byType(ErrorView) y al tocar reintentar no crashea
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/students/student_classrooms_section_test.dart`
Expected: FAIL (sección no existe)

- [ ] **Step 3: Implementar API + repo + provider**

```dart
// student_api.dart
Future<Response> getClassrooms(String studentId) =>
    _client.get('/students/$studentId/classrooms');

// student_repository.dart
Future<List<ClassroomModel>> getClassrooms(String studentId) async {
  try {
    final response = await _api.getClassrooms(studentId);
    final data = response.data['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ClassroomModel.fromJson)
        .toList();
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

// student_provider.dart
final studentClassroomsProvider =
    FutureProvider.family<List<ClassroomModel>, String>((ref, studentId) {
  return ref.watch(studentRepositoryProvider).getClassrooms(studentId);
});
```

- [ ] **Step 4: Implementar la sección y montarla en la ficha**

`StudentClassroomsSection` (`ConsumerWidget`): `ref.watch(studentClassroomsProvider(studentId)).when(...)` → loading: `SectionHeader(classroomsTitle)` + 2 `LoadingShimmer` (height 56, radius 16); error: header + `ErrorView(message: l10n.classroomsLoadError, detail, onRetry: () => ref.invalidate(studentClassroomsProvider(studentId)))`; data vacío → `SizedBox.shrink()`; data: header + `AppCard` por aula (nombre 14/w800 `inkFor` + `caretRight` 18 `primary`, `onTap: () => context.push('/classrooms/${classroom.id}')`, gap 11; patrón `_ParentClassroomCard`).

En `StudentInfoTab`: convertir a `ConsumerWidget` y agregar, después de la card institucional, `const SizedBox(height: 20), StudentClassroomsSection(studentId: student.id)`.

- [ ] **Step 5: Actualizar los fakes de `StudentRepository`**

En los 3 test files, agregar `@override Future<List<ClassroomModel>> getClassrooms(String id) async => const [];` (import de `classroom_model.dart`). Con eso los tests existentes de la ficha (incluida la tab Info) siguen verdes: la sección queda oculta.

- [ ] **Step 6: Correr y verificar**

Run: `flutter test test/students/ && flutter analyze`
Expected: PASS y `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/students/ test/students/
git commit -m "feat(students): aulas del alumno en la ficha (acceso de padres)"
```

---

## Cierre

- [ ] **Verificación final (móvil):** `flutter gen-l10n && flutter analyze && flutter test` → todo verde.
- [ ] **Verificación final (backend):** `php -l` + `pint --test` + tinker de Task 1 (sin Pest).
- [ ] **Regresión manual sugerida:** cuenta padre en el emulador (`/dashboard` → alerta, hijos, acciones; pestaña Pagos; ficha → Notas y Aulas), cuenta profesor (`Aulas` intacta), claro y oscuro.
