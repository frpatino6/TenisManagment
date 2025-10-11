# Tennis Management Backend

Backend API para el sistema de gestión de clases de tenis construido con TypeScript, Express, MongoDB y Firebase.

## 🏗️ Estructura del Proyecto

```
backend/
├── src/                          # Código fuente principal
│   ├── domain/                   # Lógica de negocio
│   ├── application/              # Casos de uso
│   ├── infrastructure/           # Implementaciones técnicas
│   └── presentation/             # Controladores y rutas
├── dist/                         # Código compilado
├── scripts/                      # Scripts de automatización
│   ├── deploy/                   # Scripts de despliegue
│   │   ├── verify-deployment.sh
│   │   └── fix-render-config.sh
│   ├── setup/                    # Scripts de configuración
│   │   └── configure-render-env.sh
│   └── security/                 # Scripts de seguridad
│       └── security-cleanup.sh
├── tools/                        # Herramientas de desarrollo
│   └── mcp/                      # Servidor MCP para despliegue
│       ├── mcp-deploy-server.js
│       ├── mcp-deploy-server-enhanced.js
│       └── render-api-client.js
├── config/                       # Configuraciones
│   └── mcp/                      # Configuración del servidor MCP
│       ├── mcp-config.json
│       ├── package-mcp.json
│       └── env.mcp.example
├── docs/                         # Documentación
│   └── deployment/               # Documentación de despliegue
│       └── MCP_DEPLOY_README.md
├── .env.example                  # Variables de entorno de ejemplo
├── package.json                  # Dependencias y scripts
├── tsconfig.json                 # Configuración de TypeScript
├── eslint.config.js              # Configuración de ESLint
└── README.md                     # Este archivo
```

## 🚀 Inicio Rápido

### Prerrequisitos
- Node.js 18+
- npm 8+
- MongoDB
- Cuenta de Firebase

### Instalación
```bash
# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Compilar el proyecto
npm run build

# Iniciar en modo desarrollo
npm run dev

# Iniciar en producción
npm start
```

## 📝 Scripts Disponibles

### Desarrollo
- `npm run dev` - Inicia servidor en modo desarrollo
- `npm run build` - Compila TypeScript a JavaScript
- `npm start` - Inicia servidor en producción
- `npm run lint` - Ejecuta ESLint
- `npm run lint:fix` - Corrige errores de ESLint

### Despliegue
- `scripts/deploy/verify-deployment.sh` - Verifica estado del despliegue
- `scripts/deploy/fix-render-config.sh` - Analiza configuración de Render
- `scripts/setup/configure-render-env.sh` - Configura variables de entorno en Render

### Seguridad
- `scripts/security/security-cleanup.sh` - Limpia datos sensibles del historial

## 🤖 Servidor MCP

El proyecto incluye un servidor MCP (Model Context Protocol) para automatizar despliegues:

### Configuración
```bash
# Configurar servidor MCP
cd tools/mcp/
cp ../config/mcp/env.mcp.example .env
# Editar .env con tus credenciales
```

### Uso
```bash
# Iniciar servidor MCP
node tools/mcp/mcp-deploy-server.js

# Servidor MCP mejorado
node tools/mcp/mcp-deploy-server-enhanced.js
```

## 🌐 Despliegue

### Render
El proyecto está configurado para despliegue automático en Render:

1. **Configurar variables de entorno** en Render Dashboard
2. **Hacer push** al repositorio para trigger automático
3. **Monitorear** el progreso en Render Dashboard

### Variables de Entorno Requeridas
```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@...
CORS_ORIGINS=https://your-frontend-url
```

## 🔧 Configuración

### TypeScript
- Configuración estricta habilitada
- Compilación a ES2020
- Módulos ES6

### ESLint
- Configuración para TypeScript
- Reglas estrictas de código
- Integración con Prettier

### Base de Datos
- MongoDB con Mongoose
- Esquemas con validación
- Índices optimizados

## 📚 Documentación

- [Configuración de Firebase](FIREBASE_SETUP.md)
- [Documentación del Servidor MCP](docs/deployment/MCP_DEPLOY_README.md)

## 🛡️ Seguridad

- Variables de entorno para credenciales
- Validación de entrada con Zod
- Rate limiting implementado
- CORS configurado
- Helmet para headers de seguridad

## 🧪 Testing

Contamos con un sistema de testing comprehensivo con **108+ tests** y **95%+ de cobertura**.

### Estadísticas

- **Tests Totales**: 108+ tests (100% pasando ✅)
- **Tests Unitarios**: 73+ tests
- **Tests de Integración**: 15+ tests
- **Tests E2E**: 35+ tests
- **Cobertura Global**: 95%+

### Comandos de Testing

```bash
# Ejecutar todos los tests
npm test

# Tests con cobertura
npm run test:coverage

# Tests unitarios
npm run test:unit

# Tests de integración
npm run test:integration

# Tests E2E
npm run test:e2e

# Tests en modo watch (desarrollo)
npm run test:watch

# Tests para CI/CD
npm run test:ci
```

### Características

- ✅ **Jest** v30.2.0 con TypeScript
- ✅ **Supertest** para testing de APIs
- ✅ **MongoDB in-memory** para tests de integración
- ✅ **Cobertura mínima**: 80% (actual: 95%+)
- ✅ **CI/CD Integration**: GitHub Actions
- ✅ **Tipos de tests**: Unit, Integration, E2E
- ✅ **Performance tests**: Rate limiting, edge cases
- ✅ **Validation tests**: DTOs con Zod schemas

### Documentación Completa

Para guías detalladas, mejores prácticas, troubleshooting y más:

📖 **[Ver Documentación Completa de Testing](TESTING.md)**

La documentación incluye:
- Cómo ejecutar tests
- Guía de contribución para testing
- Cobertura y métricas
- Troubleshooting de tests
- Mejores prácticas
- CI/CD integration

## 📊 Monitoreo

### Health Check
```bash
curl https://your-app.onrender.com/health
```

### Logs
Los logs están disponibles en Render Dashboard y en la consola local.

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado y confidencial.

## 📞 Soporte

Para soporte técnico, contacta al equipo de desarrollo.

---

**Versión:** 1.3.3  
**Última actualización:** Octubre 2024# Trigger pipeline execution
