# Guía de instalación en Android — EFE Mobile

**App:** Android (teléfono o tablet)
**Servidor:** preprod (`https://preprod.efeacademia.com/api/v1`)
**Archivo:** `app-release.apk`
**Versión de esta guía:** 1.0 (acompaña al release `v1.0.1`)

---

## 1. Antes de empezar

EFE Mobile es la aplicación de **EFE — Escuela de Formación de Enfermería**.
En Android permite consultar el inicio, aulas, estudiantes, calificaciones,
cuotas, chat, noticias, eventos, notificaciones y el perfil de la cuenta.

### Requisitos

| Requisito | Detalle |
|-----------|---------|
| Sistema | Android 6.0 (API 23) o superior |
| Espacio libre | ~100 MB |
| Conexión | Internet (Wi-Fi o datos móviles) |
| Cuenta | Correo y contraseña otorgados por el equipo de EFE |

> La app **no está publicada en Play Store**. Se instala con el archivo APK
> que el equipo publica en GitHub. Por eso Android muestra avisos de
> seguridad la primera vez; son normales y se explican más abajo.

---

## 2. Descargar el APK

La descarga se hace desde el repositorio de GitHub de Anavic AI:

**https://github.com/Anavic-AI-Solutions/efe-academia-app**

El repositorio es **privado**: solo se puede ver y descargar con una cuenta
de GitHub a la que el equipo le haya dado acceso.

### Opción A — Descargar directo en el teléfono (recomendado)

1. Abrí el navegador (Chrome, Edge o el que uses) en el teléfono.
2. Entrá a
   https://github.com/Anavic-AI-Solutions/efe-academia-app/releases/latest
   e iniciá sesión con tu cuenta de GitHub si te lo pide.
3. En la sección **Assets** del release más reciente, tocá
   **`app-release.apk`**.
4. Si Chrome avisa *"Este tipo de archivo puede dañar tu dispositivo"*,
   elegí **Descargar de todos modos**. Es el aviso estándar para cualquier
   APK, no un error.
5. Esperá a que termine la descarga. El archivo queda en
   **Descargas** (o *Downloads*) del teléfono.

> Si no tenés acceso al repositorio, pedile al equipo de EFE / Anavic AI que
> te comparta **`app-release.apk`** por otro medio aprobado (correo, Google
> Drive, USB). No lo bajes de sitios de terceros: solo es válido el archivo
> que entrega el equipo.

### Opción B — Descargar en la PC y pasarlo al teléfono

1. Descargá `app-release.apk` desde el mismo enlace usando la PC.
2. Pasalo al teléfono de alguna de estas formas:
   - **Cable USB:** conectá el teléfono, elegí *Transferir archivos* y copiá
     el APK a la carpeta **Download** del teléfono.
   - **Google Drive / correo:** subilo y abrilo desde el teléfono, luego
     descargalo.
3. Guardalo en **Descargas** para encontrarlo fácil.

---

## 3. Instalar la app

Los nombres de los menús cambian un poco según la marca (Samsung, Xiaomi,
Motorola, etc.), pero el flujo es el mismo.

### Paso 1 — Abrir el APK

1. Abrí la app **Archivos** (o *Files*) y entrá a **Descargas**.
2. Tocá **`app-release.apk`**.
3. Si aparece *"Para tu seguridad, tu teléfono no puede instalar apps
   desconocidas"*, tocá **Configuración** y activá el permiso para la app
   desde la que estás abriendo el archivo (Archivos o Chrome). Volvé atrás.

   También podés activarlo a mano:
   **Ajustes → Aplicaciones → Acceso especial → Instalar apps desconocidas**
   → elegí **Chrome** o **Archivos** → **Permitir desde esta fuente**.

   En Samsung suele estar en **Ajustes → Seguridad y privacidad → Instalar
   apps desconocidas**. En Xiaomi/MIUI: **Ajustes → Privacidad → Permisos
   especiales → Instalar apps desconocidas**.

### Paso 2 — Confirmar la instalación

1. Tocá **Instalar**.
2. Si **Play Protect** avisa *"No se puede comprobar si hay apps dañinas"*
   o *"Desarrollador desconocido"*, elegí **Instalar de todos modos**.
   La app está firmada con una clave de desarrollo interna, por eso el
   aviso; no significa que tenga virus.
3. Esperá unos segundos hasta que diga **Aplicación instalada**.

> Algunos fabricantes (Xiaomi, Huawei, vivo) agregan avisos extra o una
> cuenta regresiva de 10–20 segundos. Esperá y tocá **Instalar de todos
> modos** / **Continuar**.

### Paso 3 — Abrir la app

1. Tocá **Abrir** al terminar la instalación, o buscá el ícono
   **EFE Academia de Ingles** en el cajón de aplicaciones.
2. La app muestra la **pantalla de inicio de sesión** (logo de EFE, campos
   de correo y contraseña). Eso significa que quedó bien instalada.

---

## 4. Primer ingreso

1. En **Correo electrónico**, escribí la dirección que te dio el equipo
   (placeholder de ejemplo: `[EMAIL]`).
2. En **Contraseña**, escribí la contraseña otorgada
   (`[CONTRASEÑA]`). El ojo 👁️ al final del campo muestra u oculta los
   caracteres.
