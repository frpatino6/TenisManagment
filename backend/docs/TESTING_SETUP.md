# Testing Setup Configuration

## TEN-57: TS-001 - Setup del Entorno de Testing

Este documento describe la configuración completa del entorno de testing para el Tennis Management Backend.

---

## 📋 Dependencias Instaladas

### Testing Framework

```json
{
  "@jest/globals": "^30.2.0",
  "jest": "^30.2.0",
  "jest-environment-node": "^30.2.0",
  "jest-mock-extended": "^4.0.0",
  "ts-jest": "^29.4.4"
}
```

### TypeScript Support

```json
{
  "@types/jest": "^30.0.0",
  "typescript": "^5.0.0",
  "ts-node": "^10.9.2"
}
```

### HTTP Testing

```json
{
  "supertest": "^7.1.4",
  "@types/supertest": "^6.0.3"
}
```

### Database Testing

```json
{
  "mongodb-memory-server": "^10.2.1",
  "testcontainers": "^11.7.1"
}
```

---

## ⚙️ Configuración de Jest

### 1. Configuración Principal (jest.config.js)

**Propósito**: Tests unitarios

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.test.ts'],
  testPathIgnorePatterns: ['/node_modules/', '/integration/'],
  transform: {
    '^.+\\.ts$': ['ts-jest', {
      isolatedModules: true,
      tsconfig: {
        strict: false,
        noImplicitAny: false,
        skipLibCheck: true,
        esModuleInterop: true,
        allowSyntheticDefaultImports: true
      }
    }]
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/__tests__/**',
    '!src/presentation/server.ts'
  ],
  setupFilesAfterEnv: ['<rootDir>/src/__tests__/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  testTimeout: 10000,
  clearMocks: true,
  restoreMocks: true,
  verbose: true
};
```

**Características**:
- ✅ Soporte completo para TypeScript via ts-jest
- ✅ Isolated modules para compilación rápida
- ✅ Path aliases (`@/...`)
- ✅ Auto-clear mocks entre tests
- ✅ Timeout de 10 segundos
- ✅ Verbose output

### 2. Configuración de Integración (config/jest/jest.integration.config.js)

**Propósito**: Tests de integración

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/../../src'],
  testMatch: ['**/__tests__/integration/**/*.test.ts'],
  setupFilesAfterEnv: ['<rootDir>/../../src/__tests__/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../../src/$1'
  },
  testTimeout: 30000,  // 30 segundos
  clearMocks: true,
  restoreMocks: true,
  verbose: true
};
```

**Características**:
- ✅ Timeout extendido (30s) para operaciones de DB
- ✅ Solo ejecuta tests en `/integration/`
- ✅ Misma configuración de mocks y helpers

### 3. Configuración E2E (config/jest/jest.e2e.config.js)

**Propósito**: Tests end-to-end

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/../../src'],
  testMatch: ['**/__tests__/e2e/**/*.test.ts'],
  setupFilesAfterEnv: ['<rootDir>/../../src/__tests__/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../../src/$1'
  },
  testTimeout: 60000,  // 60 segundos
  clearMocks: true,
  restoreMocks: true,
  verbose: true
};
```

**Características**:
- ✅ Timeout muy extendido (60s) para flujos completos
- ✅ Solo ejecuta tests en `/e2e/`
- ✅ Ideal para tests de APIs completas

---

## 🔧 Scripts de Testing Configurados

### Scripts en package.json

```json
{
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage",
  "test:unit": "jest --config jest.config.js",
  "test:integration": "jest --config config/jest/jest.integration.config.js",
  "test:e2e": "jest --config config/jest/jest.e2e.config.js",
  "test:ci": "jest --ci --coverage --watchAll=false",
  "test:ci-safe": "jest --ci --coverage --watchAll=false"
}
```

### Uso de Scripts

```bash
# Tests unitarios (rápidos, solo unit/)
npm run test:unit

# Tests de integración (moderados, solo integration/)
npm run test:integration

# Tests E2E (lentos, solo e2e/)
npm run test:e2e

# Todos los tests
npm test

# Tests con cobertura
npm run test:coverage

# Modo watch para desarrollo
npm run test:watch

# Tests para CI/CD
npm run test:ci
```

