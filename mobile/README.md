# Tennis Management Mobile App

Aplicación móvil Flutter para el sistema de gestión de tenis.

## 🚀 Características

- **Autenticación con Google** via Firebase
- **Autenticación con email/contraseña** via Firebase
- **Integración completa** con el backend Node.js
- **UI moderna** y responsive
- **Manejo de estados** con Provider
- **Navegación** entre pantallas

## 📱 Pantallas implementadas

- **Login Screen** - Inicio de sesión
- **Register Screen** - Registro de usuarios
- **Home Screen** - Pantalla principal con acciones rápidas

## 🔧 Configuración

### 1. Dependencias instaladas

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
  http: ^1.1.0
  provider: ^6.1.1
  flutter_svg: ^2.0.9
  google_fonts: ^6.1.0
```

### 2. Configuración de Firebase

**IMPORTANTE:** Necesitas configurar Firebase para Android/iOS:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto "tennis-management-fcd54"
3. Agrega apps Android/iOS
4. Descarga los archivos de configuración:
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)
5. Actualiza `lib/firebase_options.dart` con las configuraciones reales

### 3. Backend URL

En `lib/services/auth_service.dart`, actualiza la URL del backend:

```dart
static const String _backendUrl = 'http://localhost:3000'; // Cambiar por tu URL
```

## 🏃‍♂️ Ejecutar la app

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release
```

## 📁 Estructura del proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── firebase_options.dart     # Configuración de Firebase
├── models/
│   └── user_model.dart      # Modelo de usuario
├── providers/
│   └── auth_provider.dart   # Provider de autenticación
├── screens/
│   ├── login_screen.dart    # Pantalla de login
│   ├── register_screen.dart # Pantalla de registro
│   └── home_screen.dart     # Pantalla principal
├── services/
│   └── auth_service.dart    # Servicio de autenticación
└── widgets/
    ├── custom_button.dart   # Botón personalizado
    └── custom_text_field.dart # Campo de texto personalizado
```

## 🔐 Flujo de autenticación

1. **Usuario inicia sesión** con Google o email/contraseña
2. **Firebase genera token** de autenticación
3. **App envía token** al backend via `/api/auth/firebase/verify`
4. **Backend verifica token** y genera JWT propio
5. **App usa JWT** para todas las requests posteriores

## 🎯 Próximos pasos

- [ ] Configurar Firebase para Android/iOS
- [ ] Implementar pantallas de funcionalidades específicas
- [ ] Agregar manejo de errores más robusto
- [ ] Implementar navegación con bottom navigation
- [ ] Agregar tests unitarios

## 🐛 Solución de problemas

### Error de Firebase
Si ves errores de Firebase, asegúrate de:
1. Configurar correctamente `firebase_options.dart`
2. Tener los archivos de configuración en las carpetas correctas
3. Habilitar Authentication en Firebase Console

### Error de conexión al backend
Si no puedes conectar al backend:
1. Verifica que el backend esté ejecutándose
2. Actualiza la URL en `auth_service.dart`
3. Verifica la configuración de CORS en el backend