# Guía de instalación y uso de EFE Mobile — Implementation Plan

> **Ajuste posterior (2026-10-06):** el usuario decidió descartar todo lo del
> APK. Queda vigente: Task 1 (EnvHelper) ✅, Task 2 sin el job `build-android`
> (solo desktop + tag limpio), **Task 3 cancelada** (emulador/capturas), Task 4
> guía **solo Windows** (sin capturas), Task 5 skill **solo Windows**, Task 6
> merge/release con 2 artefactos. Ver spec para el detalle.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publicar guía humana + skill de agente para instalar EFE Mobile (Windows/Android) desde los releases de GitHub y llegar a la interfaz logueada contra preprod, con el APK publicado en el release.

**Architecture:** CI compila Windows/Linux/Android con `.env` de preprod embebido (asset de Flutter) y publica los 3 binarios en un release con tag limpio. `EnvHelper` se vuelve robusto: el `.env` que crea junto al ejecutable hereda el valor del build y nunca rompe el arranque si no se puede escribir. La guía documenta el flujo de extremo a extremo; el skill permite a un agente ejecutarlo o guiarlo. Capturas reales de Android vía emulador contra un backend demo local.

**Tech Stack:** GitHub Actions (ubuntu-latest, windows-2022), Flutter 3.24.x/Dart 3.5, Java 17 (builds Android), Android emulador (system-image android-34, x86_64, KVM), backend Laravel demo local (SQLite) solo para capturas, Markdown + PNG.

**Spec:** `docs/superpowers/specs/2026-10-06-instalacion-uso-efe-mobile-design.md`

## Global Constraints

- `API_BASE_URL` de los builds publicados: `https://preprod.efeacademia.com/api/v1`.
- `.env` de release en CI (sobrescribe el trackeado, por job, antes de compilar):
  `API_BASE_URL=https://preprod.efeacademia.com/api/v1`,
  `REVERB_HOST=preprod.efeacademia.com`, `REVERB_PORT=8181`,
  `REVERB_SCHEME=https`, `REVERB_APP_KEY=` (vacío). El `.env` del repo no se
  toca (sigue apuntando a localhost para desarrollo).
- Versión nueva: `pubspec.yaml` → `1.0.1+2` (tag release `v1.0.1`).
- El tag se extrae con `cut -d'+' -f1` (nunca puede quedar vacío; si lo estuviera, el job falla explícitamente).
- Los 3 artefactos del release: `efe-mobile-linux-x86_64.tar.gz`,
  `efe-mobile-windows-x64.zip`, `efe-mobile-android.apk`.
- Guía en español, en `docs/GUIA_INSTALACION_Y_USO.md`, con capturas en
  `docs/images/guia/` y credenciales placeholder (`[EMAIL]` / `[CONTRASEÑA]`).
- Skill en `.agents/skills/efe-mobile-instalar-y-usar/SKILL.md` + symlink
  `/root/.agents/skills/efe-mobile-instalar-y-usar` → el del repo.
- No se publican credenciales reales en ningún archivo del repo.

## Review Focus

1. Arranque en Windows con carpeta de instalación no escribible (p.ej. `Program Files`): la app debe abrir igual (sin `.env` en filesystem usa el valor del build). — Task 1 (try/catch) y Task 3/6 (verificación en CI).
2. Arranque en Android con directorio del ejecutable de solo lectura: no debe crashear. — Task 1 (try/catch) y Task 3 (emulador: llega al login).
3. `.env` con CRLF, comentarios, espacios y `=` dentro del valor: se parsea igual. — Task 1 (tests).
4. Persona sin acceso al repo privado de GitHub: la guía da la alternativa de pedir los archivos al equipo (no puede quedarse sin salida). — Task 4 (sección "Acceso").
5. Versión mal formada/ausente en el CI: el paso de versión falla ruidoso en vez de publicar un tag vacío como hoy. — Task 2 (paso de versión con guard) y Task 6 (dispatch → release v1.0.1).

