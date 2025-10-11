# 🧪 Testing Guide - Tennis Management Backend

## 📋 Tabla de Contenidos

1. [Resumen](#resumen)
2. [Arquitectura de Testing](#arquitectura-de-testing)
3. [Cómo Ejecutar Tests](#cómo-ejecutar-tests)
4. [Tipos de Tests](#tipos-de-tests)
5. [Escribir Tests](#escribir-tests)
6. [Cobertura y Métricas](#cobertura-y-métricas)
7. [Guía de Contribución](#guía-de-contribución)
8. [Troubleshooting](#troubleshooting)
9. [Mejores Prácticas](#mejores-prácticas)
10. [CI/CD Integration](#cicd-integration)
11. [Recursos Adicionales](#recursos-adicionales)

---

## 📋 Resumen

Este documento describe la configuración completa de testing para el proyecto Tennis Management Backend. Nuestro enfoque de testing está diseñado para garantizar la calidad del código, prevenir regresiones y facilitar el mantenimiento a largo plazo.

### Estadísticas del Proyecto

- **Tests Totales**: 108+ tests
- **Cobertura Global**: > 95%
- **Tests Unitarios**: 73+ tests
- **Tests de Integración**: 15+ tests
- **Tests E2E**: 35+ tests

### Stack Tecnológico

- **Jest**: Framework de testing principal (v30.2.0)
- **ts-jest**: Soporte para TypeScript (v29.4.4)
- **supertest**: Testing de APIs HTTP (v7.1.4)
- **mongodb-memory-server**: Base de datos en memoria (v10.2.1)
- **jest-mock-extended**: Mocking avanzado (v4.0.0)
- **testcontainers**: Testing con contenedores reales (v11.7.1)

---

## 🏗️ Arquitectura de Testing

### Estructura de Directorios

```
src/__tests__/
├── unit/                           # Tests unitarios (73+ tests)
│   ├── AnalyticsController.test.ts
│   ├── AuthController.test.ts
│   ├── dtos-validation.test.ts     # Validación de DTOs
│   ├── firebase.test.ts
│   ├── MongoConversationRepository.test.ts
│   ├── MongoMessageRepository.test.ts
│   └── ...
├── integration/                    # Tests de integración (15+ tests)
│   ├── auth-integration.test.ts
│   ├── messaging-flow.test.ts
│   ├── professor-flow.test.ts
│   └── student-flow-basic.test.ts
├── e2e/                           # Tests end-to-end (35+ tests)
│   ├── auth-simple.test.ts
│   ├── edge-cases-and-performance.test.ts
│   ├── professor.test.ts
│   └── student.test.ts
├── utils/                         # Utilidades de testing
│   └── test-helpers.ts
├── fixtures/                      # Datos de prueba
│   └── test-data.json
├── mocks/                         # Mocks de servicios externos
│   └── external-apis.ts
├── types/                         # Definiciones de tipos
│   └── global.d.ts
└── jest.setup.js                  # Configuración global de Jest
```

### Pirámide de Testing

```
       /\
      /E2E\         ← 35+ tests (Flujos completos)
     /______\
    /        \
   /Integration\    ← 15+ tests (Flujos de componentes)
  /__________  \
 /              \
/   Unit Tests   \  ← 73+ tests (Lógica individual)
/__________________\
```

---

## 🚀 Cómo Ejecutar Tests

### Comandos Principales

```bash
# Ejecutar todos los tests
npm test

# Ejecutar tests en modo watch (desarrollo)
npm run test:watch

# Ejecutar tests con reporte de cobertura
npm run test:coverage

# Ejecutar solo tests unitarios
npm run test:unit

# Ejecutar solo tests de integración
npm run test:integration

# Ejecutar solo tests E2E
npm run test:e2e

# Ejecutar tests para CI/CD
npm run test:ci

# Ejecutar test:ci con fallback seguro
npm run test:ci-safe
```

### Comandos Avanzados

```bash
# Ejecutar un test específico por nombre
npm test -- --testNamePattern="should create user"

# Ejecutar tests en un archivo específico
npm test -- auth.test.ts

# Ejecutar tests con verbose output
npm test -- --verbose

# Ejecutar tests con debugging
npm test -- --detectOpenHandles

# Ejecutar tests y actualizar snapshots
npm test -- --updateSnapshot

# Ejecutar tests con información de cobertura detallada
npm run test:coverage -- --verbose

# Ejecutar solo tests que fallaron
npm test -- --onlyFailures

# Ejecutar tests en modo silencioso
npm test -- --silent
```

### Comandos por Categoría

```bash
# Tests de DTOs y Validaciones (TEN-67)
npm run test:unit -- dtos-validation

# Tests de Performance y Edge Cases (TEN-80)
npm run test:e2e -- edge-cases-and-performance

# Tests de Autenticación
npm run test:e2e -- auth

# Tests de Profesor
npm run test:e2e -- professor

# Tests de Estudiante
npm run test:e2e -- student
```

### Variables de Entorno para Tests

```bash
# Variables básicas
NODE_ENV=test
JWT_SECRET=test-jwt-secret-key-for-testing-only-do-not-use-in-production
MONGO_URI=mongodb://localhost:27017/tennis-management-test

# Variables opcionales
TEST_TIMEOUT=10000
LOG_LEVEL=error
```

---

## 🧪 Tipos de Tests

### 1. Tests Unitarios

**Ubicación**: `src/__tests__/unit/`  
**Configuración**: `jest.config.js`  
**Propósito**: Probar funciones, clases y componentes individuales de forma aislada

#### Características
- Ejecución rápida (< 1 segundo por test)
- Sin dependencias externas (mocks para todo)
- Alta cobertura de código
- Enfoque en lógica de negocio

#### Ejemplo de Estructura

```typescript
import { describe, it, expect, beforeEach } from '@jest/globals';
import { LoginSchema } from '../../application/dtos/auth';

describe('LoginSchema Validation', () => {
  describe('✅ Valid Cases', () => {
    it('should validate correct login credentials', () => {
      const validLogin = {
        email: 'user@example.com',
        password: 'password123'
      };

      const result = LoginSchema.safeParse(validLogin);
      expect(result.success).toBe(true);
    });
  });

  describe('❌ Invalid Cases', () => {
    it('should reject invalid email format', () => {
      const invalidLogin = {
        email: 'not-an-email',
        password: 'password123'
      };

      const result = LoginSchema.safeParse(invalidLogin);
      expect(result.success).toBe(false);
    });
  });
});
```

#### ¿Qué Cubren?

- ✅ Validaciones de DTOs (Zod schemas)
- ✅ Entidades de dominio
- ✅ Use cases
- ✅ Controladores (con mocks)
- ✅ Repositorios (con mocks)
- ✅ Servicios auxiliares
- ✅ Middleware (con mocks)

### 2. Tests de Integración

**Ubicación**: `src/__tests__/integration/`  
**Configuración**: `config/jest/jest.integration.config.js`  
**Propósito**: Probar la interacción entre múltiples componentes

#### Características
- Ejecución moderada (1-5 segundos por test)
- Algunas dependencias reales (MongoDB in-memory)
- Prueba flujos completos
- Enfoque en integraciones

#### Ejemplo de Estructura

```typescript
import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';

describe('Authentication Integration Flow', () => {
  let mongoServer: MongoMemoryServer;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    // Setup database connection
  });

  afterAll(async () => {
    await mongoServer.stop();
  });

  it('should complete full auth flow', async () => {
    // Test complete authentication flow
    // 1. Register
    // 2. Login
    // 3. Use protected route
  });
});
```

#### ¿Qué Cubren?

- ✅ Flujos de autenticación completos
- ✅ Flujos de profesor (crear horarios, aceptar reservas)
- ✅ Flujos de estudiante (reservar clases, pagos)
- ✅ Flujos de mensajería
- ✅ Interacciones entre capas

### 3. Tests E2E (End-to-End)

**Ubicación**: `src/__tests__/e2e/`  
**Configuración**: `config/jest/jest.e2e.config.js`  
**Propósito**: Probar el sistema completo como lo usaría un usuario

#### Características
- Ejecución más lenta (5-15 segundos por suite)
- Todas las dependencias reales o simuladas
- Prueba endpoints HTTP completos
- Enfoque en experiencia de usuario

#### Ejemplo de Estructura

```typescript
import { describe, it, expect, beforeEach } from '@jest/globals';
import request from 'supertest';
import express from 'express';

describe('Professor APIs E2E Tests', () => {
  let app: express.Application;

  beforeEach(() => {
    app = createTestApp();
  });

  it('should publish schedule successfully', async () => {
    const response = await request(app)
      .post('/api/professor/schedule')
      .set('Authorization', 'Bearer valid-token')
      .send({
        date: '2025-10-15',
        startTime: '09:00',
        endTime: '10:00',
        type: 'individual'
      })
      .expect(201);

    expect(response.body).toHaveProperty('scheduleId');
  });
});
```

#### ¿Qué Cubren?

- ✅ APIs de autenticación
- ✅ APIs de profesor
- ✅ APIs de estudiante
- ✅ APIs de dashboard
- ✅ Manejo de errores HTTP (400, 401, 403, 404, 500)
- ✅ Rate limiting
- ✅ Middleware de seguridad
- ✅ Tests de performance
- ✅ Tests de carga concurrente

---

## 📝 Escribir Tests

### Estructura AAA (Arrange-Act-Assert)

```typescript
it('should do something', () => {
  // Arrange: Preparar datos y configuración
  const input = { email: 'test@example.com', password: 'pass123' };
  const expected = { success: true };

  // Act: Ejecutar la acción que queremos probar
  const result = functionUnderTest(input);

  // Assert: Verificar el resultado
  expect(result).toEqual(expected);
});
```

### Convenciones de Nombres

```typescript
// ✅ Buenos nombres (descriptivos y claros)
it('should return 401 when credentials are invalid', () => {});
it('should create schedule when all data is valid', () => {});
it('should reject email shorter than 5 characters', () => {});

// ❌ Malos nombres (vagos y poco claros)
it('works', () => {});
it('test login', () => {});
it('should work correctly', () => {});
```

### Organización de Tests

```typescript
describe('FeatureName', () => {
  // Setup global
  beforeAll(() => {
    // Se ejecuta una vez antes de todos los tests
  });

  afterAll(() => {
    // Se ejecuta una vez después de todos los tests
  });

  describe('Method or Scenario', () => {
    // Setup para cada test
    beforeEach(() => {
      // Se ejecuta antes de cada test
    });

    afterEach(() => {
      // Se ejecuta después de cada test
    });

    it('should do something', () => {
      // Test implementation
    });
  });
});
```

### Testing Asíncrono

```typescript
// Con async/await
it('should fetch user data', async () => {
  const result = await fetchUserData('user123');
  expect(result).toHaveProperty('email');
});

// Con promises
it('should fetch user data', () => {
  return fetchUserData('user123').then(result => {
    expect(result).toHaveProperty('email');
  });
});

// Con callbacks (evitar si es posible)
it('should fetch user data', (done) => {
  fetchUserData('user123', (error, result) => {
    expect(result).toHaveProperty('email');
    done();
  });
});
```

### Mocking

```typescript
// Mock de función simple
const mockFunction = jest.fn();
mockFunction.mockReturnValue('mocked value');

// Mock de módulo
jest.mock('../../services/EmailService', () => ({
  sendEmail: jest.fn().mockResolvedValue({ success: true })
}));

// Mock de dependencia
const mockRepository = {
  findById: jest.fn().mockResolvedValue({ id: '123', name: 'Test' }),
  save: jest.fn().mockResolvedValue({ id: '123' })
};
```

### Test Data Factories

```typescript
// Crear datos de prueba consistentes
function createTestProfessor(overrides = {}) {
  return {
    id: 'prof-123',
    email: 'professor@test.com',
    name: 'Test Professor',
    specialties: ['tennis'],
    hourlyRate: 50,
    ...overrides
  };
}

// Uso
const professor = createTestProfessor({ hourlyRate: 75 });
```

---

## 📊 Cobertura y Métricas

### Umbrales de Cobertura

```javascript
// jest.config.js
coverageThreshold: {
  global: {
    branches: 80,
    functions: 80,
    lines: 80,
    statements: 80
  }
}
```

### Visualizar Cobertura

```bash
# Generar reporte de cobertura
npm run test:coverage

# Abrir reporte HTML
open coverage/lcov-report/index.html
# o en Linux:
xdg-open coverage/lcov-report/index.html
```

### Interpretar Resultados

```
----------|---------|----------|---------|---------|-------------------
File      | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s 
----------|---------|----------|---------|---------|-------------------
All files |     95% |     92%  |   94%   |   95%   |                   
 auth.ts  |    100% |    100%  |  100%   |  100%   |                   
 user.ts  |     90% |     85%  |   92%   |   90%   | 45-48,52
----------|---------|----------|---------|---------|-------------------
```

**Explicación**:
- **% Stmts**: Porcentaje de statements ejecutados
- **% Branch**: Porcentaje de ramas (if/else) cubiertas
- **% Funcs**: Porcentaje de funciones ejecutadas
- **% Lines**: Porcentaje de líneas ejecutadas
- **Uncovered Line #s**: Líneas no cubiertas por tests

### Archivos Excluidos

```javascript
collectCoverageFrom: [
  'src/**/*.ts',
  '!src/**/*.d.ts',              // Definiciones de tipos
  '!src/__tests__/**',           // Tests mismos
  '!src/presentation/server.ts'  // Entry point
]
```

### Métricas del Proyecto

#### Cobertura Actual (Octubre 2025)

- **DTOs y Validaciones**: 100%
- **Repositories**: 95%
- **Controllers**: 88%
- **Middleware**: 92%
- **Use Cases**: 85%
- **Global**: 95%

---

## 🤝 Guía de Contribución

### Agregar Nuevos Tests

#### 1. Determinar el Tipo de Test

```
¿Prueba una función individual? → Unit Test
¿Prueba interacción entre componentes? → Integration Test
¿Prueba un endpoint HTTP completo? → E2E Test
```

#### 2. Crear el Archivo

```bash
# Tests unitarios
touch src/__tests__/unit/MyFeature.test.ts

# Tests de integración
touch src/__tests__/integration/my-feature-flow.test.ts

# Tests E2E
touch src/__tests__/e2e/my-feature-api.test.ts
```

#### 3. Seguir la Plantilla

```typescript
/**
 * Tests for FeatureName
 * Issue: TEN-XXX
 */

import { describe, it, expect } from '@jest/globals';

describe('FeatureName', () => {
  describe('Scenario', () => {
    it('should do something when condition', () => {
      // Test implementation
    });
  });
});
```

#### 4. Ejecutar y Verificar

```bash
# Ejecutar el nuevo test
npm test -- MyFeature.test.ts

# Verificar cobertura
npm run test:coverage -- MyFeature.test.ts

# Asegurar que cumple umbrales
# Cobertura debe ser > 80% en todos los aspectos
```

#### 5. Commitear con Mensaje Apropiado

```bash
git add src/__tests__/unit/MyFeature.test.ts
git commit -m "test(TEN-XXX): add tests for MyFeature

- Add unit tests for feature X
- Cover edge cases Y and Z
- Achieve 95% coverage"
```

### Checklist Pre-Commit

- [ ] Tests pasan localmente (`npm test`)
- [ ] Cobertura > 80% (`npm run test:coverage`)
- [ ] No hay errores de linting (`npm run lint`)
- [ ] Compilación exitosa (`npm run build`)
- [ ] Tests siguen convenciones del proyecto
- [ ] Nombres de tests son descriptivos
- [ ] Se usan factories para datos de prueba
- [ ] Mocks están bien configurados

### Estándares de Calidad

```typescript
// ✅ Buen test: claro, descriptivo, enfocado
describe('LoginSchema', () => {
  it('should reject invalid email format', () => {
    const result = LoginSchema.safeParse({
      email: 'not-an-email',
      password: 'pass123'
    });
    
    expect(result.success).toBe(false);
    expect(result.error.issues[0].path).toContain('email');
  });
});

// ❌ Mal test: vago, sin asserts claros
describe('Login', () => {
  it('works', () => {
    const result = doSomething();
    expect(result).toBeTruthy(); // Muy genérico
  });
});
```

---

## 🚨 Troubleshooting

### Problemas Comunes y Soluciones

#### 1. Tests Fallan Localmente pero Pasan en CI

**Síntomas**:
```
✓ Tests pasan en GitHub Actions
✗ Tests fallan en tu máquina local
```

**Soluciones**:
```bash
# Limpiar cache de Jest
npm test -- --clearCache

# Reinstalar dependencias
rm -rf node_modules package-lock.json
npm install

# Verificar versión de Node
node --version  # Debe ser >= 20.0.0

# Verificar variables de entorno
cat .env.test
```

#### 2. Timeout en Tests Asíncronos

**Síntomas**:
```
Timeout - Async callback was not invoked within the 10000 ms timeout
```

**Soluciones**:
```typescript
// Aumentar timeout para un test específico
it('should handle slow operation', async () => {
  // test code
}, 30000); // 30 segundos

// O en jest.config.js
testTimeout: 30000
```

#### 3. Memory Leaks

**Síntomas**:
```
Jest has detected the following open handles...
```

**Soluciones**:
```bash
# Detectar handles abiertos
npm test -- --detectOpenHandles

# Asegurar limpieza en afterAll
afterAll(async () => {
  await mongoServer.stop();
  await app.close();
});
```

#### 4. Mocks No Funcionan

**Síntomas**:
```
Called real implementation instead of mock
```

**Soluciones**:
```typescript
// Usar jest.mock ANTES de imports
jest.mock('../../services/EmailService');
import { EmailService } from '../../services/EmailService';

// O usar beforeEach
beforeEach(() => {
  jest.clearAllMocks();
});
```

#### 5. Cobertura Baja

**Síntomas**:
```
Coverage threshold not met: 75% < 80%
```

**Soluciones**:
```bash
# Ver qué líneas no están cubiertas
npm run test:coverage -- --verbose

# Revisar reporte HTML
open coverage/lcov-report/index.html

# Agregar tests para líneas faltantes
# Focus en branches (if/else, switch)
```

#### 6. Tests Intermitentes (Flaky)

**Síntomas**:
```
Test pasa a veces, falla otras veces
```

**Soluciones**:
```typescript
// Evitar dependencias de tiempo
// ❌ Mal
const start = Date.now();
await operation();
expect(Date.now() - start).toBeLessThan(1000);

// ✅ Bien
jest.useFakeTimers();
operation();
jest.advanceTimersByTime(1000);

// Evitar race conditions
// ❌ Mal
const promise1 = doSomething();
const promise2 = doSomethingElse();

// ✅ Bien
await promise1;
await promise2;
```

### Comandos de Debugging

```bash
# Ejecutar con información detallada
npm test -- --verbose

# Mostrar configuración de Jest
npm test -- --showConfig

# Ejecutar solo tests que fallaron
npm test -- --onlyFailures

# Ver información de memoria
npm test -- --logHeapUsage

# Detectar problemas de configuración
npm test -- --debug
```

### Logs y Debugging

```typescript
// Usar console.log en tests (solo para debugging)
it('should work', () => {
  console.log('Debug:', someVariable);
  expect(someVariable).toBe(expected);
});

// Usar debugger con Node Inspector
// package.json
"scripts": {
  "test:debug": "node --inspect-brk node_modules/.bin/jest --runInBand"
}

// Luego: chrome://inspect en Chrome
```

---

## 🎯 Mejores Prácticas

### 1. Principios Fundamentales

#### DRY (Don't Repeat Yourself)
```typescript
// ❌ Mal: Código repetido
it('test 1', () => {
  const user = { email: 'test@test.com', password: 'pass123' };
  const result = login(user);
  expect(result.success).toBe(true);
});

it('test 2', () => {
  const user = { email: 'test@test.com', password: 'pass123' };
  const result = login(user);
  expect(result.token).toBeDefined();
});

// ✅ Bien: Usar factories
const createTestUser = () => ({
  email: 'test@test.com',
  password: 'pass123'
});

it('test 1', () => {
  const result = login(createTestUser());
  expect(result.success).toBe(true);
});
```

#### FIRST Principles

- **Fast**: Tests deben ser rápidos (< 1s unitarios)
- **Independent**: Tests no deben depender de otros
- **Repeatable**: Mismo resultado siempre
- **Self-Validating**: Pass o fail, nada manual
- **Timely**: Escribir tests antes o durante desarrollo

### 2. Organización y Estructura

```typescript
// ✅ Buena organización
describe('UserService', () => {
  describe('createUser', () => {
    describe('when data is valid', () => {
      it('should create user successfully', () => {});
      it('should return user with id', () => {});
    });

    describe('when email is invalid', () => {
      it('should throw ValidationError', () => {});
    });
  });
});
```

### 3. Assertions Claras

```typescript
// ❌ Assertions vagas
expect(result).toBeTruthy();
expect(data).toBeDefined();

// ✅ Assertions específicas
expect(result.status).toBe(200);
expect(data.email).toBe('test@example.com');
expect(response.body).toMatchObject({
  success: true,
  userId: expect.any(String)
});
```

### 4. Testing de Errores

```typescript
// ✅ Testing de excepciones
it('should throw error when email is invalid', () => {
  expect(() => {
    validateEmail('invalid');
  }).toThrow('Invalid email format');
});

// ✅ Testing de async errors
it('should reject when user not found', async () => {
  await expect(
    findUser('nonexistent')
  ).rejects.toThrow('User not found');
});
```

### 5. Setup y Teardown

```typescript
describe('DatabaseTests', () => {
  let connection;

  // Setup: ejecutar antes de todos los tests
  beforeAll(async () => {
    connection = await createConnection();
  });

  // Teardown: ejecutar después de todos los tests
  afterAll(async () => {
    await connection.close();
  });

  // Reset: antes de cada test
  beforeEach(async () => {
    await connection.clear();
  });

  it('test 1', async () => {
    // Test con DB limpia
  });

  it('test 2', async () => {
    // Test con DB limpia de nuevo
  });
});
```

### 6. Mocking Estratégico

```typescript
// ✅ Mock solo lo necesario
jest.mock('../../services/EmailService', () => ({
  sendEmail: jest.fn().mockResolvedValue({ sent: true })
}));

// ✅ Mock con implementación específica por test
it('should handle email failure', () => {
  mockEmailService.sendEmail.mockRejectedValueOnce(
    new Error('SMTP Error')
  );
  
  // Test error handling
});
```

### 7. Test Data Management

```typescript
// ✅ Usar constants para datos de prueba
const VALID_EMAIL = 'test@example.com';
const INVALID_EMAIL = 'not-an-email';
const TEST_PASSWORD = 'SecurePass123!';

// ✅ Usar factories con builders
const professorBuilder = {
  withEmail: (email) => ({ ...baseProfessor, email }),
  withRate: (rate) => ({ ...baseProfessor, hourlyRate: rate })
};
```

### 8. Performance

```typescript
// ✅ Tests unitarios rápidos
it('should validate input', () => {
  // < 10ms
  expect(validate(input)).toBe(true);
});

// ✅ Tests de integración moderados
it('should save to database', async () => {
  // < 100ms con in-memory DB
  await repository.save(entity);
});

// ⚠️  Tests E2E más lentos (pero justificados)
it('should complete full flow', async () => {
  // < 1000ms para flujo completo
  await completeUserJourney();
});
```

### 9. Documentación en Tests

```typescript
// ✅ Tests como documentación
describe('Payment Processing', () => {
  it('should charge card when amount is valid', () => {
    // Este test documenta el comportamiento esperado
    const payment = { amount: 100, card: validCard };
    const result = processPayment(payment);
    expect(result.charged).toBe(true);
  });

  it('should reject payment when amount exceeds limit', () => {
    // Este test documenta una regla de negocio
    const payment = { amount: 10000, card: validCard };
    expect(() => processPayment(payment))
      .toThrow('Amount exceeds daily limit');
  });
});
```

### 10. Testing de Edge Cases

```typescript
describe('Edge Cases', () => {
  // Valores límite
  it('should accept minimum valid password length', () => {
    expect(validate('123456')).toBe(true); // Exactly 6 chars
  });

  // Valores null/undefined
  it('should reject null email', () => {
    expect(() => validate(null)).toThrow();
  });

  // Caracteres especiales
  it('should handle special characters in name', () => {
    expect(validate("O'Connor")).toBe(true);
  });

  // Valores extremos
  it('should handle very large numbers', () => {
    expect(calculate(Number.MAX_SAFE_INTEGER)).toBeDefined();
  });
});
```

---

## 🔄 CI/CD Integration

### GitHub Actions Workflow

Nuestro pipeline de CI/CD ejecuta tests automáticamente en cada push y pull request.

#### Configuración Actual

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Type Check
        run: npm run type-check
      
      - name: Build
        run: npm run build
      
      - name: Run Unit Tests
        run: npm run test:unit
      
      - name: Run Integration Tests
        run: npm run test:integration
      
      - name: Generate Coverage Report
        run: npm run test:coverage
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

#### Configuración Local para CI

```bash
# Simular pipeline de CI localmente
npm run lint && \
npm run type-check && \
npm run build && \
npm run test:ci
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [TypeScript Testing](https://jestjs.io/docs/getting-started#using-typescript)
- [Supertest](https://github.com/visionmedia/supertest)
- [MongoDB Memory Server](https://github.com/nodkz/mongodb-memory-server)
- [Zod Validation](https://zod.dev/)

### Guías y Tutoriales

- [Test-Driven Development (TDD)](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Testing Best Practices](https://testingjavascript.com/)
- [Jest Testing Patterns](https://jestjs.io/docs/patterns-and-best-practices)

### Issues Relacionados en Linear

- **TEN-67**: TS-011 - Testing de DTOs y Validaciones ✅
- **TEN-80**: TS-024 - Testing de Casos Edge y Performance ✅
- **TEN-81**: TS-025 - Configuración de CI/CD ✅
- **TEN-82**: TS-026 - Documentación de Testing ✅

---

## 📝 Changelog

| Fecha | Versión | Cambios | Issue |
|-------|---------|---------|-------|
| Oct 2025 | 2.0.0 | Documentación completa expandida | TEN-82 |
| Oct 2025 | 1.5.0 | Agregado testing de DTOs y performance | TEN-67, TEN-80 |
| Oct 2024 | 1.0.0 | Configuración inicial de testing | TEN-81 |

---

## 🤝 Contribuidores

- **Fernando Rodriguez** - Setup inicial y documentación
- **Team Tennis Management** - Contribuciones continuas

---

## 📞 Contacto y Soporte

Para preguntas sobre testing:
- Crear issue en Linear con etiqueta `testing`
- Revisar este documento primero
- Consultar con el equipo en reuniones de desarrollo

---

**Última actualización**: Octubre 2025  
**Versión**: 2.0.0  
**Mantenido por**: Tennis Management Team