3. Tocá **Iniciar sesión**.
4. Si los datos son correctos, entrás a la **pantalla de Inicio** con las
   estadísticas del día.

> **No inventes credenciales ni las compartas.** Si no tenés cuenta, pedila
> al equipo de EFE indicando tu rol (directivo, profesor, estudiante o
> familia).

### Después del primer ingreso

- **La sesión queda guardada:** al cerrar y volver a abrir la app entrás
  directo a Inicio.
- **Notificaciones:** en Android 13 o superior, la app pide permiso para
  enviarlas. Aceptalo si querés recibir avisos. Si lo rechazaste, se activa
  en **Ajustes → Aplicaciones → EFE Academia de Ingles → Notificaciones**.
- **Para salir:** **Perfil → Cerrar sesión**.
- **Tema e idioma:** también en **Perfil**.

---

## 5. Actualizar la app

Cuando el equipo publique una versión nueva:

1. Descargá el nuevo `app-release.apk` (mismo enlace del paso 2).
2. Abrilo y tocá **Instalar**. Android lo instala **encima** de la versión
   anterior; no hace falta desinstalar y la sesión se conserva.

> Si Android responde *"App no instalada"* al actualizar, suele ser porque el
> APK descargado está incompleto: volvé a descargarlo. Si aun así falla,
> desinstalá la versión vieja e instalá la nueva (vas a tener que iniciar
> sesión otra vez).

### Desinstalar

Mantené presionado el ícono → **Desinstalar** (o **Ajustes → Aplicaciones →
EFE Academia de Ingles → Desinstalar**). Se borra la sesión guardada, no tus
datos en el servidor.

---

## 6. Problemas comunes

| Problema | Qué hacer |
|----------|-----------|
| **No aparece la opción de instalar / "Bloqueado por seguridad"** | Activá *Instalar apps desconocidas* para Chrome o Archivos (Paso 1). |
| **"Se produjo un error al analizar el paquete"** | El APK se descargó incompleto o corrupto. Borralo y descargalo de nuevo desde el release oficial. |
| **"App no instalada"** | Verificá que sea el APK de EFE, que haya espacio libre y que no exista una versión instalada con otra firma. Desinstalá la anterior y reintentá. |
| **Play Protect bloquea la instalación** | Tocá **Más detalles → Instalar de todos modos**. Si insiste, desactivá temporalmente *Analizar apps* en Play Store → Perfil → Play Protect; volvé a activarlo después. |
| **La app se cierra al abrirla** | Reiniciá el teléfono y abrí de nuevo. Si sigue, desinstalá, descargá otra vez el APK y reinstalá. |
| **"No se puede conectar al servidor"** | Revisá la conexión a internet. La app apunta a preprod; si el equipo cambió el servidor, hay que instalar el APK nuevo. |
| **"Credenciales inválidas"** | Revisá mayúsculas, espacios y que el correo sea el otorgado. Si persiste, pedí a soporte que verifique o restablezca tu cuenta. |
| **No llegan notificaciones** | Aceptá el permiso de notificaciones (Android 13+) y revisá que la app no esté restringida en **Ajustes → Batería**. |

---

## 7. Instalación por USB (opcional, para soporte técnico)

Requiere **Depuración USB** activada en el teléfono
(**Ajustes → Opciones de desarrollador**) y `adb` instalado en la PC.

```bash
# Verificar que el teléfono esté conectado y autorizado
adb devices

# Instalar o actualizar conservando los datos
adb install -r app-release.apk

# Si hay que bajar de versión (downgrade) en un equipo de pruebas
adb install -r -d app-release.apk
```

Errores típicos de `adb`:

| Mensaje | Causa / solución |
|---------|------------------|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Hay una versión instalada con otra firma. Desinstalar y reinstalar. |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | El APK es más viejo que el instalado. Usar `-d` solo en pruebas. |
| `device unauthorized` | Aceptar el diálogo de depuración USB en el teléfono. |

---

## 8. Notas técnicas

| Dato | Valor |
|------|-------|
| Paquete (`applicationId`) | `com.efe.efe_mobile` |
| Nombre visible | EFE Academia de Ingles |
| Android mínimo | 6.0 (API 23) |
| Artefacto del release | `app-release.apk` |
| Firma | Debug key del proyecto (instalable, **no** apta para Play Store) |
| Servidor | preprod (`https://preprod.efeacademia.com/api/v1`) |

- En Android la configuración del servidor viene **incluida dentro del
  APK**; no existe un `.env` editable como en la versión de escritorio.
  Para apuntar a otro servidor hay que compilar/publicar un APK nuevo.
- El APK se genera en el workflow `.github/workflows/build.yml`
  (`flutter build apk --release`) y se adjunta al release
  `v{versión}` junto con los paquetes de Linux y Windows.
- Para publicar en Play Store hace falta configurar un keystore real y
  reemplazar `signingConfigs.debug` en `android/app/build.gradle`.

### Compilar el APK desde el código (desarrolladores)

```bash
cp .env.example .env   # configurar API_BASE_URL y REVERB_*
flutter pub get
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

---

## Ver también

- [Guía de instalación y uso en Windows](GUIA_INSTALACION_Y_USO.md)
- [README del proyecto](../README.md)

---

*Guía mantenida por el equipo de desarrollo — Anavic AI Solutions.
Ante dudas: soporte de EFE.*
