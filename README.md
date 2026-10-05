# EFE Mobile — Educational ERP for Nursing Schools

Aplicación móvil Flutter para la gestión integral de escuelas de enfermería: asistencia, calificaciones, aulas, estudiantes, chat, noticias, eventos, notificaciones y cuotas.

## Características principales

- **Asistencia**: Registro diario por aula con estados presente/ausente
- **Calificaciones**: Grid de notas por alumno y período con promedios
- **Aulas**: Listado, detalle, profesores, materiales y filtros
- **Estudiantes**: Ficha completa, historial de asistencia, calificaciones y cuotas
- **Chat**: Mensajería entre roles con notificaciones push
- **Noticias/Eventos/Notificaciones**: Feed unificado con shimmer loading
- **Cuotas**: Listado y detalle de pagos pendientes
- **Perfil**: Configuración de tema (claro/oscuro/sistema), idioma, logout
- **Tema unificado**: Sistema visual azul coherente en todas las pantallas (claro/oscuro)

## Requisitos previos

| Herramienta | Versión mínima |
|-------------|----------------|
| Flutter SDK | 3.24.x (stable) |
| Dart SDK | 3.5.x |
| Android Studio / Xcode | Para emuladores/dispositivos |
| Git | 2.x |

## Instalación

### 1. Clonar el repositorio

```bash
git clone git@github.com:Anavic-AI-Solutions/efe-academia-app.git
cd efe-academia-app
```

### 2. Configurar variables de entorno

Crea `.env` en la raíz (copia de `.env.example`):

```bash
cp .env.example .env
# Edita .env con tus valores:
# API_BASE_URL=https://tu-api.ejemplo.com/api/v1
# Otras keys según necesidad
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Generar código (Freezed/JSON Serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Ejecutar

#### Desarrollo (hot reload)

```bash
# Android / iOS / Web / Linux / macOS / Windows
flutter run -d <device_id>

# Ejemplos:
flutter run -d linux          # Desktop Linux
flutter run -d windows        # Desktop Windows
flutter run -d chrome         # Web
flutter run -d <android_id>   # Dispositivo Android
flutter run -d <ios_id>       # Simulador iOS (solo macOS)
```

#### Release (binarios distribuibles)

```bash
# Linux
flutter build linux --release
# Artefacto: build/linux/x64/release/bundle/

# Windows
flutter build windows --release
# Artefacto: build/windows/x64/runner/Release/

# Android (APK / App Bundle)
flutter build apk --release
flutter build appbundle --release

# iOS (solo macOS)
flutter build ios --release
```

## Arquitectura

```
lib/
├── app/                    # Configuración global (router, tema, locale)
├── core/                   # Núcleo compartido
│   ├── api/               # Cliente HTTP, interceptors, paginación
│   ├── config/            # Env, constants
│   ├── storage/           # Secure storage
│   ├── utils/             # Formatters, validators
│   └── widgets/           # UI primitives (AppCard, GradientHeader, etc.)
├── features/              # Features por dominio (Clean Architecture)
│   ├── attendance/
│   ├── auth/
│   ├── chat/
│   ├── classrooms/
│   ├── dashboard/
│   ├── events/
│   ├── fees/
│   ├── news/
│   ├── notifications/
│   ├── profile/
│   ├── qualifications/
│   ├── search/
│   └── students/
└── l10n/                  # Internacionalización (ES/EN)
```

**Patrón por feature**: `data/` (API, repository), `domain/` (models), `providers/` (Riverpod), `screens/` (UI), `screens/widgets/` (UI components).

## Estado del proyecto

| Métrica | Valor |
|---------|-------|
| Tests | 230+ (98% pass, 1 flaky conocido) |
| Cobertura | `flutter test --coverage` |
| Análisis estático | `flutter analyze` ✅ clean |
| Temas | Claro / Oscuro / Sistema |
| Idiomas | Español (ES) / Inglés (EN) |
| Plataformas | Android, iOS, Web, Linux, macOS, Windows |

## CI/CD

### GitHub Actions (`.github/workflows/`)

| Workflow | Trigger | Qué hace |
|----------|---------|----------|
| `build.yml` | Push a `master` / tag | Build Linux + Windows, crea Release con artifacts |
| `sync.yml` | Schedule (6h) / push / manual | Format, analyze, test, build Linux/Windows, auto-tag version, PR de sync |

### Release automático

Al hacer push a `master`:

1. Se ejecutan tests + análisis en Linux y Windows
2. Se compilan binarios release
3. Se crea GitHub Release `v{version}` con artifacts adjuntos

## Scripts útiles

```bash
# Tests con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Análisis estático
flutter analyze

# Formateo
dart format .

# Generar código (tras cambios en models)
dart run build_runner build --delete-conflicting-outputs

# Limpiar build
flutter clean && flutter pub get
```

## Variables de entorno (`.env`)

| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| `API_BASE_URL` | Base URL del backend API | Sí |
| `REVERB_HOST` | Host del servidor Reverb (ver tabla por plataforma) | Para chat en vivo |
| `REVERB_PORT` | Puerto de Reverb (`8081` por defecto en el backend) | Para chat en vivo |
| `REVERB_APP_KEY` | App key de Reverb; debe coincidir con la del backend | Para chat en vivo |
| `REVERB_SCHEME` | `http` o `https` según el backend | Para chat en vivo |
| `FIREBASE_MESSAGING_KEY` | Para push notifications | No |
| `SENTRY_DSN` | Error tracking | No |

### Realtime (chat en vivo)

El chat en vivo usa Laravel Reverb por WebSocket. Copiá los valores
`REVERB_*` del `.env` del backend y ajustá **solo** `REVERB_HOST` según
dónde corra la app:

| Plataforma | `REVERB_HOST` |
|------------|---------------|
| Simulador iOS / Web / Desktop | `localhost` |
| Emulador Android | `10.0.2.2` |
| Dispositivo físico (Android/iOS) | IP de la LAN de la máquina que corre el backend (ej. `192.168.1.50`) |

El backend debe tener Reverb y la cola de trabajos corriendo. Sin el socket la
app sigue funcionando por REST (listar, enviar y abrir chats), pero sin
mensajes en vivo ni badge automático:

```bash
php artisan reverb:start
php artisan queue:listen --tries=1
```

## Contribuir

1. Fork del repo
2. Crea rama: `git checkout -b feat/mi-feature`
3. Commit: `git commit -m "feat: descripción"`
4. Push: `git push origin feat/mi-feature`
5. Abre Pull Request

## Licencia

Proyecto privado — Anavic AI Solutions. Uso interno únicamente.

---

**Versión actual**: `1.0.0+1` (tag `v1.0.0`)

**Contacto**: equipo@anavic-ai.com