---

### Task 1: `EnvHelper` robusto con defaults del build

**Files:**
- Modify: `lib/core/config/env_helper.dart`
- Test: `test/core/config/env_helper_test.dart` (crear)

**Interfaces:**
- Consumes: `Platform.resolvedExecutable` (dart:io), `dotenv` (flutter_dotenv), `p` (path).
- Produces:
  - `static String buildDefaultEnvContent(Map<String, String> buildValues)` → contenido del `.env` a crear (usa `API_BASE_URL` de buildValues si no está vacío, si no `http://localhost:8000/api/v1`; agrega líneas `REVERB_*` presentes y no vacías).
  - `static Map<String, String> parseEnvContent(String content)` → pares del archivo (CRLF OK, ignora blanks y `#`, corta en el primer `=`, recorta espacios, valores pueden contener `=`).
  - `static Future<void> load()` → igual que hoy, pero: crea el archivo con `buildDefaultEnvContent(dotenv.env)` cuando falta y aplica `parseEnvContent`; **todo** el acceso a archivo envuelto en `try/catch` (si falla, imprime `[ENV] No se pudo usar el .env del filesystem: <e>` y continúa con los valores del asset).

- [ ] **Step 1: Write the failing test** — crear `test/core/config/env_helper_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:efe_mobile/core/config/env_helper.dart';

void main() {
  group('buildDefaultEnvContent', () {
    test('usa API_BASE_URL del build', () {
      final out = EnvHelper.buildDefaultEnvContent({
        'API_BASE_URL': 'https://preprod.efeacademia.com/api/v1',
        'REVERB_HOST': 'x', 'REVERB_APP_KEY': '',
      });
      expect(out, contains('API_BASE_URL=https://preprod.efeacademia.com/api/v1'));
      expect(out, contains('REVERB_HOST=x'));
      expect(out, isNot(contains('REVERB_APP_KEY')));
    });
    test('cae a localhost si API_BASE_URL falta o está vacía', () {
      expect(EnvHelper.buildDefaultEnvContent({}), contains('API_BASE_URL=http://localhost:8000/api/v1'));
      expect(EnvHelper.buildDefaultEnvContent({'API_BASE_URL': ''}), contains('http://localhost:8000'));
    });
  });
  group('parseEnvContent', () {
    test('parsea pares y tolera CRLF', () {
      expect(EnvHelper.parseEnvContent('A=1\r\nB=2\r\n'), {'A': '1', 'B': '2'});
    });
    test('ignora comentarios, líneas vacías y recorta espacios', () {
      expect(EnvHelper.parseEnvContent('# c\n\nA = x \nB=2 '), {'A': 'x', 'B': '2'});
    });
    test('valores con = y líneas sin = se descartan', () {
      expect(EnvHelper.parseEnvContent('A=x=y\nmal'), {'A': 'x=y'});
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/opt/flutter/bin/flutter test test/core/config/env_helper_test.dart`
Expected: FAIL (compila error: `buildDefaultEnvContent` / `parseEnvContent` no existen).

- [ ] **Step 3: Implement en `lib/core/config/env_helper.dart`**

Agregar `buildDefaultEnvContent` y `parseEnvContent` como `static`, y reescribir `load()` según Interfaces (crear con default del build, aplicar parse, try/catch alrededor de `_envFileNextToExecutable`, `existsSync/writeAsStringSync/readAsStringSync`; el `print` de `[ENV] API_BASE_URL:` se conserva al final). Mantener el estilo actual (prints en inglés, `// ignore: avoid_print`).

- [ ] **Step 4: Run test to verify it passes**

