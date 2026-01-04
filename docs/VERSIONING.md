# 📋 Sistema de Versionamiento Profesional

Este proyecto implementa **Semantic Versioning (SemVer)** siguiendo los estándares más profesionales de la industria.

## 🎯 Estándar SemVer

### Formato: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Cambios incompatibles en la API
- **MINOR**: Nueva funcionalidad compatible hacia atrás
- **PATCH**: Correcciones de bugs compatibles hacia atrás
- **BUILD**: Número de build incremental

### Ejemplos:
- `1.0.0+1` - Primera versión estable
- `1.0.1+2` - Corrección de bug
- `1.1.0+3` - Nueva funcionalidad
- `2.0.0+4` - Cambio mayor (breaking changes)
- `1.2.0-alpha.1+5` - Versión pre-release

## 🚀 Uso del Script de Versionamiento

### Comandos Disponibles:

```bash
# Incrementar versión patch (1.2.0 -> 1.2.1)
node scripts/R

# Incrementar versión minor (1.2.0 -> 1.3.0)
node scripts/version.js minor

# Incrementar versión major (1.2.0 -> 2.0.0)
node scripts/version.js major

# Crear versión pre-release (1.2.0 -> 1.2.1-alpha.1)
node scripts/version.js prerelease

# Crear versión beta (1.2.0 -> 1.2.1-beta.1)
node scripts/version.js prerelease --preid=beta

# Crear versión release candidate (1.2.0 -> 1.2.1-rc.1)
node scripts/version.js prerelease --preid=rc
```

## 📱 Versiones Actuales

### Frontend (Flutter)
- **Archivo**: `mobile/pubspec.yaml`
- **Versión actual**: `1.2.1+13`
- **Formato**: `version: MAJOR.MINOR.PATCH+BUILD`

### Backend (Node.js)
- **Archivo**: `backend/package.json`
- **Versión actual**: `1.2.1`
- **Formato**: `"version": "MAJOR.MINOR.PATCH"`

## 🎨 Visualización en la App

### Widgets Disponibles:

#### `VersionWidget`
```dart
// Versión simple
VersionWidget()

// Con número de build
VersionWidget(showBuildNumber: true)

// Información completa
VersionWidget(showFullInfo: true)
```

#### `VersionBadge`
```dart
// Badge compacto
VersionBadge()

// Con número de build
VersionBadge(showBuildNumber: true)
```

### Ubicaciones en la App:
- **Home del Estudiante**: Badge al final de la pantalla
- **Home del Profesor**: Badge al final de la pantalla

## 🔄 Flujo de Trabajo

### 1. Desarrollo
```bash
# Trabajar en features
git checkout -b feature/nueva-funcionalidad
# ... hacer cambios ...
```

### 2. Pre-release (Opcional)
```bash
# Crear versión alpha para testing
node scripts/version.js prerelease --preid=alpha
git add .
git commit -m "chore: bump version to 1.2.1-alpha.1"
git push
```

### 3. Release
```bash
# Incrementar versión según el tipo de cambio
node scripts/version.js patch  # Para bugs
node scripts/version.js minor  # Para features
node scripts/version.js major  # Para breaking changes

# Commit y push
git add .
git commit -m "chore: bump version to 1.2.1"
git push
```

### 4. Tag de Release (Recomendado)
```bash
# Crear tag de release
git tag -a v1.2.1 -m "Release version 1.2.1"
git push origin v1.2.1
```

## 📊 Convenciones de Commits

### Tipos de Cambios:
- `feat:` - Nueva funcionalidad (incrementa MINOR)
- `fix:` - Corrección de bug (incrementa PATCH)
- `docs:` - Cambios en documentación
- `style:` - Cambios de formato, espacios, etc.
- `refactor:` - Refactorización de código
- `test:` - Agregar o modificar tests
- `chore:` - Cambios en build, dependencias, etc.

### Ejemplos:
```bash
git commit -m "feat: agregar sistema de notificaciones"
git commit -m "fix: corregir error en login de usuarios"
git commit -m "chore: actualizar dependencias de Flutter"
```

## 🎯 Beneficios del Sistema

### ✅ Para Desarrolladores:
- **Claridad**: Fácil identificación del tipo de cambio
- **Automatización**: Scripts para incrementar versiones
- **Consistencia**: Mismo formato en frontend y backend

### ✅ Para Usuarios:
- **Transparencia**: Versión visible en la app
- **Trazabilidad**: Historial de versiones en Git
- **Expectativas**: SemVer comunica compatibilidad

### ✅ Para Producción:
- **Rollback**: Fácil identificación de versiones
- **Deployment**: Control de versiones en CI/CD
- **Monitoreo**: Tracking de versiones en logs

## 🔧 Configuración Técnica

### Archivos Modificados:
- `mobile/pubspec.yaml` - Versión del frontend
- `backend/package.json` - Versión del backend
- `scripts/version.js` - Script de versionamiento
- `mobile/lib/core/services/version_service.dart` - Servicio de versiones
- `mobile/lib/core/widgets/version_widget.dart` - Widgets de versión

### Dependencias:
- `package_info_plus` - Obtener información de la app
- `google_fonts` - Tipografía para widgets
- `flutter_animate` - Animaciones

## 📈 Próximas Mejoras

- [ ] Integración con CI/CD para versiones automáticas
- [ ] Changelog automático basado en commits
- [ ] Notificaciones de nuevas versiones
- [ ] Métricas de adopción de versiones
- [ ] Rollback automático en caso de errores

---

**📝 Nota**: Este sistema sigue las mejores prácticas de la industria y es compatible con herramientas como GitHub Releases, npm, y Flutter pub.
