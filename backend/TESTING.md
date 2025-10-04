# Testing Guide - Tennis Management Backend

## 📋 Resumen

Este documento describe la configuración completa de testing para el proyecto Tennis Management Backend, implementada como parte de **TEN-81: TS-025: Configuración de CI/CD**.

## 🏗️ Arquitectura de Testing

### Stack Tecnológico
- **Jest**: Framework de testing principal
- **ts-jest**: Soporte para TypeScript
- **supertest**: Testing de APIs HTTP
- **mongodb-memory-server**: Base de datos en memoria para tests
- **jest-mock-extended**: Mocking avanzado
- **testcontainers**: Testing con contenedores reales (para E2E)

### Estructura de Directorios
```
src/__tests__/
├── unit/                    # Tests unitarios
├── integration/            # Tests de integración
├── e2e/                   # Tests end-to-end
├── utils/                 # Utilidades de testing
├── fixtures/              # Datos de prueba
├── mocks/                 # Mocks de servicios externos
├── types/                 # Definiciones de tipos
├── jest.setup.js          # Configuración global de Jest
└── README.md              # Documentación de testing
```

## 🚀 Comandos de Testing

### Comandos Principales
```bash
# Ejecutar todos los tests
npm test

# Ejecutar tests en modo watch
npm run test:watch

# Ejecutar tests con cobertura
npm run test:coverage

# Ejecutar solo tests unitarios
npm run test:unit

# Ejecutar solo tests de integración
npm run test:integration

# Ejecutar solo tests E2E
npm run test:e2e

# Ejecutar tests para CI/CD
npm run test:ci
```

## 📊 Configuración de Cobertura

### Umbrales de Cobertura
- **Statements**: 80%
- **Branches**: 80%
- **Functions**: 80%
- **Lines**: 80%

### Archivos Excluidos de Cobertura
- `src/__tests__/**` - Archivos de testing
- `src/presentation/server.ts` - Punto de entrada del servidor
- `src/**/*.d.ts` - Definiciones de tipos

## 🧪 Tipos de Tests

### 1. Tests Unitarios
- **Ubicación**: `src/__tests__/unit/`
- **Propósito**: Probar funciones y clases individuales
- **Configuración**: `jest.config.js`
- **Ejemplo**: Tests de entidades, servicios, use cases

### 2. Tests de Integración
- **Ubicación**: `src/__tests__/integration/`
- **Propósito**: Probar flujos completos entre componentes
- **Configuración**: `jest.integration.config.js`
- **Ejemplo**: Tests de controladores con repositorios

### 3. Tests E2E
- **Ubicación**: `src/__tests__/e2e/`
- **Propósito**: Probar APIs completas
- **Configuración**: `jest.e2e.config.js`
- **Ejemplo**: Tests de endpoints con base de datos real

## 🔧 Utilidades de Testing

### Test Helpers
```typescript
import { TestDataFactory, MockHelper, AssertionHelper } from '../utils/test-helpers';

// Crear datos de prueba
const professor = TestDataFactory.createProfessor();
const student = TestDataFactory.createStudent();

// Crear mocks
const mockReq = MockHelper.createMockRequest();
const mockRes = MockHelper.createMockResponse();

// Validaciones
AssertionHelper.expectValidJWT(token);
AssertionHelper.expectValidDate(date);
```

### Global Test Utils
```typescript
// Disponibles globalmente en todos los tests
const user = global.testUtils.createTestUser();
const professor = global.testUtils.createTestProfessor();
const student = global.testUtils.createTestStudent();
```

## 🗄️ Datos de Prueba

### Fixtures
- **Ubicación**: `src/__tests__/fixtures/test-data.json`
- **Contenido**: Datos predefinidos para tests
- **Uso**: Importar y usar en tests

### Mocks
- **Ubicación**: `src/__tests__/mocks/external-apis.ts`
- **Servicios**: Firebase, MongoDB, JWT, Bcrypt
- **Uso**: Mockear servicios externos

