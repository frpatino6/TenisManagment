#!/usr/bin/env node

/**
 * Script para crear épicas y historias de testing en Linear
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Definición de las 7 épicas de testing
const testingEpics = [
  {
    name: 'Testing - Configuración Base',
    description: 'Establecer la infraestructura base para testing unitario, incluyendo configuración de Jest, dependencias de testing y utilidades base.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - Capa Domain',
    description: 'Implementar testing unitario completo para todas las entidades y casos de uso del dominio de negocio.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - Capa Application',
    description: 'Implementar testing unitario para controladores, middleware y DTOs de la capa de aplicación.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - Capa Infrastructure',
    description: 'Implementar testing unitario para servicios, repositorios y configuraciones de la capa de infraestructura.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - Integración',
    description: 'Implementar testing de integración para flujos completos entre capas y sistemas.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - End-to-End',
    description: 'Implementar testing E2E para validar el comportamiento completo de la API.',
    state: 'planned',
    priority: 1
  },
  {
    name: 'Testing - CI/CD y Documentación',
    description: 'Configurar integración continua y documentar todo el sistema de testing.',
    state: 'planned',
    priority: 1
  }
];

// Definición de las 22 historias de testing
const testingStories = [
  // ÉPICA 1: Configuración Base
  {
    title: 'TS-001: Setup del Entorno de Testing',
    description: `## Descripción

Configurar Jest con TypeScript para testing unitario del proyecto Tennis Management Backend.

## Criterios de Aceptación

### Scenario: Configuración de Jest
### Given desarrollador
### When configura Jest con TypeScript
### Then debe poder ejecutar tests unitarios
### And debe tener soporte completo para TypeScript

### Scenario: Dependencias de Testing
### Given proyecto sin dependencias de testing
### When instala dependencias necesarias
### Then debe tener Jest, ts-jest, supertest, mongodb-memory-server
### And debe tener tipos de TypeScript para testing

### Scenario: Scripts de Testing
### Given configuración de Jest completada
### When ejecuta scripts de testing
### Then debe poder ejecutar tests unitarios, integración y E2E
### And debe generar reportes de cobertura

## Definition of Done

- [ ] Instalar dependencias de testing (Jest, ts-jest, supertest, etc.)
- [ ] Configurar Jest con soporte para TypeScript
- [ ] Configurar scripts de testing en package.json
- [ ] Crear configuración para diferentes tipos de test (unit, integration, e2e)
- [ ] Configurar MongoDB Memory Server para tests
- [ ] Documentar comandos de testing

## Story Points: 3 | Priority: P0 | Sprint: 1`,
    estimate: 3,
    priority: 1,
    labels: ['testing', 'infrastructure', 'setup'],
    epic: 'Testing - Configuración Base'
  },
  {
    title: 'TS-002: Utilidades y Helpers Base',
    description: `## Descripción

Crear factories y helpers para testing que faciliten la creación de datos de prueba y mocks.

## Criterios de Aceptación

### Scenario: Factory de Mocks
### Given necesidad de datos de prueba
### When usa factory de mocks
### Then debe generar entidades válidas para testing
### And debe permitir personalización de propiedades

### Scenario: Helpers de Testing
### Given tests que requieren setup/teardown
### When usa helpers de testing
### Then debe configurar y limpiar datos automáticamente
### And debe manejar conexiones de base de datos

## Definition of Done

- [ ] Crear factory de mocks para todas las entidades
- [ ] Crear helpers para setup/teardown de tests
- [ ] Configurar mocks globales para servicios externos
- [ ] Crear fixtures de datos de prueba
- [ ] Documentar uso de utilities de testing

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'utilities', 'helpers'],
    epic: 'Testing - Configuración Base'
  },

  // ÉPICA 2: Capa Domain
  {
    title: 'TS-003: Testing de Entidades Domain',
    description: `## Descripción

Implementar tests unitarios para todas las entidades del dominio de negocio.

## Criterios de Aceptación

### Scenario: Validación de Entidades
### Given entidades del dominio
### When ejecuta tests unitarios
### Then debe validar todas las propiedades y métodos
### And debe cubrir casos edge y validaciones

### Scenario: Cobertura de Entidades
### Given suite de tests de entidades
### When ejecuta reporte de cobertura
### Then debe tener cobertura mínima del 95%
### And debe incluir todas las entidades críticas

## Definition of Done

- [ ] Tests para Professor.ts: validación de propiedades, métodos de negocio
- [ ] Tests para Student.ts: validación de membership types, balance
- [ ] Tests para Booking.ts: validación de estados, fechas
- [ ] Tests para Schedule.ts: validación de disponibilidad, horarios
- [ ] Tests para Payment.ts: validación de montos, métodos de pago
- [ ] Tests para Service.ts: validación de precios, categorías
- [ ] Tests para Message.ts: validación de contenido, estados
- [ ] Tests para ServiceRequest.ts: validación de requests
- [ ] Cobertura mínima del 95% en todas las entidades

## Story Points: 8 | Priority: P0 | Sprint: 1`,
    estimate: 8,
    priority: 1,
    labels: ['testing', 'domain', 'entities'],
    epic: 'Testing - Capa Domain'
  },
  {
    title: 'TS-004: Testing de Use Cases - Professor',
    description: `## Descripción

Implementar tests unitarios para casos de uso del profesor.

## Criterios de Aceptación

### Scenario: Use Cases del Profesor
### Given casos de uso del profesor
### When ejecuta tests unitarios
### Then debe validar lógica de negocio
### And debe cubrir casos edge y validaciones

## Definition of Done

- [ ] Tests para PublishSchedule: validar creación de horarios
- [ ] Tests para ManageCourtAvailability: validar cambios de disponibilidad
- [ ] Tests para TrackIncome: validar cálculos de ingresos
- [ ] Tests para ManageServices: validar CRUD de servicios
- [ ] Tests de casos edge y validaciones de entrada
- [ ] Cobertura mínima del 90% en use cases del profesor

## Story Points: 6 | Priority: P0 | Sprint: 1`,
    estimate: 6,
    priority: 1,
    labels: ['testing', 'domain', 'use-cases', 'professor'],
    epic: 'Testing - Capa Domain'
  },
  {
    title: 'TS-005: Testing de Use Cases - Student',
    description: `## Descripción

Implementar tests unitarios para casos de uso del estudiante.

## Criterios de Aceptación

### Scenario: Use Cases del Estudiante
### Given casos de uso del estudiante
### When ejecuta tests unitarios
### Then debe validar lógica de negocio
### And debe cubrir casos edge y validaciones

## Definition of Done

- [ ] Tests para BookLesson: validar reservas
- [ ] Tests para CheckCourtAvailability: validar consultas de disponibilidad
- [ ] Tests para ViewBalance: validar consulta de saldo
- [ ] Tests para ViewPaymentHistory: validar historial de pagos
- [ ] Tests para RequestService: validar solicitudes de servicios
- [ ] Tests de casos edge y validaciones de entrada
- [ ] Cobertura mínima del 90% en use cases del estudiante

## Story Points: 6 | Priority: P0 | Sprint: 1`,
    estimate: 6,
    priority: 1,
    labels: ['testing', 'domain', 'use-cases', 'student'],
    epic: 'Testing - Capa Domain'
  },
  {
    title: 'TS-006: Testing de Use Cases - Messaging',
    description: `## Descripción

Implementar tests unitarios para casos de uso de mensajería.

## Criterios de Aceptación

### Scenario: Use Cases de Mensajería
### Given casos de uso de mensajería
### When ejecuta tests unitarios
### Then debe validar funcionalidad de mensajes
### And debe cubrir casos edge y validaciones

## Definition of Done

- [ ] Tests para SendMessage: validar envío de mensajes
- [ ] Tests para GetConversation: validar obtención de conversaciones
- [ ] Tests para GetConversations: validar lista de conversaciones
- [ ] Tests para GetMessages: validar obtención de mensajes
- [ ] Tests para MarkMessageAsRead: validar marcado como leído
- [ ] Tests para GetUnreadCount: validar conteo de no leídos
- [ ] Tests para CreateConversation: validar creación de conversaciones
- [ ] Cobertura mínima del 90% en use cases de mensajería

## Story Points: 7 | Priority: P1 | Sprint: 2`,
    estimate: 7,
    priority: 2,
    labels: ['testing', 'domain', 'use-cases', 'messaging'],
    epic: 'Testing - Capa Domain'
  },

  // ÉPICA 3: Capa Application
  {
    title: 'TS-007: Testing de Controladores - Auth',
    description: `## Descripción

Implementar tests unitarios para el controlador de autenticación.

## Criterios de Aceptación

### Scenario: Controlador de Autenticación
### Given controlador de autenticación
### When ejecuta tests unitarios
### Then debe validar login, registro y refresh
### And debe cubrir manejo de errores

## Definition of Done

- [ ] Tests para register: validar registro de usuarios, manejo de errores
- [ ] Tests para login: validar autenticación, tokens JWT
- [ ] Tests para refresh: validar renovación de tokens
- [ ] Tests de casos edge: usuarios existentes, credenciales inválidas
- [ ] Tests de integración con servicios externos (mocked)
- [ ] Cobertura mínima del 85% en AuthController

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'application', 'controllers', 'auth'],
    epic: 'Testing - Capa Application'
  },
  {
    title: 'TS-008: Testing de Controladores - Professor',
    description: `## Descripción

Implementar tests unitarios para controladores del profesor.

## Criterios de Aceptación

### Scenario: Controladores del Profesor
### Given controladores del profesor
### When ejecuta tests unitarios
### Then debe validar operaciones del profesor
### And debe cubrir autorización y permisos

## Definition of Done

- [ ] Tests para ProfessorController: getProfile, updateProfile, publishSchedule
- [ ] Tests para ProfessorDashboardController: métricas y reportes
- [ ] Tests para AnalyticsController: análisis y estadísticas
- [ ] Tests de validación de entrada y manejo de errores
- [ ] Tests de autorización y permisos
- [ ] Cobertura mínima del 85% en controladores del profesor

## Story Points: 6 | Priority: P0 | Sprint: 1`,
    estimate: 6,
    priority: 1,
    labels: ['testing', 'application', 'controllers', 'professor'],
    epic: 'Testing - Capa Application'
  },
  {
    title: 'TS-009: Testing de Controladores - Student',
    description: `## Descripción

Implementar tests unitarios para controladores del estudiante.

## Criterios de Aceptación

### Scenario: Controladores del Estudiante
### Given controladores del estudiante
### When ejecuta tests unitarios
### Then debe validar operaciones del estudiante
### And debe cubrir autorización y permisos

## Definition of Done

- [ ] Tests para StudentController: getProfile, bookLesson, viewBalance
- [ ] Tests para StudentDashboardController: dashboard del estudiante
- [ ] Tests de validación de entrada y manejo de errores
- [ ] Tests de autorización y permisos
- [ ] Tests de integración con servicios de pago
- [ ] Cobertura mínima del 85% en controladores del estudiante

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'application', 'controllers', 'student'],
    epic: 'Testing - Capa Application'
  },
  {
    title: 'TS-010: Testing de Middleware',
    description: `## Descripción

Implementar tests unitarios para todos los middleware.

## Criterios de Aceptación

### Scenario: Middleware de la Aplicación
### Given middleware de la aplicación
### When ejecuta tests unitarios
### Then debe validar autenticación, validación y logging
### And debe cubrir casos edge y manejo de errores

## Definition of Done

- [ ] Tests para auth.ts: middleware de autenticación
- [ ] Tests para validation.ts: middleware de validación
- [ ] Tests para requestId.ts: middleware de request ID
- [ ] Tests para analyticsValidation.ts: middleware de analytics
- [ ] Tests para firebaseAuth.ts: middleware de Firebase Auth
- [ ] Tests de casos edge y manejo de errores
- [ ] Cobertura mínima del 80% en middleware

## Story Points: 4 | Priority: P1 | Sprint: 2`,
    estimate: 4,
    priority: 2,
    labels: ['testing', 'application', 'middleware'],
    epic: 'Testing - Capa Application'
  },
  {
    title: 'TS-011: Testing de DTOs y Validaciones',
    description: `## Descripción

Implementar tests unitarios para DTOs y schemas de validación.

## Criterios de Aceptación

### Scenario: DTOs y Validaciones
### Given DTOs y schemas de validación
### When ejecuta tests unitarios
### Then debe validar entrada de datos
### And debe cubrir casos edge y mensajes de error

## Definition of Done

- [ ] Tests para RegisterSchema: validaciones de registro
- [ ] Tests para LoginSchema: validaciones de login
- [ ] Tests para PublishScheduleSchema: validaciones de horarios
- [ ] Tests para BookLessonSchema: validaciones de reservas
- [ ] Tests para ServiceCreateSchema: validaciones de servicios
- [ ] Tests para PaymentCreateSchema: validaciones de pagos
- [ ] Tests de casos edge y mensajes de error
- [ ] Cobertura mínima del 95% en DTOs

## Story Points: 4 | Priority: P1 | Sprint: 2`,
    estimate: 4,
    priority: 2,
    labels: ['testing', 'application', 'dtos', 'validation'],
    epic: 'Testing - Capa Application'
  },

  // ÉPICA 4: Capa Infrastructure
  {
    title: 'TS-012: Testing de Servicios Core',
    description: `## Descripción

Implementar tests unitarios para servicios principales.

## Criterios de Aceptación

### Scenario: Servicios Core
### Given servicios principales
### When ejecuta tests unitarios
### Then debe validar JWT, contraseñas y logging
### And debe cubrir casos edge y rendimiento

## Definition of Done

- [ ] Tests para JwtService: signAccess, signRefresh, verify
- [ ] Tests para PasswordService: hash, compare
- [ ] Tests para Logger: logging (mocking de console)
- [ ] Tests de casos edge: tokens expirados, contraseñas inválidas
- [ ] Tests de rendimiento y seguridad
- [ ] Cobertura mínima del 85% en servicios core

## Story Points: 4 | Priority: P0 | Sprint: 1`,
    estimate: 4,
    priority: 1,
    labels: ['testing', 'infrastructure', 'services'],
    epic: 'Testing - Capa Infrastructure'
  },
  {
    title: 'TS-013: Testing de Repositorios - CRUD Operations',
    description: `## Descripción

Implementar tests unitarios para operaciones CRUD de repositorios.

## Criterios de Aceptación

### Scenario: Repositorios CRUD
### Given repositorios de la aplicación
### When ejecuta tests unitarios
### Then debe validar interacción con base de datos
### And debe cubrir casos edge y referencias inválidas

## Definition of Done

- [ ] Tests para MongoProfessorRepository: CRUD operations, queries
- [ ] Tests para MongoStudentRepository: CRUD operations, balance updates
- [ ] Tests para MongoScheduleRepository: CRUD operations, availability queries
- [ ] Tests para MongoBookingRepository: CRUD operations, booking logic
- [ ] Tests para MongoPaymentRepository: CRUD operations, payment history
- [ ] Tests para MongoServiceRepository: CRUD operations, service management
- [ ] Tests de casos edge: datos duplicados, referencias inválidas
- [ ] Cobertura mínima del 80% en repositorios

## Story Points: 8 | Priority: P0 | Sprint: 1`,
    estimate: 8,
    priority: 1,
    labels: ['testing', 'infrastructure', 'repositories'],
    epic: 'Testing - Capa Infrastructure'
  },
  {
    title: 'TS-014: Testing de Repositorios - Messaging',
    description: `## Descripción

Implementar tests unitarios para repositorios de mensajería.

## Criterios de Aceptación

### Scenario: Repositorios de Mensajería
### Given repositorios de mensajería
### When ejecuta tests unitarios
### Then debe validar funcionalidad de mensajes
### And debe cubrir queries complejas y rendimiento

## Definition of Done

- [ ] Tests para MongoMessageRepository: CRUD operations, message queries
- [ ] Tests para MongoConversationRepository: CRUD operations, conversation logic
- [ ] Tests de queries complejas: mensajes por conversación, conteo de no leídos
- [ ] Tests de casos edge: conversaciones vacías, mensajes duplicados
- [ ] Tests de rendimiento para queries grandes
- [ ] Cobertura mínima del 80% en repositorios de mensajería

## Story Points: 5 | Priority: P1 | Sprint: 2`,
    estimate: 5,
    priority: 2,
    labels: ['testing', 'infrastructure', 'repositories', 'messaging'],
    epic: 'Testing - Capa Infrastructure'
  },
  {
    title: 'TS-015: Testing de Autenticación Firebase',
    description: `## Descripción

Implementar tests unitarios para integración con Firebase.

## Criterios de Aceptación

### Scenario: Integración Firebase
### Given integración con Firebase
### When ejecuta tests unitarios
### Then debe validar autenticación con Firebase Admin
### And debe cubrir casos edge y manejo de errores

## Definition of Done

- [ ] Tests para firebase.ts: integración con Firebase Admin
- [ ] Tests para firebaseAuth.ts: middleware de Firebase Auth
- [ ] Tests de casos edge: tokens inválidos, servicios no disponibles
- [ ] Tests de mocking de Firebase Admin SDK
- [ ] Tests de manejo de errores de Firebase
- [ ] Cobertura mínima del 80% en autenticación Firebase

## Story Points: 3 | Priority: P1 | Sprint: 2`,
    estimate: 3,
    priority: 2,
    labels: ['testing', 'infrastructure', 'auth', 'firebase'],
    epic: 'Testing - Capa Infrastructure'
  },

  // ÉPICA 5: Integración
  {
    title: 'TS-016: Testing de Integración - Auth Flow',
    description: `## Descripción

Implementar tests de integración para flujo completo de autenticación.

## Criterios de Aceptación

### Scenario: Flujo de Autenticación
### Given flujo completo de autenticación
### When ejecuta tests de integración
### Then debe validar registro, login y refresh juntos
### And debe usar MongoDB Memory Server

## Definition of Done

- [ ] Test de flujo completo: Registro → Login → Refresh
- [ ] Test con MongoDB Memory Server
- [ ] Test de manejo de errores en cadena
- [ ] Test de expiración de tokens
- [ ] Test de casos edge: usuarios duplicados, tokens corruptos
- [ ] Documentación del flujo de testing

## Story Points: 4 | Priority: P0 | Sprint: 1`,
    estimate: 4,
    priority: 1,
    labels: ['testing', 'integration', 'auth'],
    epic: 'Testing - Integración'
  },
  {
    title: 'TS-017: Testing de Integración - Professor Flow',
    description: `## Descripción

Implementar tests de integración para flujo completo del profesor.

## Criterios de Aceptación

### Scenario: Flujo del Profesor
### Given flujo completo del profesor
### When ejecuta tests de integración
### Then debe validar operaciones del profesor juntas
### And debe usar MongoDB Memory Server

## Definition of Done

- [ ] Test de flujo completo: Crear perfil → Publicar horario → Ver dashboard
- [ ] Test con MongoDB Memory Server
- [ ] Test de integración entre controladores y use cases
- [ ] Test de casos edge: horarios conflictivos, datos inválidos
- [ ] Documentación del flujo de testing

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'integration', 'professor'],
    epic: 'Testing - Integración'
  },
  {
    title: 'TS-018: Testing de Integración - Student Flow',
    description: `## Descripción

Implementar tests de integración para flujo completo del estudiante.

## Criterios de Aceptación

### Scenario: Flujo del Estudiante
### Given flujo completo del estudiante
### When ejecuta tests de integración
### Then debe validar operaciones del estudiante juntas
### And debe usar MongoDB Memory Server

## Definition of Done

- [ ] Test de flujo completo: Crear perfil → Reservar clase → Ver balance
- [ ] Test con MongoDB Memory Server
- [ ] Test de integración entre controladores y use cases
- [ ] Test de casos edge: reservas conflictivas, saldo insuficiente
- [ ] Documentación del flujo de testing

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'integration', 'student'],
    epic: 'Testing - Integración'
  },
  {
    title: 'TS-019: Testing de Integración - Messaging Flow',
    description: `## Descripción

Implementar tests de integración para flujo completo de mensajería.

## Criterios de Aceptación

### Scenario: Flujo de Mensajería
### Given flujo completo de mensajería
### When ejecuta tests de integración
### Then debe validar sistema de mensajes end-to-end
### And debe usar MongoDB Memory Server

## Definition of Done

- [ ] Test de flujo completo: Crear conversación → Enviar mensaje → Marcar como leído
- [ ] Test con MongoDB Memory Server
- [ ] Test de integración entre controladores y use cases
- [ ] Test de casos edge: mensajes vacíos, conversaciones inexistentes
- [ ] Documentación del flujo de testing

## Story Points: 4 | Priority: P1 | Sprint: 2`,
    estimate: 4,
    priority: 2,
    labels: ['testing', 'integration', 'messaging'],
    epic: 'Testing - Integración'
  },

  // ÉPICA 6: End-to-End
  {
    title: 'TS-020: Testing E2E - Authentication APIs',
    description: `## Descripción

Implementar tests E2E para APIs de autenticación.

## Criterios de Aceptación

### Scenario: APIs de Autenticación
### Given APIs de autenticación
### When ejecuta tests E2E
### Then debe validar comportamiento completo del sistema
### And debe usar base de datos real (testcontainers)

## Definition of Done

- [ ] Tests E2E para /api/auth/register
- [ ] Tests E2E para /api/auth/login
- [ ] Tests E2E para /api/auth/refresh
- [ ] Tests E2E para /api/auth/firebase/verify
- [ ] Tests con base de datos real (testcontainers)
- [ ] Tests de casos edge y manejo de errores HTTP
- [ ] Documentación de los tests E2E

## Story Points: 5 | Priority: P0 | Sprint: 1`,
    estimate: 5,
    priority: 1,
    labels: ['testing', 'e2e', 'auth', 'apis'],
    epic: 'Testing - End-to-End'
  },
  {
    title: 'TS-021: Testing E2E - Professor APIs',
    description: `## Descripción

Implementar tests E2E para APIs del profesor.

## Criterios de Aceptación

### Scenario: APIs del Profesor
### Given APIs del profesor
### When ejecuta tests E2E
### Then debe validar comportamiento completo
### And debe usar base de datos real (testcontainers)

## Definition of Done

- [ ] Tests E2E para todas las rutas de profesor
- [ ] Tests E2E para dashboard del profesor
- [ ] Tests E2E para analytics y reportes
- [ ] Tests con base de datos real (testcontainers)
- [ ] Tests de autorización y permisos
- [ ] Tests de casos edge y validaciones
- [ ] Documentación de los tests E2E

## Story Points: 6 | Priority: P0 | Sprint: 1`,
    estimate: 6,
    priority: 1,
    labels: ['testing', 'e2e', 'professor', 'apis'],
    epic: 'Testing - End-to-End'
  },
  {
    title: 'TS-022: Testing E2E - Student APIs',
    description: `## Descripción

Implementar tests E2E para APIs del estudiante.

## Criterios de Aceptación

### Scenario: APIs del Estudiante
### Given APIs del estudiante
### When ejecuta tests E2E
### Then debe validar comportamiento completo
### And debe usar base de datos real (testcontainers)

## Definition of Done

- [ ] Tests E2E para todas las rutas de estudiante
- [ ] Tests E2E para dashboard del estudiante
- [ ] Tests E2E para reservas y pagos
- [ ] Tests con base de datos real (testcontainers)
- [ ] Tests de autorización y permisos
- [ ] Tests de casos edge y validaciones
- [ ] Documentación de los tests E2E

## Story Points: 6 | Priority: P0 | Sprint: 1`,
    estimate: 6,
    priority: 1,
    labels: ['testing', 'e2e', 'student', 'apis'],
    epic: 'Testing - End-to-End'
  },
  {
    title: 'TS-023: Testing E2E - Messaging APIs',
    description: `## Descripción

Implementar tests E2E para APIs de mensajería.

## Criterios de Aceptación

### Scenario: APIs de Mensajería
### Given APIs de mensajería
### When ejecuta tests E2E
### Then debe validar comportamiento completo
### And debe usar base de datos real (testcontainers)

## Definition of Done

- [ ] Tests E2E para todas las rutas de mensajería
- [ ] Tests E2E para conversaciones y mensajes
- [ ] Tests E2E para notificaciones y estados
- [ ] Tests con base de datos real (testcontainers)
- [ ] Tests de autorización y permisos
- [ ] Tests de casos edge y validaciones
- [ ] Documentación de los tests E2E

## Story Points: 5 | Priority: P1 | Sprint: 2`,
    estimate: 5,
    priority: 2,
    labels: ['testing', 'e2e', 'messaging', 'apis'],
    epic: 'Testing - End-to-End'
  },
  {
    title: 'TS-024: Testing de Casos Edge y Performance',
    description: `## Descripción

Implementar tests E2E para casos edge y performance.

## Criterios de Aceptación

### Scenario: Casos Edge y Performance
### Given sistema bajo condiciones extremas
### When ejecuta tests E2E
### Then debe validar comportamiento del sistema
### And debe incluir tests de carga

## Definition of Done

- [ ] Tests de manejo de errores HTTP (400, 401, 403, 404, 500)
- [ ] Tests de rate limiting
- [ ] Tests de middleware de seguridad
- [ ] Tests de performance básicos
- [ ] Tests de carga con múltiples usuarios concurrentes
- [ ] Tests de timeout y recuperación
- [ ] Documentación de los tests de performance

## Story Points: 4 | Priority: P1 | Sprint: 2`,
    estimate: 4,
    priority: 2,
    labels: ['testing', 'e2e', 'performance', 'edge-cases'],
    epic: 'Testing - End-to-End'
  },

  // ÉPICA 7: CI/CD y Documentación
  {
    title: 'TS-025: Configuración de CI/CD',
    description: `## Descripción

Configurar CI/CD para testing automático.

## Criterios de Aceptación

### Scenario: CI/CD de Testing
### Given configuración de CI/CD
### When se ejecuta pipeline
### Then debe ejecutar todos los tests automáticamente
### And debe generar reportes de cobertura

## Definition of Done

- [ ] Configurar GitHub Actions o similar para CI/CD
- [ ] Pipeline de testing automático en cada PR
- [ ] Configuración de coverage reports
- [ ] Notificaciones de fallos de tests
- [ ] Configuración de tests en diferentes entornos
- [ ] Documentación del pipeline de CI/CD

## Story Points: 3 | Priority: P0 | Sprint: 1`,
    estimate: 3,
    priority: 1,
    labels: ['testing', 'cicd', 'automation'],
    epic: 'Testing - CI/CD y Documentación'
  },
  {
    title: 'TS-026: Documentación de Testing',
    description: `## Descripción

Crear documentación completa del sistema de testing.

## Criterios de Aceptación

### Scenario: Documentación de Testing
### Given sistema de testing completo
### When se consulta documentación
### Then debe facilitar mantenimiento y contribución
### And debe incluir guías y mejores prácticas

## Definition of Done

- [ ] Documentación de cómo ejecutar tests
- [ ] Guía de contribución para testing
- [ ] Documentación de cobertura y métricas
- [ ] Guía de troubleshooting de tests
- [ ] Documentación de mejores prácticas
- [ ] Actualización del README con información de testing

## Story Points: 3 | Priority: P1 | Sprint: 2`,
    estimate: 3,
    priority: 2,
    labels: ['testing', 'documentation', 'guides'],
    epic: 'Testing - CI/CD y Documentación'
  }
];

async function createTestingEpicsAndStories() {
  try {
    console.log('🚀 Creando épicas y historias de testing en Linear...\n');

    const { teamId } = getLinearConfig();

    // 1. Crear las 7 épicas como proyectos
    console.log('📋 Creando épicas como proyectos...');
    const epicProjects = {};

    for (const epic of testingEpics) {
      console.log(`📝 Creando proyecto: ${epic.name}`);
      
      const createProjectMutation = `
        mutation {
          projectCreate(
            input: {
              name: "${epic.name}"
              description: "${epic.description}"
              state: "${epic.state}"
              teamIds: ["${teamId}"]
            }
          ) {
            success
            project {
              id
              name
              state
            }
          }
        }
      `;

      const projectResponse = await makeLinearRequest(createProjectMutation);
      
      if (projectResponse.data.projectCreate?.success) {
        const project = projectResponse.data.projectCreate.project;
        epicProjects[epic.name] = project.id;
        console.log(`   ✅ Proyecto creado: ${project.name} (${project.id})`);
      } else {
        console.log(`   ❌ Error creando proyecto: ${epic.name}`);
      }
    }

    // 2. Crear labels necesarios
    console.log('\n🏷️  Creando labels necesarios...');
    const labels = [
      'testing', 'infrastructure', 'setup', 'utilities', 'helpers',
      'domain', 'entities', 'use-cases', 'professor', 'student', 'messaging',
      'application', 'controllers', 'auth', 'middleware', 'dtos', 'validation',
      'repositories', 'firebase', 'integration', 'e2e', 'apis', 'performance',
      'edge-cases', 'cicd', 'automation', 'documentation', 'guides'
    ];

    const createdLabels = {};
    for (const labelName of labels) {
      try {
        const createLabelMutation = `
          mutation {
            issueLabelCreate(
              input: {
                name: "${labelName}"
                color: "#${Math.floor(Math.random()*16777215).toString(16)}"
                teamId: "${teamId}"
              }
            ) {
              success
              issueLabel {
                id
                name
                color
              }
            }
          }
        `;

        const labelResponse = await makeLinearRequest(createLabelMutation);
        
        if (labelResponse.data.issueLabelCreate?.success) {
          const label = labelResponse.data.issueLabelCreate.issueLabel;
          createdLabels[labelName] = label.id;
          console.log(`   ✅ Label creado: ${label.name}`);
        }
      } catch (error) {
        // Label ya existe, obtener su ID
        const getLabelsQuery = `
          query {
            issueLabels(first: 50, filter: { name: { eq: "${labelName}" } }) {
              nodes {
                id
                name
              }
            }
          }
        `;

        const labelsResponse = await makeLinearRequest(getLabelsQuery);
        if (labelsResponse.data.issueLabels.nodes.length > 0) {
          createdLabels[labelName] = labelsResponse.data.issueLabels.nodes[0].id;
          console.log(`   ✅ Label existente: ${labelName}`);
        }
      }
    }

    // 3. Crear las 22 historias
    console.log('\n📋 Creando historias de testing...');
    let createdStories = 0;
    let errorStories = 0;

    for (const story of testingStories) {
      console.log(`📝 Creando historia: ${story.title}`);
      
      // Obtener IDs de labels para esta historia
      const labelIds = story.labels.map(labelName => createdLabels[labelName]).filter(Boolean);
      
      // Obtener ID del proyecto (épica)
      const projectId = epicProjects[story.epic];
      
      if (!projectId) {
        console.log(`   ❌ Error: No se encontró proyecto para épica: ${story.epic}`);
        errorStories++;
        continue;
      }

      const createIssueMutation = `
        mutation {
          issueCreate(
            input: {
              title: "${story.title}"
              description: ${JSON.stringify(story.description)}
              teamId: "${teamId}"
              projectId: "${projectId}"
              labelIds: [${labelIds.map(id => `"${id}"`).join(', ')}]
              estimate: ${story.estimate}
              priority: ${story.priority}
            }
          ) {
            success
            issue {
              id
              title
              number
              project {
                name
              }
            }
          }
        }
      `;

      try {
        const issueResponse = await makeLinearRequest(createIssueMutation);
        
        if (issueResponse.data.issueCreate?.success) {
          const issue = issueResponse.data.issueCreate.issue;
          console.log(`   ✅ Historia creada: ${issue.title} (#${issue.number})`);
          console.log(`      📁 Proyecto: ${issue.project.name}`);
          console.log(`      📊 Story Points: ${story.estimate}`);
          console.log(`      ⚡ Priority: P${story.priority - 1}`);
          createdStories++;
        } else {
          console.log(`   ❌ Error creando historia: ${story.title}`);
          errorStories++;
        }
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
        errorStories++;
      }
    }

    // 4. Resumen final
    console.log('\n🎉 ¡Creación de épicas y historias completada!');
    console.log('─'.repeat(60));
    console.log(`📋 Épicas creadas: ${Object.keys(epicProjects).length}/7`);
    console.log(`📋 Historias creadas: ${createdStories}/22`);
    console.log(`❌ Errores: ${errorStories}`);
    console.log(`🏷️  Labels creados: ${Object.keys(createdLabels).length}`);

    console.log('\n📊 RESUMEN DE ÉPICAS:');
    console.log('─'.repeat(60));
    Object.keys(epicProjects).forEach(epicName => {
      console.log(`✅ ${epicName}`);
    });

    console.log('\n📊 DISTRIBUCIÓN POR PRIORIDAD:');
    console.log('─'.repeat(60));
    const priorityCount = testingStories.reduce((acc, story) => {
      acc[story.priority] = (acc[story.priority] || 0) + 1;
      return acc;
    }, {});
    
    Object.entries(priorityCount).forEach(([priority, count]) => {
      console.log(`P${priority - 1}: ${count} historias`);
    });

    console.log('\n📊 TOTAL STORY POINTS:');
    console.log('─'.repeat(60));
    const totalPoints = testingStories.reduce((sum, story) => sum + story.estimate, 0);
    console.log(`Total: ${totalPoints} story points`);
    console.log(`Estimación: ${Math.ceil(totalPoints / 20)} semanas`);

  } catch (error) {
    console.error('❌ Error creando épicas y historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
createTestingEpicsAndStories();
