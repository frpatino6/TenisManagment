# CI/CD Pipeline Setup

Este proyecto incluye una pipeline de CI/CD automatizada que despliega tanto el backend (Render) como el frontend (Firebase Hosting) cuando se hace merge a la rama `main`.

## 🔧 Configuración de Secrets

Para que la pipeline funcione correctamente, necesitas configurar los siguientes secrets en GitHub:

### 1. Secrets para Render (Backend)

Ve a **Settings > Secrets and variables > Actions** en tu repositorio de GitHub y agrega:

#### `RENDER_API_KEY`
- Ve a [Render Dashboard](https://dashboard.render.com/)
- Ve a **Account Settings > API Keys**
- Crea una nueva API Key
- Copia el valor y agrégalo como secret

#### `RENDER_SERVICE_ID`
- Ve a tu servicio en Render Dashboard
- En la URL del servicio, copia el ID (ej: `srv-abc123def456`)
- Agrégalo como secret

### 2. Secrets para Firebase (Frontend)

#### `FIREBASE_SERVICE_ACCOUNT`
- Ve a [Firebase Console](https://console.firebase.google.com/)
- Selecciona tu proyecto `tennis-management-fcd54`
- Ve a **Project Settings > Service Accounts**
- Haz clic en **Generate new private key**
- Descarga el archivo JSON
- Copia todo el contenido del JSON y agrégalo como secret

## 🚀 Cómo Funciona

### En Pull Requests:
- ✅ Ejecuta tests del backend (linting, type checking, build)
- ✅ Ejecuta tests del frontend (analyze, tests, build)
- ❌ **NO** despliega (solo valida que todo funcione)

### En Push a Main:
- ✅ Ejecuta todos los tests
- ✅ Despliega backend a Render
- ✅ Despliega frontend a Firebase Hosting

## 📋 Workflows Incluidos

1. **`ci-cd.yml`** - Pipeline principal (recomendado)
2. **`deploy-backend.yml`** - Solo backend
3. **`deploy-frontend.yml`** - Solo frontend

## 🔍 Monitoreo

Puedes ver el estado de los despliegues en:
- **GitHub Actions**: https://github.com/[tu-usuario]/TenisManagment/actions
- **Render Dashboard**: https://dashboard.render.com/
- **Firebase Console**: https://console.firebase.google.com/project/tennis-management-fcd54

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
