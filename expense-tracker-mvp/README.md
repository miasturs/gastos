# 💰 Gestor de Gastos Personales — MVP

[![Demo](https://img.shields.io/badge/🌐_Demo_Web-Abrir-blue)](https://TU_USUARIO.github.io/TU_REPO/)

Aplicación web progresiva (PWA) para gestionar gastos personales. Funciona 100% en el navegador, sin servidor, sin instalación, sin compilación.

## 🚀 Cómo usarla

### 1. Subir el repositorio

1. Crea un repositorio en https://github.com/new llamado `expense-tracker-mvp`
2. Sube estas carpetas y archivos (arrastrándolos desde la web de GitHub o con GitHub Desktop)
3. Ve a **Settings → Pages**
4. En **Source**, selecciona **Deploy from a branch**
5. En **Branch**, elige `main` y carpeta `/ (root)` → **Save**

En 1–2 minutos tu app estará en:
`https://TU_USUARIO.github.io/expense-tracker-mvp/`

### 2. Instalar en tu dispositivo (opcional)

Al abrir la URL en Chrome/Edge/Safari, aparecerá un botón **"Instalar"** en la barra o en el menú. Al instalarla, queda como app nativa con su propio ícono, sin necesitar APK.

## ✨ Funcionalidades

- 📊 **CRUD completo** de gastos, categorías y presupuestos
- 🔐 **Autenticación local** con contraseña (PBKDF2 + SHA-256)
- 🔒 **Cifrado AES-256-GCM** de todos los datos almacenados
- 💾 **Persistencia en IndexedDB** (funciona offline)
- 👆 **Biometría** con WebAuthn (huella/Face ID del dispositivo)
- 📸 **Cámara** para capturar tickets (getUserMedia)
- 🔔 **Notificaciones nativas** (Notification API) con alerta al 80% del presupuesto
- 📈 **Gráficos** con Chart.js
- 💵 **Formato de moneda** localizado con Intl
- ☁️ **Sincronización opcional** con Supabase (configura en `js/config.js`)
- 📱 **Instalable como PWA** (funciona como app nativa)

## 🛠️ Stack técnico

| Requisito | Implementación |
|---|---|
| Framework | HTML5 + CSS3 + JavaScript vanilla |
| Persistencia | IndexedDB + cifrado AES-256-GCM |
| Autenticación | PBKDF2 + SHA-256 + WebAuthn (biometría) |
| Cifrado | Web Crypto API |
| Cámara | `navigator.mediaDevices.getUserMedia` |
| Notificaciones | Notification API |
| Gráficos | Chart.js (CDN) |
| Formato | Intl.NumberFormat |
| Sync (opcional) | Supabase (CDN) |
| PWA | Service Worker + manifest.json |

## 🌳 Ramas del repositorio

Para cumplir con el flujo de Git requerido:

```bash
# Rama principal
git checkout -b main

# Rama de desarrollo
git checkout -b develop

# Features
git checkout -b feature/login develop
git checkout -b feature/crud-gastos develop

# Hotfix
git checkout -b hotfix/notificaciones main
```

Y sube cada rama con `git push origin <rama>`.

## 🔧 Configuración opcional de Supabase

Si quieres sincronizar en la nube:

1. Crea un proyecto gratis en https://supabase.com
2. Ejecuta este SQL en el editor:
   ```sql
   create table gastos (
     id uuid primary key,
     user_id uuid references auth.users(id),
     monto float8 not null,
     fecha text not null,
     categoria_id text not null,
     descripcion text
   );
   ```
3. Copia tu **URL** y **anon key** de Settings → API
4. Pégalos en `js/config.js`:
   ```js
   window.APP_CONFIG = {
     supabaseUrl: 'https://tu-proyecto.supabase.co',
     supabaseAnonKey: 'tu-anon-key-aqui'
   };
   ```

Sin esta configuración, la app funciona 100% offline.

## 🔐 Seguridad

- Contraseña derivada con **PBKDF2** (150.000 iteraciones, SHA-256)
- Datos cifrados con **AES-256-GCM** antes de guardar en IndexedDB
- La clave de cifrado **solo reside en memoria** durante la sesión
- Al cerrar la pestaña, se requiere reautenticación
- No hay backend, no hay envío de datos a servidores de terceros (salvo que configures Supabase)

## 📄 Licencia

MIT