## 🚀 CI/CD Integration

### GitHub Actions
El pipeline de CI/CD incluye:

1. **Linting**: ESLint para calidad de código
2. **Type Checking**: TypeScript compilation check
3. **Build**: Compilación del proyecto
4. **Unit Tests**: Tests unitarios con cobertura
5. **Integration Tests**: Tests de integración
6. **Coverage Report**: Reporte de cobertura

### Configuración
```yaml
# .github/workflows/ci-cd.yml
- name: Run unit tests
  run: npm run test:unit

- name: Run integration tests
  run: npm run test:integration

- name: Generate coverage report
  run: npm run test:coverage
```

## 📝 Escribir Tests

### Estructura de un Test
```typescript
describe('Feature Name', () => {
  describe('Method Name', () => {
    it('should do something when condition', () => {
      // Arrange
      const input = 'test data';
      
      // Act
      const result = methodUnderTest(input);
      
      // Assert
      expect(result).toBe('expected output');
    });
  });
});
```

### Mejores Prácticas

1. **Nombres Descriptivos**: Usar nombres que expliquen qué hace el test
2. **AAA Pattern**: Arrange, Act, Assert
3. **Un Test, Una Aserción**: Un test debe probar una cosa
4. **Mocks Apropiados**: Mockear dependencias externas
5. **Datos de Prueba**: Usar factories para crear datos consistentes

## 🔍 Debugging Tests

### Comandos Útiles
```bash
# Ejecutar un test específico
npm test -- --testNamePattern="should create user"

# Ejecutar tests en un archivo específico
npm test -- setup.test.ts

# Ejecutar con verbose output
npm test -- --verbose

# Ejecutar tests con debugging
npm test -- --detectOpenHandles
```

### Variables de Entorno
```bash
# Para tests
NODE_ENV=test
JWT_SECRET=test-jwt-secret-key-for-testing-only
MONGO_URI=mongodb://localhost:27017/tennis-management-test
```

## 📊 Métricas y Reportes

### Coverage Report
- **Ubicación**: `coverage/` (generado automáticamente)
- **Formato**: HTML, JSON, LCOV
- **Visualización**: Abrir `coverage/lcov-report/index.html`

### Test Results
- **Console Output**: Resultados en consola
- **JUnit Format**: Para CI/CD integration
- **Coverage Badges**: Para README

## 🚨 Troubleshooting

### Problemas Comunes

1. **Tests Failing**: Verificar configuración de Jest
2. **Coverage Low**: Revisar umbrales en `jest.config.js`
3. **Type Errors**: Verificar tipos en `src/__tests__/types/`
4. **Mock Issues**: Revisar configuración de mocks

### Logs Útiles
```bash
# Ver logs detallados
npm test -- --verbose

# Ver configuración de Jest
npm test -- --showConfig

# Ver información de cobertura
npm run test:coverage -- --verbose
```

## 📚 Recursos Adicionales

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [TypeScript Testing](https://jestjs.io/docs/getting-started#using-typescript)
- [Supertest API Testing](https://github.com/visionmedia/supertest)
- [MongoDB Memory Server](https://github.com/nodkz/mongodb-memory-server)

## 🤝 Contribución

### Agregar Nuevos Tests
1. Crear archivo en directorio apropiado (`unit/`, `integration/`, `e2e/`)
2. Seguir convención de nombres: `*.test.ts`
3. Usar utilidades existentes cuando sea posible
4. Mantener cobertura de código > 80%

### Actualizar Configuración
1. Modificar archivos de configuración de Jest
2. Actualizar este README si es necesario
3. Verificar que todos los tests pasen
4. Actualizar cobertura si es necesario

---

**Configurado como parte de TEN-81: TS-025: Configuración de CI/CD**  
**Fecha**: Octubre 2024  
**Versión**: 1.0
