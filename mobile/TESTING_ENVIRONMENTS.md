# 🧪 Guía de Prueba - Ambientes

Esta guía te ayudará a verificar que los ambientes estén funcionando correctamente.

---

## ✅ Checklist de Verificación

### 1. Preparación

- [ ] Flutter instalado y funcionando (`flutter doctor`)
- [ ] Backend local ejecutándose en `localhost:3000` (solo para dev)
- [ ] Emulador Android o dispositivo conectado

### 2. Verificar Configuración de Archivos

```bash
# Verificar que los archivos existan
ls lib/main_dev.dart
ls lib/main_prod.dart
ls lib/main_uat.dart
ls lib/core/config/environment.dart
ls lib/core/config/app_config.dart
ls scripts/run_dev.sh
ls scripts/run_prod.sh
```

### 3. Compilar el Proyecto

```bash
cd mobile
flutter pub get
flutter analyze
```

**Resultado esperado:** ✅ Sin errores

---

## 🧪 Prueba 1: Ambiente de Desarrollo

### Ejecutar

```bash
./scripts/run_dev.sh
```

O manualmente:

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### Verificar en los Logs

Deberías ver algo como:

```
🌍 Environment set to: Development (dev)
┌─────────────────────────────────────────────────
│ 🎯 APP CONFIGURATION
├─────────────────────────────────────────────────
│ Environment:        Development
│ App Name:          Tennis DEV
│ Package:           com.tennismanagement.tennis_management.dev
├─────────────────────────────────────────────────
│ Backend URL:       http://10.0.2.2:3000
│ API Base URL:      http://10.0.2.2:3000/api
│ Auth Base URL:     http://10.0.2.2:3000/api/auth
├─────────────────────────────────────────────────
│ Debug Logs:        true
│ Network Logs:      true
│ Analytics:         false
│ Crash Reporting:   false
├─────────────────────────────────────────────────
│ HTTP Timeout:      60s
│ Max Retries:       2
└─────────────────────────────────────────────────
✅ Firebase initialized for DEVELOPMENT
```

### Verificar en la App

1. **Nombre de la app en el dispositivo:** "Tennis DEV"
2. **Badge/Icono:** Debería tener indicador de desarrollo (si se configuró)
3. **Login:** Intenta iniciar sesión
4. **Backend:** Verifica que se conecte a tu backend local

### Verificar Requests

Si tu backend local está corriendo, deberías ver requests en:
```
http://10.0.2.2:3000/api/auth/firebase/verify
```

---

## 🧪 Prueba 2: Ambiente de Producción

### Ejecutar

```bash
./scripts/run_prod.sh
```

O manualmente:

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

### Verificar en los Logs

Deberías ver:

```
🌍 Environment set to: Production (prod)
┌─────────────────────────────────────────────────
│ 🎯 APP CONFIGURATION
├─────────────────────────────────────────────────
│ Environment:        Production
│ App Name:          Tennis Management
│ Package:           com.tennismanagement.tennis_management
├─────────────────────────────────────────────────
│ Backend URL:       https://tenismanagment.onrender.com
│ API Base URL:      https://tenismanagment.onrender.com/api
│ Auth Base URL:     https://tenismanagment.onrender.com/api/auth
├─────────────────────────────────────────────────
│ Debug Logs:        false
│ Network Logs:      false
│ Analytics:         true
│ Crash Reporting:   true
├─────────────────────────────────────────────────
│ HTTP Timeout:      30s
│ Max Retries:       3
└─────────────────────────────────────────────────
✅ Firebase initialized for PRODUCTION
```

### Verificar en la App

1. **Nombre de la app en el dispositivo:** "Tennis Management"
2. **Login:** Intenta iniciar sesión
3. **Backend:** Verifica que se conecte al backend en Render

---

## 🧪 Prueba 3: Ambiente de UAT (Pruebas de Aceptación)

### Ejecutar

```bash
# Aún no hay script sh, usar comando manual:
flutter run --flavor uat -t lib/main_uat.dart
```

### Verificar en los Logs

Deberías ver:

```
🌍 Environment set to: UAT (uat)
┌─────────────────────────────────────────────────
│ 🎯 APP CONFIGURATION
├─────────────────────────────────────────────────
│ Environment:        UAT
│ App Name:          Tennis UAT
│ Package:           com.tennismanagement.tennis_management.uat
├─────────────────────────────────────────────────
│ Backend URL:       https://tenismanagment.onrender.com
│ API Base URL:      https://tenismanagment.onrender.com/api
│ Auth Base URL:     https://tenismanagment.onrender.com/api/auth
├─────────────────────────────────────────────────
│ Debug Logs:        false
│ Network Logs:      false
│ Analytics:         false
│ Crash Reporting:   false
├─────────────────────────────────────────────────
│ HTTP Timeout:      30s
│ Max Retries:       3
└─────────────────────────────────────────────────
✅ Firebase initialized for UAT
```