Run: `/opt/flutter/bin/flutter test test/core/config/env_helper_test.dart`
Expected: PASS (3 tests). Luego `/opt/flutter/bin/flutter analyze` → sin issues nuevos.

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/env_helper.dart test/core/config/env_helper_test.dart
git commit -m "fix(env): .env con defaults del build y arranque tolerante a fallos de filesystem"
```

---

### Task 2: Versión `1.0.1+2` + workflow con APK y tag limpio

**Files:**
- Modify: `pubspec.yaml` (línea `version:`)
- Modify: `.github/workflows/build.yml`

**Interfaces:**
- Consumes: nada de Task 1.
- Produces: artefactos de release `efe-mobile-linux-x86_64.tar.gz`, `efe-mobile-windows-x64.zip`, `efe-mobile-android.apk`; tag `v1.0.1`.

- [ ] **Step 1: Bump version**

`pubspec.yaml`: `version: 1.0.1+2`.

- [ ] **Step 2: Escribir el `.env` de preprod en cada job de build**

En `build-linux`, `build-windows` (con `shell: bash`, runner Windows incluye git-bash) y el nuevo `build-android`, después de `actions/checkout@v4`:

```yaml
- name: Configure app (preprod)
  shell: bash
  run: |
    cat > .env <<'EOF'
    API_BASE_URL=https://preprod.efeacademia.com/api/v1
    REVERB_HOST=preprod.efeacademia.com
    REVERB_PORT=8181
    REVERB_APP_KEY=
    REVERB_SCHEME=https
    EOF
```

- [ ] **Step 3: Job `build-android`**

```yaml
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
      # (paso "Configure app (preprod)" igual al Step 2)
      - name: Accept Android licenses
        run: yes | flutter doctor --android-licenses
      - name: Install dependencies
        run: flutter pub get
      - name: Build APK
        run: flutter build apk --release
      - name: Package
        run: cp build/app/outputs/flutter-apk/app-release.apk efe-mobile-android.apk
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: android
          path: efe-mobile-android.apk
```

- [ ] **Step 4: Job `release` — 3 artefactos y tag limpio**

- `needs: [build-linux, build-windows, build-android]`.
- Agregar download del artifact `android` a `./artifacts`.
- Reemplazar el paso "Get version" por:

```yaml
      - name: Get version
        id: version
        shell: bash
        run: |
          VERSION=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
          if [ -z "$VERSION" ]; then echo "VERSION vacía"; exit 1; fi
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
```

- `files:` incluir también `artifacts/efe-mobile-android.apk`.

- [ ] **Step 5: Validar YAML + commit**

Run: `python3 -c "import yaml,sys; list(yaml.safe_load_all(open('.github/workflows/build.yml'))); print('yaml ok')"` — si no está `pyyaml`, validar con `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/build.yml'); puts 'yaml ok'"` o `docker run --rm -v $(pwd):/w mikefarah/yq eval '.name' /w/.github/workflows/build.yml`.
Expected: parsea sin error.
Luego:

```bash
git add pubspec.yaml .github/workflows/build.yml
git commit -m "ci(release): build de APK, .env de preprod y tag de versión limpio"
git push -u origin feat/instalacion-uso-efe-mobile
```

- [ ] **Step 6: Disparar el workflow en la rama**

Run: `gh workflow run build.yml --ref feat/instalacion-uso-efe-mobile` y luego `gh run watch` (hasta que terminen los 3 jobs de build; el job `release` queda skip porque `github.ref != master`).
Expected: los 3 jobs `build-linux`, `build-windows`, `build-android` en verde (el job build-android correrá la nueva compilación de APK; si falla por licencias/Java, arreglar en este task y re-despachar).

---

### Task 3: Emulador Android + APK de capturas + capturas PNG

**Files:**
- Create: `docs/images/guia/android-01-login.png`, `docs/images/guia/android-02-inicio.png`, `docs/images/guia/android-03-perfil.png` (los nombres finales según lo que se pueda capturar)
- Modify temporal (NO commitear): `.env` para un build de capturas.

