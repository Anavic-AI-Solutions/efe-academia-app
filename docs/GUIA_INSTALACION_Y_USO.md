# Guía de instalación y uso — EFE Mobile

**App:** Windows (escritorio)
**Servidor:** preprod (`https://preprod.efeacademia.com/api/v1`)
**Versión de esta guía:** 1.0 (acompaña al release `v1.0.1`)

> ¿Buscás instalar en un **teléfono o tablet Android**? Usá la
> [Guía de instalación en Android](GUIA_INSTALACION_ANDROID.md).

---

## 1. Qué es EFE Mobile

EFE Mobile es la aplicación de escritorio **EFE — Escuela de Formación de
Enfermería**. Desde la computadora permite consultar:

- **Inicio**: estadísticas del día (alumnos, cuotas, novedades).
- **Aulas**: listado y detalle de cursos, con horarios, profesores y materiales.
- **Estudiantes**: ficha completa con asistencia, calificaciones y cuotas.
- **Calificaciones**: notas por alumno y promedio del período.
- **Chat**: mensajería entre los distintos roles.
- **Noticias, eventos y notificaciones**: feed unificado de la escuela.
- **Perfil**: datos de la cuenta, tema claro/oscuro, idioma y cierre de sesión.

### Requisitos

| Requisito | Detalle |
|-----------|---------|
| Sistema | Windows 10 u 11 (64 bits) |
| Conexión | Internet (Wi-Fi o cable) |

---

## 2. Acceso a la descarga (importante)

La aplicación se descarga desde el repositorio de GitHub de Anavic AI:

**https://github.com/Anavic-AI-Solutions/efe-academia-app**

El repositorio es **privado**: solo se puede ver y descargar con una cuenta
de GitHub a la que el equipo le haya dado acceso.

