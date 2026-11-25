# 💰 Mis Gastos — MVP (Flutter)

MVP de gestión de gastos personales con **SQLite cifrado**, **Firebase Auth**, **Firestore sync**, **biometría**, **notificaciones locales** y **captura de tickets**.

## 📋 Requisitos cubiertos

| # | Requisito | Implementación |
|---|---|---|
| 1 | BD local | `sqflite_sqlcipher` (AES-256) |
| 2 | CRUD gastos | `ExpenseRepository` + `ExpenseFormScreen` |
| 3 | 3 entidades con FK | `Category`, `Budget`, `Expense` |
| 4 | Auth | `FirebaseAuth` con fallback demo |
| 5 | Sync nube | `SyncService` (Firestore offline-first) |
| 6 | Estados UI | `AsyncValue.when()` en todas las pantallas |
| 7 | Cámara | `image_picker` |
| 8 | Biometría | `local_auth` |
| 9 | Notificación local | `flutter_local_notifications` (alerta 80% + recordatorio semanal) |
| 10 | Cifrado local | SQLCipher + `flutter_secure_storage` |
| 11 | Validación | `TextFormField.validator` en todos los forms |
| 12 | Librerías terceros | `intl`, `fl_chart`, `image_picker` (+ `uuid`) |

## 🚀 Instalación

### Requisitos
- Flutter ≥ 3.16 (`flutter --version`)
- Android Studio / Xcode

### Pasos

```bash
git clone https://github.com/TU_USUARIO/expense_mvp.git
cd expense_mvp
flutter pub get
flutter run
```

La app arranca **en modo demo sin Firebase** (auth local + BD local, sync simulado).

### Configurar Firebase (recomendado para defensa)

1. Crear proyecto en https://console.firebase.google.com
2. Activar **Auth → Email/Password** y **Firestore**
3. Ejecutar:
   ```bash
   npm i -g firebase-tools
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. En `lib/main.dart` descomentar:
   ```dart
   import 'firebase_options.dart';
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
5. Reglas Firestore:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{db}/documents {
       match /users/{userId}/expenses/{expenseId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
6. `flutter run` y probar sync.

### Permisos Android

`android/app/src/main/AndroidManifest.xml` (dentro de `<manifest>`):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Permisos iOS

`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Para capturar tickets de gastos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para adjuntar imágenes de tickets</string>
<key>NSFaceIDUsageDescription</key>
<string>Para autenticación biométrica</string>
```

## 🌿 Flujo Git (rúbrica)

```bash
# Inicialización
git init && git add . && git commit -m "chore: initial project setup"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/expense_mvp.git
git push -u origin main

# Develop
git checkout -b develop
git push -u origin develop

# Feature login
git checkout -b feature/login develop
git commit -m "feat(auth): add AuthService with Firebase + demo fallback"
git commit -m "feat(auth): implement biometric login with local_auth"
git commit -m "feat(auth): add login screen with validations"
git commit -m "test(auth): add widget test for login form"
git commit -m "docs(auth): document biometric token storage"
git push -u origin feature/login
# Abrir PR feature/login → develop, auto-comentar y mergear

# Feature CRUD
git checkout -b feature/expense_crud develop
git commit -m "feat(db): add SQLCipher database helper with encryption key"
git commit -m "feat(models): add Expense, Category and Budget entities"
git commit -m "feat(repo): implement CRUD for expenses"
git commit -m "feat(ui): build expense form with camera ticket capture"
git commit -m "feat(ui): add category pie chart with fl_chart"
git commit -m "feat(notif): schedule budget alert at 80% threshold"
git push -u origin feature/expense_crud

# Feature sync
git checkout -b feature/sync develop
git commit -m "feat(sync): add offline-first sync with Firestore"
git commit -m "feat(ui): add sync button with loading state"
git push -u origin feature/sync

# Hotfix
git checkout -b hotfix/token_storage main
git commit -m "fix(security): move token from SharedPreferences to secure_storage"
git push -u origin hotfix/token_storage
# Abrir PR hotfix → main, mergear, luego merge main → develop
```

Total: **≥ 18 commits** ✅

## 🔐 Seguridad

- **Cifrado en reposo**: SQLCipher AES-256. Clave de 72 chars en Keychain (iOS) / Keystore (Android) vía `flutter_secure_storage`.
- **Tokens biométricos**: almacenados con `flutter_secure_storage`, nunca en SharedPreferences.
- **Firebase tokens**: gestionados por SDK (auto-refresh).
- **Validación de inputs**: en `Form.validator` (UI) y en `repository` (tipo).
- **Firestore Rules**: cada usuario solo accede a `/users/{su_uid}/...`.

## 📄 Reporte PDF

Incluye:
- Diagrama de clases (Mermaid en `/docs/`)
- Modelo de datos SQL con FK
- Descripción de mecanismos de seguridad (arriba)
- Capturas de pantalla
- Captura del PR mergeado

## 🧪 Tests

```bash
flutter test
```

## 📦 Estructura

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp + routing por auth
├── core/theme.dart
├── data/
│   ├── models/            # Category, Expense, Budget
│   ├── database/          # SQLCipher
│   └── repositories/      # CRUD
├── services/              # auth, bio, notif, sync
├── providers/             # Riverpod
└── presentation/
    ├── screens/           # login, home, form, budgets
    └── widgets/           # tile, chart
```