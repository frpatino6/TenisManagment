# 🚀 CI/CD Pipeline - Tennis Management

Este proyecto incluye una pipeline de CI/CD automatizada que despliega tanto el backend (Render) como el frontend (Firebase Hosting) cuando se hace merge a la rama `main`.

## 📋 Resumen

- **Backend**: Se despliega automáticamente a Render
- **Frontend**: Se despliega automáticamente a Firebase Hosting
- **Tests**: Se ejecutan en cada PR y push
- **Validación**: Linting, type checking, y builds antes del despliegue

## 🔧 Configuración Inicial

### 1. Secrets de GitHub

Ve a **Settings > Secrets and variables > Actions** en tu repositorio y agrega:

#### Para Render (Backend):
- `RENDER_API_KEY`: Tu API key de Render
- `RENDER_SERVICE_ID`: El ID de tu servicio en Render

#### Para Firebase (Frontend):
- `FIREBASE_SERVICE_ACCOUNT`: El JSON completo de la service account

### 2. Obtener RENDER_SERVICE_ID

1. Ve a [Render Dashboard](https://dashboard.render.com/)
2. Selecciona tu servicio `tennis-management-backend`
3. En la URL del servicio, copia el ID (ej: `srv-abc123def456`)

### 3. Obtener RENDER_API_KEY

1. Ve a [Render Dashboard](https://dashboard.render.com/)
2. Ve a **Account Settings > API Keys**
3. Crea una nueva API Key
4. Copia el valor

### 4. Obtener FIREBASE_SERVICE_ACCOUNT

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto `tennis-management-fcd54`
3. Ve a **Project Settings > Service Accounts**
4. Haz clic en **Generate new private key**
5. Descarga el archivo JSON
6. Copia todo el contenido del JSON

## 🎯 Cómo Funciona

### En Pull Requests:
```
┌─────────────────┐    ┌─────────────────┐
│   Backend       │    │   Frontend      │
│   Tests         │    │   Tests         │
│   ✅ Lint       │    │   ✅ Analyze    │
│   ✅ Type Check │    │   ✅ Tests      │
│   ✅ Build      │    │   ✅ Build      │
└─────────────────┘    └─────────────────┘
```

### En Push a Main:
```
┌─────────────────┐    ┌─────────────────┐
│   Backend       │    │   Frontend      │
│   Tests         │    │   Tests         │
│   ✅ Lint       │    │   ✅ Analyze    │
│   ✅ Type Check │    │   ✅ Tests      │
│   ✅ Build      │    │   ✅ Build      │
└─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Deploy to     │    │   Deploy to     │
│   Render        │    │   Firebase      │
└─────────────────┘    └─────────────────┘
```

## 📁 Archivos de Configuración

- `.github/workflows/ci-cd.yml` - Pipeline principal
- `.github/workflows/deploy-backend.yml` - Solo backend
- `.github/workflows/deploy-frontend.yml` - Solo frontend
- `render.yaml` - Configuración de Render
- `.github/CI-CD-SETUP.md` - Guía detallada de configuración

## 🔍 Monitoreo

### GitHub Actions
- Ve a: `https://github.com/[tu-usuario]/TenisManagment/actions`
- Aquí puedes ver el estado de todos los despliegues

### Render Dashboard
- Ve a: `https://dashboard.render.com/`
- Monitorea el estado del backend

### Firebase Console
- Ve a: `https://console.firebase.google.com/project/tennis-management-fcd54`
- Monitorea el estado del frontend

## 🛠️ Comandos Locales

Si quieres ejecutar los mismos tests localmente:

```bash
# Backend
cd backend
npm ci
npm run lint
npm run type-check
npm run build

# Frontend
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

## 🚨 Troubleshooting

### Error: "Render service not found"
- Verifica que `RENDER_SERVICE_ID` sea correcto
- Asegúrate de que el servicio exista en Render

### Error: "Firebase authentication failed"
- Verifica que `FIREBASE_SERVICE_ACCOUNT` contenga el JSON completo
- Asegúrate de que el proyecto Firebase sea correcto

### Error: "Build failed"
- Revisa los logs en GitHub Actions
- Ejecuta los comandos localmente para debuggear

## 📞 Soporte

Si tienes problemas con la configuración:
1. Revisa los logs en GitHub Actions
2. Verifica que todos los secrets estén configurados
3. Ejecuta los comandos localmente para debuggear
4. Consulta la documentación de [Render](https://render.com/docs) y [Firebase](https://firebase.google.com/docs)
