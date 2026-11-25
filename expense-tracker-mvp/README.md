# 💰 Gestor de Gastos Personales — MVP

[![Demo Web](https://img.shields.io/badge/Demo-Web-blue)](https://TU_USUARIO.github.io/TU_REPO/)
[![Descargar APK](https://img.shields.io/badge/Descargar-APK-green)](https://github.com/TU_USUARIO/TU_REPO/releases/latest)

Aplicación móvil MVP de gestión de gastos personales desarrollada en **Flutter**.

## ✨ Funcionalidades

- 📊 CRUD completo de gastos, categorías y presupuestos
- 🔐 Autenticación con Supabase Auth (opcional)
- 🔒 Persistencia local cifrada con **Hive + AES-256**
- ☁️ Sincronización manual con Supabase
- 📸 Captura de foto de ticket con la cámara
- 👆 Autenticación biométrica (huella/Face ID) — solo móvil
- 🔔 Notificaciones locales programadas (presupuesto >80%) — solo móvil
- 📈 Gráficos con **fl_chart**
- 💵 Formato de moneda localizado con **intl**

## 📦 Stack

| Requisito | Herramienta |
|---|---|
| Framework | Flutter |
| Persistencia local | Hive + HiveAesCipher |
| Auth + Sync | Supabase |
| Cámara | image_picker |
| Biometría | local_auth |
| Notificaciones | flutter_local_notifications |
| Gráficos | fl_chart |
| Formato de moneda | intl |

## 🚀 Instalación local

```bash
# 1. Clonar
git clone https://github.com/TU_USUARIO/TU_REPO.git
cd TU_REPO

# 2. Generar archivos de plataforma (android/, ios/, web/)
flutter create .

# 3. Instalar dependencias
flutter pub get

# 4. Ejecutar en Web
flutter run -d chrome

# 5. O en Android
flutter run -d android
```

> **Nota:** El proyecto **funciona sin configurar Supabase**. Si quieres habilitar la sincronización:
> 1. Crea un proyecto en https://supabase.com
> 2. En `lib/main.dart`, rellena `supabaseUrl` y `supabaseAnonKey`
> 3. Crea la tabla `gastos` en Supabase con columnas: `id` (uuid, PK), `user_id` (uuid), `monto` (float8), `fecha` (text), `categoria_id` (text), `descripcion` (text)

## 🌐 Publicar en GitHub Pages

1. En **Settings → Pages**, selecciona **Source: GitHub Actions**
2. Haz push a `main` — el workflow `deploy-web.yml` compilará y publicará
3. La URL será `https://TU_USUARIO.github.io/TU_REPO/`

## 📱 Publicar APK descargable

```bash
flutter build apk --release
```

1. Ve a **Releases → Draft a new release** en GitHub
2. Tag: `v1.0.0`
3. Sube el archivo `build/app/outputs/flutter-apk/app-release.apk`
4. Publica

## 🔧 Configuración extra para Android (biometría)

Edita `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

Y en `android/app/src/main/AndroidManifest.xml` añade:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

## 🌳 Ramas y flujo de trabajo

- `main` — versión estable
- `develop` — integración
- `feature/login` — autenticación
- `feature/crud-gastos` — CRUD y gráficos
- `hotfix/notificaciones` — correcciones urgentes

## 📄 Licencia

MIT