**Interfaces:**
- Consumes: backend demo local en `http://127.0.0.1:8055` (levantado en sesión), user `demo@maqueta.local` / `demo123`, `adb` y emulador.
- Produces: PNGs reales de login, inicio (logueado) y perfil para la guía.

- [ ] **Step 1: Instalar emulador + system image**

Run:
```bash
yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses
/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager "emulator" "platform-tools" "system-images;android-34;google_apis;x86_64"
echo no | /opt/android-sdk/cmdline-tools/latest/bin/avdmanager create avd -n capturas -k "system-images;android-34;google_apis;x86_64" -d pixel_7
```
Expected: AVD `capturas` creada (el download puede tardar varios minutos).

- [ ] **Step 2: Bootear emulador headless**

Run: `/opt/android-sdk/emulator/emulator -avd capturas -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &` y esperar `adb wait-for-device` + `adb shell getprop sys.boot_completed` == 1 (poll hasta ~5 min).
Expected: device `emulator-5554` online.

- [ ] **Step 3: Build del APK de capturas (localhost:8055)**

Temporalmente `.env` con `API_BASE_URL=http://localhost:8055/api/v1` (y REVERB_* vacíos), luego:
```bash
/opt/flutter/bin/flutter build apk --release
git checkout -- .env   # restaurar el .env del repo
```
Expected: `build/app/outputs/flutter-apk/app-release.apk` existe y el asset `assets/flutter_assets/.env` dentro del APK contiene `http://localhost:8055`.

- [ ] **Step 4: Instalar, abrir y capturar el login**

```bash
adb reverse tcp:8055 tcp:8055
adb install build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.efe.efe_mobile/.MainActivity
# esperar render (10-15 s)
adb exec-out screencap -p > docs/images/guia/android-01-login.png
```
Expected: PNG con la pantalla de login (logo EFE, email, contraseña, botón Iniciar sesión). El app NO debe crashear al arrancar (valida Review Focus 2).

- [ ] **Step 5: Loguearse y capturar inicio + perfil**

Con `adb shell input text` / `input tap` (dimensiones del Pixel 7: 1080x2400) escribir `demo@maqueta.local` y `demo123`, tocar "Iniciar sesión"; esperar carga; capturar `android-02-inicio.png`. Ir a Perfil (barra inferior, 4º item) y capturar `android-03-perfil.png`. También capturar lo que muestre el home (stats).
Expected: home con datos del backend demo (73 alumnos, cuotas, etc.) y perfil con "Demo Admin".

- [ ] **Step 6: Commit**

```bash
git add docs/images/guia/
git commit -m "docs(guia): capturas reales de Android (login, inicio, perfil)"
```

---

### Task 4: Guía humana + README

**Files:**
- Create: `docs/GUIA_INSTALACION_Y_USO.md`
- Modify: `README.md` (sección que enlaza la guía, al tope después del intro o en "Instalación")

**Interfaces:**
- Consumes: capturas de Task 3; datos de Task 1/2 (nombres de artefactos, URL preprod, versión v1.0.1).
- Produces: documento navegable en Markdown con imágenes referenciadas por ruta relativa.

- [ ] **Step 1: Escribir `docs/GUIA_INSTALACION_Y_USO.md`**

