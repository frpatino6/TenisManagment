# 🎾 Tennis Management System

Sistema completo de gestión de tenis para profesores y estudiantes. Incluye reservas de clases, gestión de horarios, seguimiento de pagos y administración de servicios.

## 🌐 **Aplicación en Producción**

- **🌐 Frontend Web**: https://tennis-management-fcd54.web.app
- **🔧 Backend API**: https://tenismanagment.onrender.com
- **📊 Health Check**: https://tenismanagment.onrender.com/health

## 📁 **Estructura del Proyecto**

```
TenisManagment/
├── backend/          # Backend Node.js con TypeScript
│   ├── src/
│   │   ├── application/     # Casos de uso y controladores
│   │   ├── domain/         # Entidades y repositorios
│   │   ├── infrastructure/ # Base de datos y servicios externos
│   │   └── presentation/   # Rutas y servidor Express
│   ├── package.json
│   ├── tsconfig.json
│   └── render.yaml         # Configuración para Render
├── mobile/           # Aplicación Flutter (Web + Móvil)
│   ├── lib/
│   │   ├── core/           # Configuración y widgets base
│   │   ├── features/       # Módulos de funcionalidades
│   │   └── main.dart
│   ├── pubspec.yaml
│   ├── firebase.json       # Configuración Firebase Hosting
│   └── .firebaserc
└── README.md
```

## 🚀 **Características Principales**

### 👨‍🏫 **Dashboard de Profesor**
- ✅ **Gestión de horarios**: Crear, editar y bloquear horarios
- ✅ **Panel de estudiantes**: Ver estudiantes y sus reservas
- ✅ **Sistema de ganancias**: Seguimiento de ingresos mensuales
- ✅ **Configuración de precios**: Precios personalizables por servicio
- ✅ **Gestión de clases**: Completar/cancelar clases con pagos
- ✅ **Widget "Horarios hoy"**: Vista rápida del día actual

### 👨‍🎓 **Dashboard de Estudiante**
- ✅ **Reserva de clases**: Selección de profesor y horario
- ✅ **Tipos de servicio**: Clase individual, grupal o alquiler de cancha
- ✅ **Actividades recientes**: Historial de reservas
- ✅ **Precios dinámicos**: Mostrar precios según el profesor

### 🔧 **Sistema Técnico**
- ✅ **Configuración por ambientes**: Automática sin hardcodeo
- ✅ **Autenticación Firebase**: Google Sign-In + Email/Password
- ✅ **Sistema de pagos**: Registro de pagos y penalizaciones
- ✅ **Gestión de reservas**: Estados (pendiente, confirmado, cancelado, completado)

## 🏗️ **Arquitectura**

### **Backend (Node.js + TypeScript)**
- **🏛️ Arquitectura hexagonal** (Clean Architecture)
- **🔐 Autenticación dual**: JWT + Firebase Admin SDK
- **🗄️ Base de datos**: MongoDB con Mongoose
- **🛡️ Seguridad**: Helmet, CORS, Rate Limiting
- **✅ Validación**: Zod para validación de datos
- **💉 Inyección de dependencias**: Inversify
- **📊 Logging**: Sistema de logs estructurado

### **Frontend (Flutter)**
- **📱 Multiplataforma**: Web, Android, iOS
- **🎨 UI moderna**: Material Design 3
- **🔄 State Management**: Riverpod
- **🌐 Configuración inteligente**: Detección automática de ambiente
- **🔐 Autenticación**: Firebase Auth + Google Sign-In
- **📡 HTTP Client**: Comunicación con API REST

## 🔧 **Tecnologías Utilizadas**

### **Backend**
- **Node.js 18.20.8** + **TypeScript**
- **Express.js** - Framework web
- **MongoDB** + **Mongoose** - Base de datos
- **Firebase Admin SDK** - Autenticación
- **JWT** - Tokens de autenticación
- **bcryptjs** - Hash de contraseñas
- **Inversify** - Inyección de dependencias
- **Zod** - Validación de esquemas
- **Helmet, CORS, express-rate-limit** - Seguridad

### **Frontend**
- **Flutter 3.35.4** + **Dart 3.9.2**
- **Firebase Core & Auth** - Autenticación
- **Google Sign-In** - Login con Google
- **Riverpod** - Gestión de estado
- **HTTP** - Cliente HTTP
- **Material Design 3** - UI/UX

### **Despliegue**
- **Firebase Hosting** - Frontend web
- **Render** - Backend API
- **MongoDB Atlas** - Base de datos en la nube

## 📋 **Funcionalidades Implementadas**

### **🔐 Autenticación**
- ✅ Login con Google
- ✅ Registro/Login con email y contraseña
- ✅ Gestión de sesiones
- ✅ Protección de rutas

### **👨‍🏫 Gestión de Profesores**
- ✅ Crear y gestionar horarios
- ✅ Configurar precios personalizados
- ✅ Ver estudiantes y sus reservas
- ✅ Completar/cancelar clases
- ✅ Registrar pagos y penalizaciones
- ✅ Panel de ganancias mensuales

### **👨‍🎓 Gestión de Estudiantes**
- ✅ Ver profesores disponibles
- ✅ Reservar clases por tipo de servicio
- ✅ Ver actividades recientes
- ✅ Historial de reservas

### **💰 Sistema de Pagos**
- ✅ Precios base configurables
- ✅ Precios personalizados por profesor
- ✅ Registro de pagos por clase
- ✅ Sistema de penalizaciones
- ✅ Cálculo automático de ganancias

### **📅 Gestión de Horarios**
- ✅ Creación de horarios por rangos
- ✅ Generación automática de slots
- ✅ Bloqueo de horarios específicos
- ✅ Estados de reserva (disponible, reservado, completado)

