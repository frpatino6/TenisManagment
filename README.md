# Tennis Management System

Sistema completo de gestión de tenis con backend Node.js y aplicación móvil Flutter.

## 📁 Estructura del proyecto

```
TenisManagment/
├── backend/          # Backend Node.js con TypeScript
│   ├── src/
│   ├── package.json
│   └── ...
├── mobile/           # Aplicación móvil Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
└── README.md
```

## 🚀 Características

### Backend (Node.js + TypeScript)
- **Arquitectura hexagonal** (Clean Architecture)
- **Autenticación JWT** + Firebase Auth
- **Base de datos MongoDB** con Mongoose
- **API REST** completa
- **Dependency Injection** con Inversify
- **Validación** con Zod
- **Seguridad** con Helmet, CORS, Rate Limiting

### Mobile (Flutter)
- **Autenticación con Google** via Firebase
- **Autenticación con email/contraseña** via Firebase
- **Integración completa** con el backend
- **UI moderna** y responsive
- **Manejo de estados** con Provider

## 🔧 Tecnologías utilizadas

### Backend
- Node.js 18.20.8
- TypeScript
- Express.js
- MongoDB + Mongoose
- Firebase Admin SDK
- JWT (jsonwebtoken)
- bcryptjs
- Inversify (DI)
- Zod (validación)
- Helmet, CORS, express-rate-limit

### Mobile
- Flutter 3.35.4
- Dart 3.9.2
- Firebase Core & Auth
- Google Sign-In
- Provider (state management)
- HTTP (requests)
- Google Fonts

## 📋 Funcionalidades implementadas

### Backend
- ✅ **Autenticación completa** (JWT + Firebase)
- ✅ **CRUD de usuarios** (Estudiantes y Profesores)
- ✅ **Gestión de horarios** y disponibilidad
- ✅ **Sistema de reservas**
- ✅ **Gestión de pagos**
- ✅ **Servicios adicionales**
- ✅ **Reportes de ingresos**
- ✅ **19 endpoints** funcionando

### Mobile
- ✅ **Pantallas de login/registro**
- ✅ **Autenticación con Google**
- ✅ **Autenticación con email/contraseña**
- ✅ **Integración con backend**
- ✅ **UI moderna** y responsive
- ✅ **Navegación** entre pantallas

## 🚀 Cómo ejecutar

### Backend
```bash
cd backend
npm install
npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## 🔐 Configuración de Firebase

1. **Backend:** Ya configurado con credenciales reales
2. **Mobile:** Necesita configuración adicional para Android/iOS

Ver documentación específica en cada carpeta.

## 📊 Estado del proyecto

- **Backend:** ✅ 100% funcional
- **Mobile:** ✅ 80% funcional (falta configuración Firebase móvil)
- **Integración:** ✅ 100% funcional

## 🎯 Próximos pasos

1. Configurar Firebase para Android/iOS en mobile
2. Implementar funcionalidades específicas en mobile
3. Agregar tests
4. Deploy a producción
 Full-stack tennis management system for coaches and students. Features scheduling, court booking, payment tracking, and service management. Built with Node.js/TypeScript backend, Flutter frontend, and MongoDB.
