---
name: efe-mobile-instalar-y-usar
description: Use when someone needs to install, launch, or reach the logged-in screen of EFE Mobile on Windows desktop from the GitHub release, or asks for support with downloading, installing, logging in, or configuring the app's server. Triggers include "descargar la app", "instalar EFE", "cómo entro a la app", "no me loguea", "no puedo conectarme al servidor", and setup or demo requests for EFE Mobile.
---

# EFE Mobile: instalar y usar

## Overview

EFE Mobile es la app de escritorio (Flutter) del ERP educativo EFE.
Este skill dice cómo se descarga del release de GitHub, se instala en
Windows y se llega a la pantalla de inicio con la sesión iniciada. La guía
completa para personas está en `docs/GUIA_INSTALACION_Y_USO.md` del repo.

**Nunca inventar credenciales.** Las cuentas las otorga el equipo; en la
guía y en ejemplos van como placeholders `[EMAIL]` / `[CONTRASEÑA]`.

## Cuando el agente ejecuta vs. cuando guía

- **Ejecutar** (solo si el agente corre en una máquina Windows real y el
  usuario lo pidió): descargar el ZIP del release, extraer, abrir
  `efe_mobile.exe`, verificar que la pantalla de login aparezca, y —si hay
  credenciales del usuario disponibles— iniciar sesión y confirmar la
  pantalla de Inicio. Nunca crear cuentas ni escribir credenciales en el repo.
- **Guiar** (caso más común: el usuario está en su propia PC): responder con
  los pasos numerados y referir a la guía del repo.

## Pasos (Windows)

1. Acceso: el repo `Anavic-AI-Solutions/efe-academia-app` es **privado**.
   Si el usuario no tiene cuenta con acceso, pedirle que solicite los
   archivos al equipo (o compartirle `efe-mobile-windows-x64.zip` por otro
   medio aprobado).
2. Descargar desde
   `https://github.com/Anavic-AI-Solutions/efe-academia-app/releases/latest`
   el archivo `efe-mobile-windows-x64.zip`.
3. Extraer en una carpeta simple (ej. `C:\EFE-Mobile`), **no** en
   `C:\Program Files`.
4. Doble clic en `efe_mobile.exe`. Ante el aviso de **SmartScreen**
   ("Windows protegió tu PC"): *Más información* → *Ejecutar de todas formas*.
5. La app abre la pantalla de login. La app ya apunta a preprod; **no** hay
   que tocar el `.env` salvo indicación del equipo (bloc de notas, línea
   `API_BASE_URL=`, reiniciar la app).
6. Login con las credenciales otorgadas → pantalla de **Inicio**.

## Checklist de verificación

La tarea NO está completa hasta que:

- [ ] `efe_mobile.exe` abre en la máquina del usuario (o se le dio el paso exacto).
- [ ] El usuario (o el agente) llegó a la **pantalla de login** visible.
- [ ] Con credenciales reales: **pantalla de Inicio visible** (datos cargados).
- [ ] Sin credenciales a mano: se indicó claramente a quién pedirlas (soporte/equipo).
- [ ] No se publicó ninguna credencial ni URL interna en chats o código.

## Errores comunes

| Síntoma | Causa probable | Respuesta |
|---------|----------------|-----------|
| "No se puede conectar al servidor" | Sin internet, o `.env` apuntando a otro servidor | Revisar conexión; si se editó `.env`, reiniciar la app |
| "Credenciales inválidas" | Cuenta mal tipeada o no otorgada | Revisar mayúsculas/espacios; pedir cuenta/reset al equipo |
| Windows bloquea la app | SmartScreen / antivirus (app sin firma) | *Más información* → *Ejecutar de todas formas*; excepción del antivirus |
| No abre o pantalla blanca | Instalación incompleta | Reextraer el ZIP; verificar antivirus |

## Referencias

- Guía completa para personas: `docs/GUIA_INSTALACION_Y_USO.md`.
- Servidor configurado en los builds: preprod
  (`API_BASE_URL=https://preprod.efeacademia.com/api/v1`). Si el equipo pide
  otro servidor, se cambia la línea `API_BASE_URL` del `.env` junto al exe.