# 📱 Configuración de iOS Schemes

## ⚠️ Configuración Manual Requerida

La configuración de flavors en iOS requiere Xcode y debe hacerse manualmente.

---

## 🎯 Objetivo

Crear dos schemes en Xcode:
- **Development** → Para desarrollo local
- **Production** → Para producción

---

## 📝 Pasos de Configuración

### 1. Abrir Proyecto en Xcode

```bash
cd mobile/ios
open Runner.xcworkspace
```

### 2. Duplicar Scheme (Development)

1. En Xcode, ve a: **Product > Scheme > Manage Schemes...**
2. Selecciona el scheme **Runner**
3. Haz clic en el botón **⚙️** (gear) → **Duplicate**
4. Nombra el nuevo scheme: **Development**
5. ✅ Asegúrate de marcar **Shared**
6. Click **Close**

### 3. Duplicar Scheme (Production)

1. Repite el proceso anterior
2. Nombra este scheme: **Production**
3. ✅ Asegúrate de marcar **Shared**

### 4. Configurar Build Configuration

#### Para Development Scheme:
1. Edita el scheme **Development**: **Product > Scheme > Edit Scheme...**
2. En cada fase (Run, Test, Profile, Analyze, Archive):
   - Cambia **Build Configuration** a **Debug**
3. En la fase **Archive**:
   - Cambia a **Release** (para builds de distribución)

#### Para Production Scheme:
1. Edita el scheme **Production**: **Product > Scheme > Edit Scheme...**
2. En cada fase (Run, Test, Profile, Analyze, Archive):
   - Usa **Debug** para Run y Test
   - Usa **Release** para Profile, Analyze y Archive

### 5. Configurar Info.plist (Opcional)

Si quieres nombres de app diferentes en iOS:

1. Crea dos archivos Info.plist:
   - `ios/Runner/Info-Dev.plist`
   - `ios/Runner/Info-Prod.plist`

2. En cada archivo, cambia:
```xml
<key>CFBundleDisplayName</key>
<string>Tennis DEV</string>  <!-- o "Tennis Management" para prod -->
```

3. En Xcode Build Settings, configura:
   - Busca **Info.plist File**
   - Para Development: usa `Runner/Info-Dev.plist`
   - Para Production: usa `Runner/Info.plist`

---

## 🚀 Comandos de Ejecución

Una vez configurado, puedes usar:

```bash
# Development
flutter run --flavor dev -t lib/main_dev.dart

# Production  
flutter run --flavor prod -t lib/main_prod.dart
```

**NOTA:** En iOS, los flavors se mapean a los schemes automáticamente.

---

## 🔧 Verificación

Para verificar que está funcionando:

1. Ejecuta con flavor dev:
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

2. Revisa los logs, deberías ver:
```
🌍 Environment set to: Development (dev)
✅ Firebase initialized for DEVELOPMENT
```

3. En la app, verifica que:
   - Se conecta al backend local (10.0.2.2:3000)
   - El nombre de la app es "Tennis DEV"

---

## 📚 Referencias

- [Flutter iOS Setup](https://flutter.dev/docs/deployment/ios)
- [Xcode Schemes Guide](https://developer.apple.com/library/archive/featuredarticles/XcodeConcepts/Concept-Schemes.html)
- [iOS Build Configurations](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)

---

## ⏭️ Siguiente Paso

Por ahora, puedes desarrollar solo con Android. Cuando necesites iOS:
1. Sigue esta guía
2. Configura los schemes
3. Prueba en simulador iOS

