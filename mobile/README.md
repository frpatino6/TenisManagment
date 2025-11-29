# 📱 Tennis Management Mobile App

Aplicación móvil Flutter para el sistema de gestión de tenis.

---

## 🚀 Características

- ✅ **Autenticación con Google** via Firebase
- ✅ **Autenticación con email/contraseña** via Firebase
- ✅ **Integración completa** con el backend Node.js
- ✅ **UI moderna** y responsive con Material Design 3
- ✅ **Manejo de estados** con Riverpod
- ✅ **Navegación** con GoRouter
- ✅ **Múltiples ambientes** (desarrollo y producción)
- ✅ **Temas claro/oscuro**

---

## 🌍 Ambientes

La aplicación soporta dos ambientes completamente separados:

### 🔧 Desarrollo (DEV)
- **Backend:** `http://10.0.2.2:3000` (localhost en emulador Android)
- **App Name:** Tennis DEV
- **Package:** `com.tennismanagement.tennis_management.dev`
- **Firebase:** tennis-management-fcd54 (por ahora)
- **Debug logs:** ✅ Habilitados
- **Uso:** Desarrollo local contra tu backend local

### 🌐 Producción (PROD)
- **Backend:** `https://tenismanagment.onrender.com`
- **App Name:** Tennis Management
- **Package:** `com.tennismanagement.tennis_management`
- **Firebase:** tennis-management-fcd54
- **Debug logs:** ❌ Deshabilitados
- **Uso:** Testing contra backend en Render o para releases

> 💡 **Nota:** Ambas apps pueden estar instaladas simultáneamente en el mismo dispositivo.

---

## 🏃‍♂️ Ejecutar la Aplicación

### Opción 1: Scripts (Recomendado)

```bash
# Desarrollo (backend local)
./scripts/run_dev.sh

# Producción (backend Render)
./scripts/run_prod.sh
```

### Opción 2: Comandos Flutter directos

```bash
# Desarrollo
flutter run --flavor dev -t lib/main_dev.dart

# Producción
flutter run --flavor prod -t lib/main_prod.dart

# Producción (por defecto)
flutter run
```

### Opción 3: Especificar dispositivo

```bash
# En un dispositivo específico
./scripts/run_dev.sh android
./scripts/run_prod.sh ios

# O con Flutter
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```

---

## 🏗️ Construir APK/AAB

### APK para instalación directa

```bash
# Desarrollo
./scripts/build_dev.sh apk

# Producción
./scripts/build_prod.sh apk
```

### App Bundle para Google Play

```bash
# Desarrollo
./scripts/build_dev.sh appbundle

# Producción
./scripts/build_prod.sh appbundle
```

### Ubicaciones de los builds

- **Dev APK:** `build/app/outputs/flutter-apk/app-dev-release.apk`
- **Prod APK:** `build/app/outputs/flutter-apk/app-prod-release.apk`
- **Dev AAB:** `build/app/outputs/bundle/devRelease/app-dev-release.aab`
- **Prod AAB:** `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

---

## 📦 Instalación y Setup

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Verificar instalación de Flutter

```bash
flutter doctor
```

### 3. Configurar Firebase (si no está configurado)

Los archivos de Firebase ya están configurados en:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Si necesitas actualizar la configuración de Firebase:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto `tennis-management-fcd54`
3. Descarga los archivos de configuración actualizados

---

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Tests con coverage
flutter test --coverage

# Análisis de código
flutter analyze
```

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Entrypoint por defecto (prod)
├── main_dev.dart            # Entrypoint desarrollo
├── main_prod.dart           # Entrypoint producción
├── main_common.dart         # Widget principal compartido
├── firebase_options.dart    # Config Firebase (legacy)
│
├── core/                    # Funcionalidad compartida
│   ├── config/
│   │   ├── environment.dart      # Enum de ambientes
│   │   ├── app_config.dart       # Configuración por ambiente
│   │   └── firebase_config.dart  # Firebase por ambiente
│   ├── router/
│   │   └── app_router.dart       # Navegación (GoRouter)
│   ├── theme/
│   │   ├── app_theme.dart        # Temas Material 3
│   │   └── theme_provider.dart   # Provider de tema
│   ├── services/
│   │   └── version_service.dart
│   └── widgets/                  # Widgets compartidos
│
└── features/               # Organización por características
    ├── auth/              # Autenticación
    │   ├── domain/
    │   │   ├── models/
    │   │   └── services/
    │   └── presentation/
    │       ├── providers/
    │       ├── screens/
    │       └── widgets/
    │
    ├── professor/         # Funcionalidad del profesor
    ├── student/           # Funcionalidad del estudiante
    ├── booking/           # Sistema de reservas
    ├── home/              # Pantalla principal
    └── settings/          # Configuración
