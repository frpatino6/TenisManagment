# Tennis Management Backend

Backend API para el sistema de gestión de tenis.

## 🚀 Despliegue en Render

### Variables de Entorno Requeridas

```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/tennis-management?retryWrites=true&w=majority
JWT_SECRET=your-super-secret-jwt-key-here
FIREBASE_PROJECT_ID=tennis-management-fcd54
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tennis-management-fcd54.iam.gserviceaccount.com
CORS_ORIGINS=https://tennis-management-fcd54.web.app
```

### Comandos de Render

- **Build**: `npm run build`
- **Start**: `npm start`
- **Health Check**: `/health`

### Estructura del Proyecto

```
src/
├── application/          # Casos de uso y controladores
├── domain/              # Entidades y repositorios
├── infrastructure/      # Base de datos, servicios externos
└── presentation/        # Rutas y servidor Express
```

### Endpoints Principales

- `GET /health` - Health check
- `POST /api/auth/firebase/login` - Autenticación Firebase
- `GET /api/professor-dashboard/*` - Dashboard del profesor
- `GET /api/student-dashboard/*` - Dashboard del estudiante