### Verificar en la App

1. **Nombre de la app en el dispositivo:** "Tennis UAT"
2. **Login:** Intenta iniciar sesión (Usará BD de UAT)
3. **Backend:** Verifica que se conecte al backend en Render

---

## 🧪 Prueba 4: Ambas Apps Instaladas Simultáneamente

### Instalar ambas

```bash
# Construir e instalar DEV
./scripts/build_dev.sh apk
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# Construir e instalar PROD
./scripts/build_prod.sh apk
adb install build/app/outputs/flutter-apk/app-prod-release.apk
```

### Verificar

1. En el drawer de apps, deberías ver:
   - 🎾 Tennis DEV
   - 🎾 Tennis Management

2. Abre cada una y verifica:
   - Diferentes nombres
   - Se conectan a diferentes backends
   - Puedes usar ambas sin conflicto

---

## 🧪 Prueba 5: Switching entre Ambientes

### Sin rebuild

```bash
# Ejecutar DEV
flutter run --flavor dev -t lib/main_dev.dart

# Hot restart (R en la terminal)
# Debería mantener ambiente DEV

# Detener y ejecutar PROD
flutter run --flavor prod -t lib/main_prod.dart
```

---

## ❌ Problemas Comunes

### Error: "No se encontró el flavor"

```
Error: The value of the --flavor option must be one of: dev, prod
```

**Solución:** Asegúrate de usar `dev` o `prod` (minúsculas)

### Error: "Backend no responde" (DEV)

```
SocketException: Failed to connect to /10.0.2.2:3000
```

**Solución:**
1. Verifica que tu backend local esté corriendo
2. En emulador: usa `10.0.2.2`
3. En dispositivo físico: usa tu IP local (ej: `192.168.1.100`)

### Las apps se reemplazan entre sí

**Solución:** Esto significa que los package names son iguales. Verifica:
```kotlin
// En build.gradle.kts
create("dev") {
    applicationIdSuffix = ".dev"  // ← Debe estar presente
}
```

### El nombre de la app no cambia

**Solución:** Verifica que AndroidManifest.xml use:
```xml
android:label="@string/app_name"
```

---

## 🧪 Pruebas de Integración

Puedes ejecutar los tests de integración para verificar los flujos completos de la aplicación. Asegúrate de tener un emulador corriendo.

### 1. Test de Flujo de Reserva de Cancha (Booking Flow)

Verifica el flujo completo de reserva de cancha para un estudiante:
- Login
- Selección de Centro (Tenant)
- Selección de Cancha
- Selección de Fecha y Hora
- Confirmación

```bash
flutter test integration_test/booking_flow_test.dart --flavor dev
```

### 2. Test de Flujo de Reserva de Clase (Class Booking)

Verifica el flujo de reserva de clase con un profesor:
- Login
- Navegación a "Reservar Clase"
- Selección de Profesor (itera buscando horarios)
- Selección de Servicio y Horario
- Confirmación

```bash
flutter test integration_test/class_booking_test.dart --flavor dev
```

---

## ✅ Lista de Verificación Final

- [ ] Los logs muestran el ambiente correcto
- [ ] El nombre de la app es correcto (Tennis DEV / Tennis Management)
- [ ] Se conecta al backend correcto (local / Render)
- [ ] Puedo tener ambas apps instaladas simultáneamente
- [ ] Los timeouts son diferentes (60s dev, 30s prod)
- [ ] Los debug logs solo aparecen en DEV

---

## 📊 Comparación de Ambientes

| Característica | DEV | UAT | PROD |
|----------------|-----|-----|------|
| **Backend** | localhost:3000 | Render (UAT DB) | Render (Prod DB) |
| **App Name** | Tennis DEV | Tennis UAT | Tennis Management |
| **Package** | .dev suffix | .uat suffix | Normal |
| **Debug Logs** | ✅ Sí | ❌ No | ❌ No |
| **Timeout** | 60s | 30s | 30s |
| **Analytics** | ❌ No | ❌ No | ✅ Sí |
| **Crash Reporting** | ❌ No | ❌ No | ✅ Sí |

---

## 🎯 Siguiente Paso

Si todas las pruebas pasan, ¡estás listo para desarrollar! 

Usa ambiente **DEV** para desarrollo diario y **PROD** para testing final antes de releases.

---

## 📞 ¿Problemas?

Si encuentras problemas, revisa:
1. Los logs de la app
2. Los logs del backend
3. La configuración en `app_config.dart`
4. Este documento: `TESTING_ENVIRONMENTS.md`