```

---

## 🔧 Configuración de Ambientes

### Cambiar Backend URL

Edita `lib/core/config/app_config.dart`:

```dart
static String get backendUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://10.0.2.2:3000';  // ← Cambiar aquí
    case Environment.production:
      return 'https://tenismanagment.onrender.com';
  }
}
```

### Agregar nuevo ambiente

Si necesitas agregar más ambientes (staging, uat, etc.):

1. Agrega el ambiente a `lib/core/config/environment.dart`
2. Actualiza `app_config.dart` con la nueva configuración
3. Crea un nuevo entrypoint `main_staging.dart`
4. Agrega el flavor en `android/app/build.gradle.kts`
5. Crea un script `scripts/run_staging.sh`

---

## 🍏 iOS Setup

Para configurar iOS con múltiples schemes, sigue la guía:

```bash
cat IOS_SCHEMES_SETUP.md
```

> ⚠️ **Nota:** La configuración de iOS requiere Xcode y debe hacerse manualmente.

---

## 🐛 Troubleshooting

### Error: "No se puede conectar al backend"

**En Desarrollo:**
1. Verifica que el backend esté ejecutándose en `localhost:3000`
2. En emulador Android, usa `10.0.2.2` en lugar de `localhost`
3. En dispositivo físico, usa la IP de tu máquina (ej: `192.168.1.100`)

**En Producción:**
1. Verifica que el backend en Render esté activo
2. Revisa la URL en `app_config.dart`

### Error: "Firebase ya está inicializado"

Esto es normal y la app maneja este error automáticamente. Puedes ignorarlo.

### Error: "Flavor no encontrado"

Asegúrate de especificar el flavor correcto:
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### La app muestra el ambiente incorrecto

Verifica en los logs al inicio:
```
🌍 Environment set to: Development (dev)
✅ Firebase initialized for DEVELOPMENT
```

---

## 📊 Tech Stack

- **Framework:** Flutter 3.35.4
- **Language:** Dart 3.9.2
- **State Management:** Riverpod 3.0
- **Navigation:** GoRouter 16.2
- **UI:** Material Design 3 + Google Fonts
- **Animation:** flutter_animate 4.5
- **Backend:** Node.js + Express (Render)
- **Auth:** Firebase Auth
- **Database:** MongoDB (via backend)

---

## 📱 Pantallas Implementadas

### Estudiante (Student)
- ✅ **Home Screen** - Dashboard con acciones rápidas
- ✅ **Book Class Screen** - Reservar clases con profesores
- ✅ **My Bookings Screen** - Ver mis reservas
- ✅ **My Balance Screen** - Ver balance de pagos
- ✅ **Request Service Screen** - Solicitar servicios

### Profesor (Professor)
- ✅ **Professor Home Screen** - Dashboard del profesor
- ✅ **Create Schedule Screen** - Crear horarios disponibles
- ✅ **Manage Schedules Screen** - Gestionar horarios
- ✅ **Pricing Config Screen** - Configurar precios
- ✅ **Edit Profile Screen** - Editar perfil del profesor
- ✅ **Students List Screen** - Lista de estudiantes
- ✅ **Student Profile Screen** - Perfil del estudiante
- ✅ **Analytics Dashboard Screen** - Métricas y analytics

### Compartido
- ✅ **Login Screen** - Inicio de sesión
- ✅ **Register Screen** - Registro de usuarios
- ✅ **Theme Settings Screen** - Configurar tema

---

## 🔐 Flujo de Autenticación

```
1. Usuario inicia sesión (Google/Email) 
   ↓
2. Firebase genera token
   ↓
3. App envía token al backend: POST /api/auth/firebase/verify
   ↓
4. Backend verifica token y retorna usuario con rol
   ↓
5. GoRouter redirige según rol:
   - professor → /professor-home
   - student → /home
   ↓
6. App usa Firebase token para todas las requests
   (Header: Authorization: Bearer <token>)
```

---

## 🎯 Próximos Pasos

- [ ] Crear proyecto Firebase separado para desarrollo
- [ ] Configurar iOS schemes en Xcode
- [ ] Agregar CI/CD para builds nativos (Android/iOS)
- [ ] Implementar Firebase App Distribution
- [ ] Configurar signing para releases
- [ ] Agregar más tests unitarios y de integración
- [ ] Implementar offline mode
- [ ] Agregar notificaciones push

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en la consola
2. Verifica la configuración de ambientes
3. Asegúrate de que el backend esté ejecutándose
4. Consulta la documentación de [Flutter](https://flutter.dev/docs) y [Firebase](https://firebase.google.com/docs)

---

## 📄 Licencia

Privado - Tennis Management © 2025