Secciones (español, tono simple, pasos numerados):
1. Qué es EFE Mobile + requisitos (Windows 10+ 64 bits, Android 5+).
2. Acceso (repo privado: github.com/Anavic-AI-Solutions/efe-academia-app → Releases; si no hay cuenta con acceso, pedir al equipo el ZIP/APK).
3. Windows: descargar `efe-mobile-windows-x64.zip` → extraer (carpeta, p.ej. `C:\EFE`) → doble clic `efe_mobile.exe` → SmartScreen ("Más información" → "Ejecutar de todas formas") → login → inicio. Nota: la app crea un `.env` junto al exe con el servidor configurado; cómo cambiarlo si se necesita (Notepad, línea `API_BASE_URL=`), y reiniciar la app.
4. Android: descargar `efe-mobile-android.apk` → permitir "Instalar apps desconocidas" (pasos por versión: Ajustes → Seguridad/Apps → Permitir de esta fuente) → Abrir → login → inicio. Capturas 01–03 insertadas con `![...](images/guia/android-01-login.png)` etc.
5. Iniciar sesión: campos `[EMAIL]` y `[CONTRASEÑA]` (cómo pedir cuenta al equipo); qué se ve al entrar (Inicio con estadísticas; Aulas; Chat; Perfil; Noticias; Calificaciones según rol).
6. Sesión: la app recuerda la sesión (se abre directo); cerrar sesión en Perfil; olvidé mi contraseña (enlace en el login).
7. Problemas comunes (tabla: no conecta al servidor → revisar internet/WiFi y que el servidor sea el correcto; credenciales inválidas → pedir soporte; Windows Defender/SmartScreen; Android "no se puede abrir el archivo" → permisos de instalación; app se ve en blanco → cerrar y reabrir).
8. Preguntas frecuentes + glosario (APK, release, .env).
9. Pie: versión de la guía y enlace al repo.

- [ ] **Step 2: README**

Agregar tras el párrafo introductorio: "## Guía de instalación y uso (usuarios) — [docs/GUIA_INSTALACION_Y_USO.md](docs/GUIA_INSTALACION_Y_USO.md)". Mantener el resto.

- [ ] **Step 3: Verificar render + links**

Run: revisar que todas las imágenes referenciadas existen (`ls docs/images/guia/`), y abrir la guía con `tools.browser.preview` para confirmar que renderiza.
Expected: documento renderiza, imágenes aparecen.

- [ ] **Step 4: Commit**

```bash
git add docs/GUIA_INSTALACION_Y_USO.md README.md
git commit -m "docs(guia): instrucciones de instalación y uso para Windows y Android"
```

---

### Task 5: Skill `efe-mobile-instalar-y-usar` (writing-skills: RED → GREEN → REFACTOR)

**Files:**
- Create: `.agents/skills/efe-mobile-instalar-y-usar/SKILL.md`
- Create (symlink, fuera de git): `/root/.agents/skills/efe-mobile-instalar-y-usar` → `.agents/skills/efe-mobile-instalar-y-usar` del repo.

**Interfaces:**
- Consumes: guía de Task 4 (referencia), URL de release, credenciales placeholder, herramientas del agente (shell, adb, browser).
- Produces: skill cargable por OpenCode con frontmatter `name`/`description`.

- [ ] **Step 1 (RED): Baseline con subagente** — despachar `subagent` (agent: general) SIN el skill: "Un usuario quiere instalar la app EFE Mobile (escritorio Windows o Android APK) desde GitHub y ver la interfaz logueada contra el backend de preprod. El repo es privado y las credenciales son del equipo. ¿Qué pasos darías / qué le dirías?" Registrar huecos (ej.: no conocer el release, no explicar SmartScreen/permitir apps desconocidas, no manejar `.env`, no pedir credenciales al equipo).

- [ ] **Step 2 (GREEN): Escribir `SKILL.md`** — frontmatter:

```yaml
---
name: efe-mobile-instalar-y-usar
description: Use when a user needs to install, launch, or reach the logged-in screen of EFE Mobile (Windows desktop ZIP or Android APK) from the GitHub release, or when asked for support/help with downloading, installing, logging in, or configuring the app's API server. Triggers include "descargar la app", "instalar EFE", "cómo entro a la app", "no me loguea", and demo/setup requests for EFE Mobile.
---
```