## 🚀 **Cómo Ejecutar Localmente**

### **Prerrequisitos**
- Node.js 18.20.8+
- Flutter 3.35.4+
- MongoDB (local o Atlas)
- Cuenta de Firebase

### **Backend**
```bash
cd backend
npm install
npm run dev
```
El backend estará disponible en `http://localhost:3000`

### **Frontend**
```bash
cd mobile
flutter pub get
flutter run -d chrome  # Para web
# o
flutter run            # Para móvil
```

## 🚀 **Cómo Desplegar a Producción**

### **Frontend (Firebase Hosting)**

#### **1. Instalar Firebase CLI**
```bash
npm install -g firebase-tools
```

#### **2. Login a Firebase**
```bash
firebase login
```

#### **3. Build y Deploy**
```bash
cd mobile
flutter build web --release
firebase deploy --only hosting
```

#### **4. Verificar Despliegue**
- La aplicación estará disponible en: https://tennis-management-fcd54.web.app
- Firebase Console: https://console.firebase.google.com/project/tennis-management-fcd54/overview

### **Backend (Render)**

#### **1. Configurar en Render Dashboard**
1. Ve a [render.com](https://render.com)
2. **"New Project"** → **"Web Service"**
3. Conecta tu repositorio GitHub
4. Configura:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`

#### **2. Variables de Entorno en Render**
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

#### **3. Deploy Automático**
- Render detecta automáticamente los cambios en `main`
- Cada push a `main` genera un nuevo deploy
- El backend estará disponible en: https://tenismanagment.onrender.com

### **Comandos de Deploy Rápido**

#### **Deploy completo (Frontend + Backend)**
```bash
# 1. Actualizar frontend
cd mobile
flutter build web --release
firebase deploy --only hosting

# 2. Backend se actualiza automáticamente con git push
cd ../backend
git add .
git commit -m "feat: New feature"
git push origin main
```

#### **Solo Frontend**
```bash
cd mobile
flutter build web --release
firebase deploy --only hosting
```

#### **Solo Backend**
```bash
cd backend
git add .
git commit -m "fix: Backend update"
git push origin main
# Render detecta el cambio y hace deploy automático
```

## 🌍 **Configuración por Ambientes**

El sistema detecta automáticamente el ambiente:

### **🌐 Web**
- **Producción**: `tennis-management-fcd54.web.app` → Render API
- **Desarrollo**: `localhost:8080` → Render API
- **Local con IP**: `192.168.x.x:3000` → IP local

### **📱 Móvil**
- **Debug**: IP local del backend
- **Release**: Render API (producción)

## 🔐 **Variables de Entorno**

### **Backend (Render)**
```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=tennis-management-fcd54
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@tennis-management-fcd54.iam.gserviceaccount.com
CORS_ORIGINS=https://tennis-management-fcd54.web.app
```

## 📊 **Endpoints de la API**

### **Autenticación**
- `POST /api/auth/firebase/login` - Login con Firebase
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/login` - Login con email/contraseña

### **Profesor**
- `GET /api/professor-dashboard/info` - Información del profesor
- `GET /api/professor-dashboard/schedules` - Horarios del profesor
- `POST /api/professor-dashboard/schedules` - Crear horario
- `PUT /api/professor-dashboard/schedules/:id/complete` - Completar clase
- `PUT /api/professor-dashboard/schedules/:id/cancel-booking` - Cancelar reserva

### **Estudiante**
- `GET /api/student-dashboard/recent-activities` - Actividades recientes
- `GET /api/student-dashboard/available-schedules` - Horarios disponibles
- `POST /api/student-dashboard/book-lesson` - Reservar clase

### **Precios**
- `GET /api/pricing/my-pricing` - Precios del profesor
- `PUT /api/pricing/my-pricing` - Actualizar precios
- `DELETE /api/pricing/my-pricing` - Resetear precios

## 🗄️ **Modelos de Base de Datos**

### **Usuarios**
- **Student**: Información del estudiante
- **Professor**: Información del profesor + precios personalizados

### **Reservas y Horarios**
- **Schedule**: Horarios disponibles del profesor
- **Booking**: Reservas de estudiantes con tipo de servicio y precio

### **Pagos**
- **Payment**: Registro de pagos y penalizaciones
- **SystemConfig**: Precios base del sistema

## 🎯 **Próximos Pasos**

### **Funcionalidades Adicionales**
- [ ] Notificaciones push
- [ ] Sistema de mensajería
- [ ] Reportes avanzados
- [ ] Integración con calendarios
- [ ] Sistema de reviews/calificaciones

### **Mejoras Técnicas**
- [ ] Tests unitarios y de integración
- [ ] CI/CD con GitHub Actions
- [ ] Monitoreo y analytics
- [ ] Optimización de performance
- [ ] PWA (Progressive Web App)

### **Despliegue**
- [ ] Dominio personalizado
- [ ] SSL personalizado
- [ ] CDN para assets
- [ ] Backup automático de BD

## 📈 **Estado del Proyecto**

- **✅ Backend**: 100% funcional y desplegado
- **✅ Frontend Web**: 100% funcional y desplegado
- **✅ Base de datos**: Configurada y funcionando
- **✅ Autenticación**: Completamente implementada
- **✅ Sistema de pagos**: Funcional
- **✅ Gestión de horarios**: Completa
- **✅ Configuración por ambientes**: Implementada

## 🤝 **Contribución**

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 **Licencia**

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 **Desarrollado por**

**Fernando Patiño** - [GitHub](https://github.com/frpatino6)

---

## 🎾 **¡Sistema de Gestión de Tenis Completamente Funcional!**

**Frontend**: https://tennis-management-fcd54.web.app  
**Backend**: https://tenismanagment.onrender.com