# Testing Utilities and Helpers Guide

## TEN-58: TS-002 - Utilidades y Helpers Base

Esta guía documenta todas las utilidades, factories y helpers disponibles para facilitar la escritura de tests en el proyecto.

---

## 📋 Tabla de Contenidos

1. [Test Data Factories](#test-data-factories)
2. [Mock Helpers](#mock-helpers)
3. [Assertion Helpers](#assertion-helpers)
4. [Database Helpers](#database-helpers)
5. [Time Helpers](#time-helpers)
6. [Global Test Utilities](#global-test-utilities)
7. [Fixtures](#fixtures)
8. [Mocks Globales](#mocks-globales)
9. [Ejemplos de Uso](#ejemplos-de-uso)

---

## 🏭 Test Data Factories

### TestDataFactory

Ubicación: `src/__tests__/utils/test-helpers.ts`

Proporciona métodos para crear datos de prueba consistentes y válidos.

### Métodos Disponibles

#### createUser(overrides?)

Crea un usuario de prueba genérico.

```typescript
import { TestDataFactory } from '../utils/test-helpers';

const user = TestDataFactory.createUser();
// {
//   id: 'test-user-id',
//   email: 'user@example.com',
//   role: 'student',
//   name: 'Test User'
// }

// Con personalización
const customUser = TestDataFactory.createUser({
  email: 'custom@example.com',
  role: 'professor'
});
```

#### createProfessor(overrides?)

Crea un profesor de prueba.

```typescript
const professor = TestDataFactory.createProfessor();
// {
//   id: 'test-professor-id',
//   name: 'Test Professor',
//   email: 'professor@example.com',
//   phone: '1234567890',
//   specialties: ['tennis'],
//   hourlyRate: 50,
//   experienceYears: 5
// }

// Personalizar hourly rate
const expensiveProfessor = TestDataFactory.createProfessor({
  hourlyRate: 100,
  specialties: ['tennis', 'padel']
});
```

#### createStudent(overrides?)

Crea un estudiante de prueba.

```typescript
const student = TestDataFactory.createStudent();
// {
//   id: 'test-student-id',
//   name: 'Test Student',
//   email: 'student@example.com',
//   phone: '0987654321',
//   membershipType: 'basic',
//   balance: 100
// }

// Estudiante premium con balance alto
const premiumStudent = TestDataFactory.createStudent({
  membershipType: 'premium',
  balance: 500
});
```

#### createSchedule(overrides?)

Crea un horario de profesor de prueba.

```typescript
const schedule = TestDataFactory.createSchedule();
// {
//   id: 'test-schedule-id',
//   professorId: 'test-professor-id',
//   date: new Date('2024-12-01'),
//   startTime: '10:00',
//   endTime: '11:00',
//   type: 'individual',
//   isAvailable: true
// }

// Horario grupal
const groupSchedule = TestDataFactory.createSchedule({
  type: 'group',
  maxStudents: 6,
  startTime: '14:00',
  endTime: '16:00'
});
```

#### createBooking(overrides?)

Crea una reserva de prueba.

```typescript
const booking = TestDataFactory.createBooking();
// {
//   id: 'test-booking-id',
//   studentId: 'test-student-id',
//   scheduleId: 'test-schedule-id',
//   type: 'lesson',
//   status: 'confirmed',
//   createdAt: Date
// }

// Reserva de cancha
const courtBooking = TestDataFactory.createBooking({
  type: 'court_rental',
  status: 'pending'
});
```

#### createPayment(overrides?)

Crea un pago de prueba.

```typescript
const payment = TestDataFactory.createPayment();
// {
//   id: 'test-payment-id',
//   studentId: 'test-student-id',
//   professorId: 'test-professor-id',
//   amount: 50,
//   date: Date,
//   method: 'card',
//   concept: 'Tennis lesson'
// }

// Pago en efectivo
const cashPayment = TestDataFactory.createPayment({
  method: 'cash',
  amount: 75
});
```

#### createService(overrides?)

Crea un servicio de prueba.

```typescript
const service = TestDataFactory.createService();
// {
//   id: 'test-service-id',
//   name: 'Racket Stringing',
//   description: 'Professional racket stringing service',
//   price: 25,
//   category: 'stringing'
// }

// Servicio de grip
const gripService = TestDataFactory.createService({
  name: 'Grip Replacement',
  category: 'grip',
  price: 10
});
```

#### createMessage(overrides?)

Crea un mensaje de prueba.

```typescript
const message = TestDataFactory.createMessage();
// {
//   id: 'test-message-id',
//   conversationId: 'test-conversation-id',
//   senderId: 'test-sender-id',
//   content: 'Test message content',
//   isRead: false,
//   createdAt: Date
// }
```

---

## 🎭 Mock Helpers

### MockHelper

Ubicación: `src/__tests__/utils/test-helpers.ts`

Proporciona mocks de objetos de Express y otros componentes comunes.

### Métodos Disponibles

#### createMockRequest(overrides?)

Crea un objeto Request de Express mockeado.

```typescript
import { MockHelper } from '../utils/test-helpers';

const mockReq = MockHelper.createMockRequest({
  body: { email: 'test@example.com', password: 'pass123' },
  params: { id: 'user-123' },
  query: { page: '1' },
  headers: { authorization: 'Bearer token' },
  user: { id: 'user-id', role: 'student' }
});

// Usar en tests de controllers
await controller.login(mockReq, mockRes, mockNext);
```

#### createMockResponse()

Crea un objeto Response de Express mockeado con métodos spy.

```typescript
const mockRes = MockHelper.createMockResponse();

// Los métodos son jest.fn() automáticamente
await controller.getUser(mockReq, mockRes);

expect(mockRes.status).toHaveBeenCalledWith(200);
expect(mockRes.json).toHaveBeenCalledWith({
  user: expect.any(Object)
});
```

#### createMockNextFunction()

Crea una función next mockeada para middleware.

```typescript
const mockNext = MockHelper.createMockNextFunction();

await middleware(mockReq, mockRes, mockNext);

expect(mockNext).toHaveBeenCalled();
expect(mockNext).toHaveBeenCalledWith(); // Sin errores
```

#### createMockUser(overrides?)

Crea un usuario mockeado para req.user.

```typescript
const mockUser = MockHelper.createMockUser({
  id: 'custom-id',
  role: 'professor'
});

const mockReq = MockHelper.createMockRequest({
  user: mockUser
});
```

---

## ✅ Assertion Helpers

### AssertionHelper

Ubicación: `src/__tests__/utils/test-helpers.ts`

Proporciona assertions comunes reutilizables.

### Métodos Disponibles

#### expectValidJWT(token)

Valida que un token tenga formato JWT válido.

```typescript
import { AssertionHelper } from '../utils/test-helpers';

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

AssertionHelper.expectValidJWT(token);
// Verifica:
// - Token está definido
// - Es string
// - Tiene 3 partes separadas por '.'
```

#### expectValidDate(date)

Valida que un objeto sea una fecha válida.

```typescript
const date = new Date();

AssertionHelper.expectValidDate(date);
// Verifica:
// - Es instancia de Date
// - getTime() no retorna NaN
```

#### expectValidObjectId(id)

Valida que un ID tenga formato de MongoDB ObjectId.

```typescript
const id = '507f1f77bcf86cd799439011';

AssertionHelper.expectValidObjectId(id);
// Verifica:
// - ID está definido
// - Es string
// - Cumple regex de ObjectId (24 caracteres hex)
```

#### expectErrorResponse(res, statusCode, message?)

Valida que una respuesta sea de error con el código apropiado.

```typescript
const mockRes = MockHelper.createMockResponse();

await controller.invalidOperation(mockReq, mockRes);

AssertionHelper.expectErrorResponse(mockRes, 400, 'Invalid input');
// Verifica:
// - res.status fue llamado con 400
// - res.json fue llamado
// - response tiene propiedad 'error'
// - error message coincide (si se proporciona)
```

---

## 🗄️ Database Helpers

### DatabaseTestHelper

Ubicación: `src/__tests__/utils/test-helpers.ts`

Helpers para manejo de base de datos en tests.

### Métodos Disponibles

#### setupTestDatabase()

Configura la base de datos de prueba (MongoDB Memory Server).

```typescript
import { DatabaseTestHelper } from '../utils/test-helpers';

beforeAll(async () => {
  await DatabaseTestHelper.setupTestDatabase();
});
```

#### cleanupTestDatabase()

Limpia y cierra la conexión de base de datos.

```typescript
afterAll(async () => {
  await DatabaseTestHelper.cleanupTestDatabase();
});
```

#### clearCollections()

Limpia todas las colecciones sin cerrar la conexión.

```typescript
beforeEach(async () => {
  await DatabaseTestHelper.clearCollections();
});
```

### Patrón de Uso Completo

```typescript
describe('Database Integration Test', () => {
  beforeAll(async () => {
    await DatabaseTestHelper.setupTestDatabase();
  });

  afterAll(async () => {
    await DatabaseTestHelper.cleanupTestDatabase();
  });

  beforeEach(async () => {
    await DatabaseTestHelper.clearCollections();
  });

  it('should work with clean database', async () => {
    // Cada test tiene DB limpia
  });
});
```

---

## ⏰ Time Helpers

### TimeHelper

Ubicación: `src/__tests__/utils/test-helpers.ts`

Helpers para manejo de tiempo en tests.

### Métodos Disponibles

#### sleep(ms)

Pausa la ejecución por milisegundos especificados.

```typescript
import { TimeHelper } from '../utils/test-helpers';

it('should handle delayed operation', async () => {
  startOperation();
  await TimeHelper.sleep(1000); // Esperar 1 segundo
  expect(operationCompleted()).toBe(true);
});
```

#### getFutureDate(days = 1)

Obtiene una fecha futura.

```typescript
const tomorrow = TimeHelper.getFutureDate(1);
const nextWeek = TimeHelper.getFutureDate(7);

const schedule = TestDataFactory.createSchedule({
  date: TimeHelper.getFutureDate(3) // 3 días en el futuro
});
```

#### getPastDate(days = 1)

Obtiene una fecha pasada.

```typescript
const yesterday = TimeHelper.getPastDate(1);
const lastMonth = TimeHelper.getPastDate(30);

const oldBooking = TestDataFactory.createBooking({
  createdAt: TimeHelper.getPastDate(7) // Hace 7 días
});
```

---

## 🌍 Global Test Utilities

### global.testUtils

Ubicación: `src/__tests__/jest.setup.js`

Utilities disponibles globalmente en todos los tests sin necesidad de importar.

### Métodos Disponibles

#### global.testUtils.createTestUser(overrides?)

```typescript
it('should create user', () => {
  const user = global.testUtils.createTestUser({
    name: 'Custom Name'
  });
  
  expect(user.email).toBe('test@example.com');
});
```

#### global.testUtils.createTestProfessor(overrides?)

```typescript
it('should handle professor', () => {
  const prof = global.testUtils.createTestProfessor({
    hourlyRate: 75
  });
  
  expect(prof.specialties).toContain('tennis');
});
```

#### global.testUtils.createTestStudent(overrides?)

```typescript
const student = global.testUtils.createTestStudent();
```

#### global.testUtils.createTestSchedule(overrides?)

```typescript
const schedule = global.testUtils.createTestSchedule();
```

#### global.testUtils.createTestBooking(overrides?)

```typescript
const booking = global.testUtils.createTestBooking();
```

---

## 📦 Fixtures

### Test Data Fixtures

Ubicación: `src/__tests__/fixtures/test-data.json`

Datos de prueba predefinidos en formato JSON.

### Uso

```typescript
import testData from '../fixtures/test-data.json';

it('should use fixture data', () => {
  const professor = testData.professors[0];
  expect(professor).toHaveProperty('name');
});
```

---

## 🎭 Mocks Globales

### External APIs Mocks

Ubicación: `src/__tests__/mocks/external-apis.ts`

Mocks para servicios externos como Firebase, APIs de terceros, etc.

### Uso

```typescript
// Los mocks se configuran automáticamente en jest.setup.js
// No necesitas importarlos manualmente

it('should use mocked external service', async () => {
  // Firebase ya está mockeado globalmente
  const result = await firebaseAuth.verifyToken('token');
  expect(result).toBeDefined();
});
```

---

## 💡 Ejemplos de Uso

### Ejemplo 1: Test de Controller con Mocks

```typescript
import { describe, it, expect } from '@jest/globals';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';
import { ProfessorController } from '../../application/controllers/ProfessorController';

describe('ProfessorController', () => {
  let controller: ProfessorController;
  let mockReq: any;
  let mockRes: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new ProfessorController();
    mockReq = MockHelper.createMockRequest();
    mockRes = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  it('should publish schedule successfully', async () => {
    const professor = TestDataFactory.createProfessor();
    const scheduleData = {
      date: '2025-10-15',
      startTime: '09:00',
      endTime: '10:00',
      type: 'individual'
    };

    mockReq.body = scheduleData;
    mockReq.user = { id: professor.id, role: 'professor' };

    await controller.publishSchedule(mockReq, mockRes, mockNext);

    expect(mockRes.status).toHaveBeenCalledWith(201);
    expect(mockRes.json).toHaveBeenCalled();
  });
});
```

### Ejemplo 2: Test de Repository con Database Helper

```typescript
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@jest/globals';
import { DatabaseTestHelper, TestDataFactory } from '../utils/test-helpers';
import { ProfessorRepository } from '../../infrastructure/repositories/ProfessorRepository';

describe('ProfessorRepository', () => {
  let repository: ProfessorRepository;

  beforeAll(async () => {
    await DatabaseTestHelper.setupTestDatabase();
    repository = new ProfessorRepository();
  });

  afterAll(async () => {
    await DatabaseTestHelper.cleanupTestDatabase();
  });

  beforeEach(async () => {
    await DatabaseTestHelper.clearCollections();
  });

  it('should save professor to database', async () => {
    const professor = TestDataFactory.createProfessor();
    
    const saved = await repository.save(professor);
    
    expect(saved).toHaveProperty('id');
    expect(saved.name).toBe(professor.name);
  });
});
```

### Ejemplo 3: Test con Assertion Helpers

```typescript
import { describe, it, expect } from '@jest/globals';
import { AssertionHelper } from '../utils/test-helpers';
import { AuthService } from '../../infrastructure/auth/AuthService';

describe('AuthService', () => {
  it('should generate valid JWT token', async () => {
    const token = await authService.generateToken({
      userId: 'user-123',
      role: 'student'
    });

    // Usar helper para validar JWT
    AssertionHelper.expectValidJWT(token);
  });

  it('should create valid dates', () => {
    const expiresAt = authService.getTokenExpiration();
    
    // Usar helper para validar Date
    AssertionHelper.expectValidDate(expiresAt);
  });
});
```

### Ejemplo 4: Test con Time Helpers

```typescript
import { describe, it, expect } from '@jest/globals';
import { TimeHelper, TestDataFactory } from '../utils/test-helpers';

describe('Booking Expiration', () => {
  it('should mark booking as expired after 24 hours', async () => {
    const oldBooking = TestDataFactory.createBooking({
      createdAt: TimeHelper.getPastDate(2) // Hace 2 días
    });

    const isExpired = checkBookingExpiration(oldBooking);
    expect(isExpired).toBe(true);
  });

  it('should allow future bookings', () => {
    const futureSchedule = TestDataFactory.createSchedule({
      date: TimeHelper.getFutureDate(7) // En 7 días
    });

    expect(isScheduleAvailable(futureSchedule)).toBe(true);
  });
});
```

### Ejemplo 5: Test Completo con Todos los Helpers

```typescript
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@jest/globals';
import {
  DatabaseTestHelper,
  MockHelper,
  TestDataFactory,
  AssertionHelper,
  TimeHelper
} from '../utils/test-helpers';

describe('Complete Booking Flow', () => {
  let mockReq: any;
  let mockRes: any;

  beforeAll(async () => {
    await DatabaseTestHelper.setupTestDatabase();
  });

  afterAll(async () => {
    await DatabaseTestHelper.cleanupTestDatabase();
  });

  beforeEach(async () => {
    await DatabaseTestHelper.clearCollections();
    mockReq = MockHelper.createMockRequest();
    mockRes = MockHelper.createMockResponse();
  });

  it('should complete full booking flow', async () => {
    // Crear datos de prueba
    const professor = TestDataFactory.createProfessor();
    const student = TestDataFactory.createStudent();
    const schedule = TestDataFactory.createSchedule({
      professorId: professor.id,
      date: TimeHelper.getFutureDate(3)
    });

    // Guardar en DB
    await saveProfessor(professor);
    await saveStudent(student);
    await saveSchedule(schedule);

    // Hacer booking
    mockReq.body = {
      studentId: student.id,
      scheduleId: schedule.id
    };

    await bookingController.create(mockReq, mockRes);

    // Validar respuesta
    expect(mockRes.status).toHaveBeenCalledWith(201);
    
    const response = mockRes.json.mock.calls[0][0];
    AssertionHelper.expectValidObjectId(response.bookingId);
    AssertionHelper.expectValidDate(response.createdAt);
  });
});
```

---

## 🎯 Mejores Prácticas

### 1. Usar Factories en lugar de Objetos Literales

```typescript
// ❌ Mal: Objetos literales repetidos
it('test 1', () => {
  const user = { id: '1', name: 'Test', email: 'test@test.com' };
});

it('test 2', () => {
  const user = { id: '1', name: 'Test', email: 'test@test.com' };
});

// ✅ Bien: Usar factory
it('test 1', () => {
  const user = TestDataFactory.createUser();
});

it('test 2', () => {
  const user = TestDataFactory.createUser();
});
```

### 2. Personalizar Solo lo Necesario

```typescript
// ✅ Bien: Override solo campos relevantes
const expensiveProfessor = TestDataFactory.createProfessor({
  hourlyRate: 150 // Solo cambiar lo que importa para el test
});
```

### 3. Combinar Helpers

```typescript
// ✅ Excelente: Usar múltiples helpers juntos
it('should handle future booking', () => {
  const schedule = TestDataFactory.createSchedule({
    date: TimeHelper.getFutureDate(5)
  });
  
  const booking = TestDataFactory.createBooking({
    scheduleId: schedule.id,
    createdAt: new Date()
  });
  
  AssertionHelper.expectValidDate(schedule.date);
  AssertionHelper.expectValidObjectId(booking.id);
});
```

### 4. Usar Global Utils en Tests Simples

```typescript
// Para tests simples, usar global.testUtils (no requiere import)
it('simple test', () => {
  const user = global.testUtils.createTestUser();
  expect(user.email).toBe('test@example.com');
});
```

### 5. Limpiar Database Entre Tests

```typescript
// ✅ Siempre limpiar DB en beforeEach
beforeEach(async () => {
  await DatabaseTestHelper.clearCollections();
  jest.clearAllMocks(); // También limpiar mocks
});
```

---

## 📚 Referencia Rápida

### Import Statement

```typescript
import {
  TestDataFactory,
  MockHelper,
  AssertionHelper,
  DatabaseTestHelper,
  TimeHelper
} from '../utils/test-helpers';
```

### Todas las Factories Disponibles

| Factory | Método | Retorna |
|---------|--------|---------|
| TestDataFactory | createUser() | User object |
| TestDataFactory | createProfessor() | Professor object |
| TestDataFactory | createStudent() | Student object |
| TestDataFactory | createSchedule() | Schedule object |
| TestDataFactory | createBooking() | Booking object |
| TestDataFactory | createPayment() | Payment object |
| TestDataFactory | createService() | Service object |
| TestDataFactory | createMessage() | Message object |

### Todos los Mock Helpers

| Helper | Método | Retorna |
|--------|--------|---------|
| MockHelper | createMockRequest() | Express Request mock |
| MockHelper | createMockResponse() | Express Response mock |
| MockHelper | createMockNextFunction() | Express NextFunction mock |
| MockHelper | createMockUser() | User object for req.user |

### Todos los Assertion Helpers

| Helper | Método | Propósito |
|--------|--------|-----------|
| AssertionHelper | expectValidJWT(token) | Validar JWT format |
| AssertionHelper | expectValidDate(date) | Validar Date object |
| AssertionHelper | expectValidObjectId(id) | Validar MongoDB ID |
| AssertionHelper | expectErrorResponse(res, code, msg) | Validar error response |

### Todos los Database Helpers

| Helper | Método | Propósito |
|--------|--------|-----------|
| DatabaseTestHelper | setupTestDatabase() | Iniciar DB de prueba |
| DatabaseTestHelper | cleanupTestDatabase() | Cerrar DB de prueba |
| DatabaseTestHelper | clearCollections() | Limpiar datos |

### Todos los Time Helpers

| Helper | Método | Propósito |
|--------|--------|-----------|
| TimeHelper | sleep(ms) | Pausar ejecución |
| TimeHelper | getFutureDate(days) | Fecha futura |
| TimeHelper | getPastDate(days) | Fecha pasada |

---

## 🔧 Extender Helpers

### Agregar Nuevas Factories

```typescript
// En test-helpers.ts
export class TestDataFactory {
  // ... factories existentes
  
  static createConversation(overrides: any = {}) {
    return {
      id: 'test-conversation-id',
      participants: ['user1', 'user2'],
      lastMessage: 'Hello',
      createdAt: new Date(),
      ...overrides
    };
  }
}
```

### Agregar Nuevos Assertion Helpers

```typescript
export class AssertionHelper {
  // ... helpers existentes
  
  static expectValidEmail(email: string) {
    expect(email).toMatch(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);
  }
  
  static expectValidPhoneNumber(phone: string) {
    expect(phone).toMatch(/^\d{10,}$/);
  }
}
```

---

## 📝 Definition of Done - Status

- [x] ✅ Crear factory de mocks para todas las entidades
- [x] ✅ Crear helpers para setup/teardown de tests
- [x] ✅ Configurar mocks globales para servicios externos
- [x] ✅ Crear fixtures de datos de prueba
- [x] ✅ Documentar uso de utilities de testing

---

## 🔗 Archivos Relacionados

- **Main Helpers**: `src/__tests__/utils/test-helpers.ts`
- **Global Setup**: `src/__tests__/jest.setup.js`
- **Fixtures**: `src/__tests__/fixtures/test-data.json`
- **External Mocks**: `src/__tests__/mocks/external-apis.ts`
- **Type Definitions**: `src/__tests__/types/global.d.ts`

---

**Issue**: TEN-58  
**Fecha**: Octubre 2025  
**Estado**: ✅ Completado  
**Líneas de Código**: 206 líneas de helpers  
**Documentación**: Este archivo