Contenido: cuándo ejecutar vs cuándo guiar (mapeo de plataforma: máquina del agente con Android tooling → ejecutar con adb/emulador; usuario final → guiar); pasos por plataforma (resumen rápido con referencia a `docs/GUIA_INSTALACION_Y_USO.md` del repo); checklist de verificación que TERMINA en "pantalla de inicio visible" (no en "se instaló"); pitfalls (repo privado → pedir acceso o los archivos; SmartScreen; Android "instalar apps desconocidas"; `.env` junto al exe con `API_BASE_URL`; Windows Notepad no crea `.env` desde cero: usar "Guardar como" tipo "Todos los archivos"); no inventar credenciales: usar placeholders y pedir la cuenta al equipo; no publicar credenciales en el repo. Máx ~500 palabras, reference-style.

- [ ] **Step 3 (GREEN): Test con subagente** — despachar `subagent` con el skill presente (incluir el contenido del skill en el prompt y decirle que lo siga) con el mismo escenario del Step 1 + un caso de ejecución ("instalá el APK en un emulador y confirmá que llega al login"). Expected: sigue los pasos del skill, no inventa credenciales, verifica la pantalla de inicio.
- [ ] **Step 4 (REFACTOR):** por cada hueco que aparezca en Step 3, agregar línea al skill y re-testear (1 iteración como mínimo).
- [ ] **Step 5: Symlink global + commit**

```bash
ln -sfn /opt/dev/efe_mobile/.worktrees/instalacion-uso/.agents/skills/efe-mobile-instalar-y-usar /root/.agents/skills/efe-mobile-instalar-y-usar
git add .agents/skills/efe-mobile-instalar-y-usar/SKILL.md
git commit -m "skills: skill efe-mobile-instalar-y-usar (instalar, abrir y llegar logueado)"
```

---

### Task 6: CI verde, merge a master y verificación del release

**Files:** ninguno (solo git + gh).

- [ ] **Step 1: Suite completa local**

Run: `/opt/flutter/bin/flutter analyze && /opt/flutter/bin/flutter test`
Expected: analyze limpio; tests: 303+5 (los 3-4 nuevos de env) pasan, solo el flaky conocido de `professor_home_screen_test.dart` puede fallar (documentado en README).

- [ ] **Step 2: Merge a master y release**

```bash
git checkout master
git pull origin master
git merge --no-ff feat/instalacion-uso-efe-mobile
git push origin master          # dispara build.yml; release job publica v1.0.1
```
Expected: workflow en master corre; job `release` crea release `EFE Mobile v1.0.1` con los 3 assets (tag `v1.0.1`).

- [ ] **Step 3: Verificar release**

Run: `gh release view v1.0.1 -R Anavic-AI-Solutions/efe-academia-app --json tagName,assets`
Expected: tag `v1.0.1`, assets linux/windows/android. Descargar el APK y verificar que `assets/flutter_assets/.env` contiene `https://preprod.efeacademia.com/api/v1` (unzip -p).

- [ ] **Step 4: Revisión final de rama** — despachar `subagent` reviewer (agent: general) sobre el diff de la rama vs master (`git diff master...feat/...`), foco: guía correcta y sin credenciales, skill alineado, workflow válido, EnvHelper sin regresiones.
Expected: sin hallazgos bloqueantes (o arreglarlos y re-pushear).

- [ ] **Step 5: Avisar al usuario** con resumen: release v1.0.1, dónde quedó la guía, el skill, y cómo se probó.

---

## Notas de entorno para el implementador

- Flutter: `/opt/flutter/bin/flutter` (no está en PATH). Android SDK: `/opt/android-sdk`.
- Backend de capturas (ya validado en sesión): `php -d variables_order=EGPCS -S 127.0.0.1:8055 -t public public/index.php` en `/opt/dev/efe-demo-tour` con `APP_ENV=demo` y `DB_DATABASE=/tmp/opencode/demo-screens.sqlite` (fresca, migrada y sembrada). Usuario: `demo@maqueta.local` / `demo123`.
- El `.env` está trackeado en git: cualquier build local lo usa como asset; restaurar con `git checkout -- .env` después de builds de capturas.
- El release viejo con tag `v` (roto) NO se toca en este plan.