- ✅ Si tenés una cuenta de GitHub con acceso: entrá, abrí la pestaña
  **Releases** (o entrá directo a
  https://github.com/Anavic-AI-Solutions/efe-academia-app/releases/latest)
  y buscá el release más reciente.
- ❌ Si **no** tenés acceso: pedile al equipo (soporte de EFE / Anavic AI)
  que te comparta el archivo por otro medio (correo, WhatsApp, USB). El
  archivo que vas a pedir es **`efe-mobile-windows-x64.zip`**.

> **Nota:** el ZIP viene ya configurado para conectarse al servidor de
> pruebas (preprod). No hace falta tocar ninguna configuración para empezar.

---

## 3. Instalación

### Paso 1 — Descargar el ZIP

1. Abrí el navegador y entrá a
   https://github.com/Anavic-AI-Solutions/efe-academia-app/releases/latest
   (iniciá sesión con tu cuenta de GitHub si te lo pide).
2. Buscá el archivo **`efe-mobile-windows-x64.zip`** y hacé clic para
   descargarlo (queda en tu carpeta *Descargas*).

### Paso 2 — Descomprimir

1. Abrí la carpeta **Descargas**.
2. Hacé clic derecho sobre `efe-mobile-windows-x64.zip` y elegí
   **Extraer todo…** (en Windows 11: *Extraer todo*).
3. Elegí una carpeta de destino, por ejemplo:
   `C:\EFE-Mobile` (evitá carpetas protegidas del sistema como
   `C:\Program Files`, para que la app pueda guardar su configuración).
4. Hacé clic en **Extraer**. Al terminar tenés una carpeta con la app.

### Paso 3 — Primera ejecución

1. Entrá a la carpeta recién extraída y hacé doble clic en **`efe_mobile.exe`**.
2. **Aviso de SmartScreen (importante):** la primera vez, Windows puede
   mostrar "Windows protegió tu PC" porque la aplicación no tiene firma de
   Microsoft. Para continuar:
   - Clic en **Más información** (o *More info*).
   - Clic en **Ejecutar de todas formas** (o *Run anyway*).
3. La ventana de la aplicación se abre con la **pantalla de inicio de
   sesión** (logo de EFE, campos de correo y contraseña). Eso ya está bien:
   la app está esperando que inicies sesión.

> **Cómo funciona la configuración (avanzado):** la primera vez que se abre,
> la app crea un archivo llamado **`.env`** en la misma carpeta, con la línea
> `API_BASE_URL=...` que indica a qué servidor se conecta. No hace falta
> tocarlo. Si algún día el equipo te indica otra dirección, se edita ese
> archivo con el Bloc de notas y se vuelve a abrir la app.

### Paso 4 — Iniciar sesión

1. En el campo **Correo electrónico**, escribí la dirección que te dio el
   equipo (placeholders de ejemplo: `[EMAIL]`).
2. En el campo **Contraseña**, escribí la contraseña otorgada
   (`[CONTRASEÑA]`; el ojo 👁️ al final del campo muestra/oculta los
   caracteres).
3. Tocá el botón **Iniciar sesión**.
4. La app valida los datos y te lleva a la **pantalla de Inicio** con las
   estadísticas del día. ¡Listo, ya estás adentro! 🎉

> Si no tenés cuenta todavía: pedila al equipo de EFE (te van a indicar
> correo y contraseña de prueba o definitiva).

### Paso 5 — Uso diario

- **La sesión queda guardada**: al cerrar la app y volver a abrirla, entrás
  directo a la pantalla de Inicio (no vuelve a pedirte la contraseña).
- **Para salir**: andá a **Perfil** (pestaña de la barra inferior) y tocá
  **Cerrar sesión**.
- **Cambiar idioma o tema**: también en **Perfil** (idioma y tema
  claro/oscuro).

---

## 4. Cómo pedir una cuenta si no tenés una

1. Escribile al equipo de EFE / Anavic AI (o al soporte que te indicó la
   institución).
2. Deciles que necesitás una cuenta para **EFE Mobile** y tu **rol**
   (directivo, profesor, estudiante o familia).
3. Te van a dar un **correo** y una **contraseña**, y el servidor al que
   tenés que apuntar (por defecto la app ya viene configurada con preprod).

---

## 5. Problemas comunes

| Problema | Qué hacer |
|----------|-----------|
| **"No se puede conectar al servidor"** al iniciar sesión | Revisá que tengas internet. Si recién te cambiaron el servidor, cerrá la app y volvé a abrirla. |
| **"Credenciales inválidas"** / no deja entrar | Revisá mayúsculas y espacios en el correo y la contraseña. Si sigue fallando, pedile al soporte que verifique tu cuenta (o que te restablezca la contraseña). |
| **Windows bloquea la app (SmartScreen)** | Clic en **Más información** → **Ejecutar de todas formas** (ver Paso 3). Si lo bloquea el antivirus, agregá una excepción para la carpeta donde está `efe_mobile.exe`. |
| **La app queda en pantalla blanca o congelada** | Cerrá la app por completo (cerrá la ventana y verificá que no quede en segundo plano) y volvé a abrirla. |
| **No me llegan las notificaciones** | Las notificaciones push se habilitan según la cuenta y el servidor; consultá con soporte. |

---

## 6. Preguntas frecuentes

**¿La app guarda mi contraseña?** La app guarda una sesión segura: no tenés
que escribir la contraseña cada vez. Para salir, usá **Perfil → Cerrar
sesión**.

**¿Cuánto vale?** Es una aplicación interna de la escuela; si te piden pagar
por algo, avisale al soporte.

**¿Qué hago si olvidé la contraseña?** En la pantalla de inicio tocá
**¿Olvidaste tu contraseña?** y seguí los pasos con tu correo. Si no
funciona, pedí ayuda a soporte.

**¿En qué idioma está?** Español e inglés; se cambia en **Perfil**.

---

## Glosario

| Término | Qué significa |
|---------|---------------|
| **Release** | Versión publicada del programa en GitHub, con los archivos para descargar. |
| **Preprod** | Servidor de pruebas donde se validan las cuentas y los datos antes de producción. |
| **`.env`** | Archivo de configuración de la app (indica a qué servidor conectarse). No hace falta editarlo normalmente. |
| **SmartScreen** | Filtro de seguridad de Windows que avisa al ejecutar programas sin firma conocida. |

---

*Guía mantenida por el equipo de desarrollo — Anavic AI Solutions.
Ante dudas: soporte de EFE.*