---

## 🗄️ MongoDB Memory Server

### Configuración

MongoDB Memory Server está instalado y listo para usar en tests de integración:

```typescript
import { MongoMemoryServer } from 'mongodb-memory-server';

describe('Integration Test', () => {
  let mongoServer: MongoMemoryServer;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    // Connect to in-memory database
  });

  afterAll(async () => {
    await mongoServer.stop();
  });

  it('should work with database', async () => {
    // Test with real MongoDB operations
  });
});
```

### Ventajas

- ✅ No requiere MongoDB instalado
- ✅ Base de datos limpia para cada test
- ✅ Rápido (en memoria)
- ✅ Aislamiento completo entre tests

---

## 🛠️ Helpers y Utilities

### Global Test Utilities (jest.setup.js)

```typescript
global.testUtils = {
  // Crear usuarios de prueba
  createTestUser: (overrides = {}) => ({
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
    role: 'student',
    ...overrides
  }),

  // Crear profesores de prueba
  createTestProfessor: (overrides = {}) => ({
    id: 'test-professor-id',
    name: 'Test Professor',
    email: 'professor@example.com',
    phone: '1234567890',
    specialties: ['tennis'],
    hourlyRate: 50,
    experienceYears: 5,
    ...overrides
  }),

  // Crear estudiantes de prueba
  createTestStudent: (overrides = {}) => ({
    id: 'test-student-id',
    name: 'Test Student',
    email: 'student@example.com',
    phone: '0987654321',
    membershipType: 'basic',
    balance: 100,
    ...overrides
  }),

  // Crear horarios de prueba
  createTestSchedule: (overrides = {}) => ({
    id: 'test-schedule-id',
    professorId: 'test-professor-id',
    date: new Date('2024-12-01'),
    startTime: '10:00',
    endTime: '11:00',
    type: 'individual',
    isAvailable: true,
    ...overrides
  }),

  // Crear reservas de prueba
  createTestBooking: (overrides = {}) => ({
    id: 'test-booking-id',
    studentId: 'test-student-id',
    scheduleId: 'test-schedule-id',
    type: 'lesson',
    status: 'confirmed',
    createdAt: new Date(),
    ...overrides
  })
};
```

### Uso en Tests

```typescript
import { describe, it, expect } from '@jest/globals';

it('should create user', () => {
  const user = global.testUtils.createTestUser({ 
    name: 'Custom Name' 
  });
  
  expect(user.name).toBe('Custom Name');
  expect(user.email).toBe('test@example.com');
});
```

---

## 🔒 Variables de Entorno

### Variables Configuradas en jest.setup.js

```javascript
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-only';
process.env.MONGO_URI = 'mongodb://localhost:27017/tennis-management-test';
```

### Variables Adicionales (si necesarias)

```bash
# .env.test
NODE_ENV=test
JWT_SECRET=test-jwt-secret-key
MONGO_URI=mongodb://localhost:27017/tennis-test
LOG_LEVEL=error
```

---

## 📊 Cobertura de Código

### Configuración

```javascript
collectCoverageFrom: [
  'src/**/*.ts',           // Incluir todo el código fuente
  '!src/**/*.d.ts',        // Excluir definiciones de tipos
  '!src/__tests__/**',     // Excluir tests
  '!src/presentation/server.ts'  // Excluir entry point
]
```

### Umbrales (Actualmente deshabilitados para desarrollo)

```javascript
coverageThreshold: {
  global: {
    branches: 0,    // Se puede configurar a 80
    functions: 0,   // Se puede configurar a 80
    lines: 0,       // Se puede configurar a 80
    statements: 0   // Se puede configurar a 80
  }
}
```

### Activar Umbrales de Cobertura

Para activar umbrales estrictos (cuando el proyecto esté más maduro):

```javascript
coverageThreshold: {
  global: {
    branches: 80,
    functions: 80,
    lines: 80,
    statements: 80
  }
}
```

---

## 🧪 Estructura de Directorios de Tests

