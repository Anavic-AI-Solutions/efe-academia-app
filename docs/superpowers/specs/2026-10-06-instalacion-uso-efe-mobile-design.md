# Guía de instalación y uso de EFE Mobile — Diseño

**Fecha:** 2026-10-06
**Estado:** aprobado (brainstorming en sesión)

## Objetivo

Publicar una guía paso a paso, en español, para que una persona instale EFE
Mobile desde GitHub (Windows de escritorio y Android) y llegue a ver la
interfaz con la sesión iniciada contra el backend de preprod. Además, dejar
un skill para agentes que permita ejecutar o guiar ese mismo proceso.

## Decisiones aprobadas

| Tema | Decisión |
|------|----------|
| Programa | EFE Mobile (Flutter) |
| Plataformas de la guía | Windows (ZIP de escritorio) y Android (APK) |
| Backend | Preprod: `https://preprod.efeacademia.com/api/v1` |
| Credenciales | Placeholders `[EMAIL]` / `[CONTRASEÑA]`; se pide cuenta al equipo |
| APK | Se compila en CI y se publica en el release de GitHub |
| Entregables | Guía humana en el repo + skill para agentes |
| Capturas | Sí, las que se puedan generar (Android con emulador) |
| Merge | A `master` al final (dispara el release) |

## Entregables

1. `docs/GUIA_INSTALACION_Y_USO.md` — guía humana súper detallada (ES).
2. `docs/images/guia/*.png` — capturas reales (Android; lo que se pueda).
3. `.agents/skills/efe-mobile-instalar-y-usar/SKILL.md` — skill para agentes,
   enlazado también en `/root/.agents/skills/`.
4. `.github/workflows/build.yml` — job Android + `.env` de preprod en todos
   los builds + arreglo del tag + APK adjunto al release.
5. `lib/core/config/env_helper.dart` — robustez y defaults desde el build.
6. `README.md` — sección que enlaza la guía.
7. Release `v1.0.1` con `efe-mobile-linux-x86_64.tar.gz`,
   `efe-mobile-windows-x64.zip` y `efe-mobile-android.apk`.

## Diseño técnico

### 1. `EnvHelper`

Problema actual: si no existe `.env` junto al ejecutable, escribe siempre
`localhost:8000` (ignora el valor con el que se compiló); y si el directorio
del ejecutable no es escribible (posible en Android), puede fallar al iniciar.

Cambios:

- `buildDefaultEnvContent(Map<String, String> buildValues)`: genera el
  contenido del `.env` que se crea, usando `API_BASE_URL` del build (asset
  embebido por CI) y `localhost:8000/api/v1` como fallback; copia las claves
  `REVERB_*` presentes y no vacías.
- `parseEnvContent(String content)`: parseo puro del archivo (soporta CRLF,
  comentarios, líneas vacías, `=` dentro del valor).
- `load()`: envuelve toda la operatoria de archivo en `try/catch`; si algo
  falla, quedan los valores del asset. Los devs no notan cambios (el `.env`
  del repo sigue apuntando a localhost).

### 2. CI (`build.yml`)

- Variable de workflow `PREPROD_API_BASE_URL=https://preprod.efeacademia.com/api/v1`.
- Cada job escribe (overwrite) `.env` antes de compilar:
  `API_BASE_URL` de preprod; `REVERB_HOST=preprod.efeacademia.com`,
  `REVERB_PORT=8181`, `REVERB_SCHEME=https`, `REVERB_APP_KEY=` (vacío: el chat
  en vivo queda fuera de alcance, el REST sigue funcionando).
- Job `build-android`: Java 17 + Flutter 3.24, `flutter build apk --release`,
  artefacto `efe-mobile-android.apk`.
- Job `release`: descarga los 3 artefactos y adjunta los 3 al release.
- Arreglo del tag: hoy publica `EFE Mobile v` (tag `v`) porque el extractor no
  limpia `+1`; pasa a `v1.0.1` (se sube `pubspec.yaml` a `1.0.1+2`).

### 3. Guía humana (esquema)

1. Qué es EFE Mobile; requisitos (Windows 10+ 64 bits / Android 5+).
2. Acceso a GitHub: repo privado → cuenta con acceso o pedir los archivos.
3. Windows: descargar ZIP → extraer → abrir `efe_mobile.exe` (aviso de
   SmartScreen y cómo continuar) → login → pantalla de inicio.
4. Android: descargar APK → permitir apps desconocidas → instalar → login →
   pantalla de inicio.
5. Login: placeholders + cómo pedir una cuenta; qué se ve al entrar.
6. Sesión persistente y cómo cerrar sesión.
7. Problemas comunes (sin conexión, credenciales, antivirus, bloqueo de
   instalación).
8. FAQ + glosario.

### 4. Skill

- Nombre: `efe-mobile-instalar-y-usar`; description “Use when…” (disparadores,
  sin resumir el flujo).
- Contenido: decisión ejecutar vs guiar, pasos por plataforma, checklist de
  verificación que termina en “pantalla de inicio visible”, pitfalls
  (SmartScreen, APK desconocido, repo privado) y referencia a la guía.
- Proceso writing-skills: baseline con subagente sin el skill (RED), escritura
  (GREEN), ajuste de huecos (REFACTOR).

## Verificación

1. `flutter analyze` + `flutter test` (incluye tests nuevos de env).
2. Build local del APK con `.env` de preprod y control del asset embebido.
3. Emulador Android: instalar el APK, abrir, llegar al login sin crash;
   capturas reales.
4. CI: `workflow_dispatch` en la rama para validar los 3 builds; luego merge a
   `master` → release → verificar assets con `gh`.
5. Guía: recorrer el flujo Android en el emulador; Windows se revisa de forma
   estática (no hay Windows en este entorno).

## Fuera de alcance

- Chat en vivo (Reverb) configurado para preprod.
- Firma de release de Android con keystore propia (se mantiene la firma debug;
  alcanza para sideload).
- Capturas reales de Windows.
- Publicación en Play Store.