```
src/__tests__/
├── unit/                    # Tests unitarios
│   ├── *.test.ts           # Tests de componentes individuales
│   └── dtos-validation.test.ts
├── integration/            # Tests de integración
│   ├── auth-integration.test.ts
│   ├── messaging-flow.test.ts
│   ├── professor-flow.test.ts
│   └── student-flow-basic.test.ts
├── e2e/                   # Tests end-to-end
│   ├── auth-simple.test.ts
│   ├── edge-cases-and-performance.test.ts
│   ├── professor.test.ts
│   └── student.test.ts
├── utils/                 # Utilidades de testing
│   └── test-helpers.ts
├── fixtures/              # Datos de prueba
│   └── test-data.json
├── mocks/                 # Mocks de servicios
│   └── external-apis.ts
├── types/                 # Definiciones de tipos
│   └── global.d.ts
└── jest.setup.js          # Setup global
```

---

## ✅ Verificación del Setup

### Comandos de Verificación

```bash
# 1. Verificar que Jest puede encontrar tests
npm test -- --listTests

# 2. Ejecutar tests unitarios
npm run test:unit

# 3. Ejecutar tests de integración
npm run test:integration

# 4. Ejecutar tests E2E
npm run test:e2e

# 5. Generar cobertura
npm run test:coverage

# 6. Ver configuración de Jest
npm test -- --showConfig
```

### Checklist de Verificación

- ✅ Jest instalado y configurado
- ✅ TypeScript support via ts-jest
- ✅ Supertest para testing de APIs
- ✅ MongoDB Memory Server instalado
- ✅ Configuraciones separadas (unit, integration, e2e)
- ✅ Scripts en package.json
- ✅ Setup global con helpers
- ✅ Path aliases configurados
- ✅ Mock clearing automático
- ✅ Variables de entorno configuradas

---

## 🚀 Ejecución Rápida

### Test Individual

```bash
# Ejecutar un test específico
npm test -- src/__tests__/unit/dtos-validation.test.ts

# Con pattern matching
npm test -- --testNamePattern="should validate"
```

### Modo Watch (Desarrollo)

```bash
npm run test:watch

# Watch solo un archivo
npm run test:watch -- dtos-validation.test.ts
```

### CI/CD

```bash
# Ejecutar como en CI
npm run test:ci

# Con safe mode
npm run test:ci-safe
```

---

## 📝 Definition of Done - Status

- [x] ✅ Instalar dependencias de testing (Jest, ts-jest, supertest, etc.)
- [x] ✅ Configurar Jest con soporte para TypeScript
- [x] ✅ Configurar scripts de testing en package.json
- [x] ✅ Crear configuración para diferentes tipos de test (unit, integration, e2e)
- [x] ✅ Configurar MongoDB Memory Server para tests
- [x] ✅ Documentar comandos de testing

---

## 🔗 Referencias

- **Configuración Principal**: `jest.config.js`
- **Config Integration**: `config/jest/jest.integration.config.js`
- **Config E2E**: `config/jest/jest.e2e.config.js`
- **Setup Global**: `src/__tests__/jest.setup.js`
- **Documentación**: `TESTING.md`

---

## 📊 Estado del Setup

| Componente | Estado | Versión | Notas |
|------------|--------|---------|-------|
| Jest | ✅ Configurado | 30.2.0 | Framework principal |
| TypeScript | ✅ Configurado | 5.0.0 | Con ts-jest |
| Supertest | ✅ Instalado | 7.1.4 | Para testing HTTP |
| MongoDB Memory | ✅ Instalado | 10.2.1 | Para tests de DB |
| Scripts | ✅ Configurados | - | 8 scripts disponibles |
| Helpers | ✅ Creados | - | 5 factories globales |
| Coverage | ✅ Configurado | - | Con umbrales opcionales |

---

## 🎯 Siguientes Pasos

Ahora que el setup está completo, puedes:

1. ✅ Escribir tests unitarios
2. ✅ Escribir tests de integración  
3. ✅ Escribir tests E2E
4. ✅ Generar reportes de cobertura
5. ✅ Ejecutar tests en CI/CD

---

**Issue**: TEN-57  
**Fecha**: Octubre 2025  
**Estado**: ✅ Completado

