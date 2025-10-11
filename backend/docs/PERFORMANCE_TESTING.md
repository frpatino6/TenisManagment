# Performance Testing Documentation

## TEN-80: TS-024 - Testing de Casos Edge y Performance

Esta documentación describe los tests de performance, casos edge, y pruebas de carga implementados para el sistema de gestión de tenis.

---

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Tipos de Tests](#tipos-de-tests)
3. [Configuración](#configuración)
4. [Tests de Errores HTTP](#tests-de-errores-http)
5. [Tests de Rate Limiting](#tests-de-rate-limiting)
6. [Tests de Middleware de Seguridad](#tests-de-middleware-de-seguridad)
7. [Tests de Performance](#tests-de-performance)
8. [Tests de Carga Concurrente](#tests-de-carga-concurrente)
9. [Tests de Timeout y Recuperación](#tests-de-timeout-y-recuperación)
10. [Métricas de Performance](#métricas-de-performance)
11. [Cómo Ejecutar los Tests](#cómo-ejecutar-los-tests)
12. [Interpretación de Resultados](#interpretación-de-resultados)
13. [Mejores Prácticas](#mejores-prácticas)

---

## Descripción General

El conjunto de tests de edge cases y performance (`edge-cases-and-performance.test.ts`) está diseñado para validar el comportamiento del sistema bajo condiciones extremas y garantizar que el API mantiene un rendimiento aceptable bajo carga.

### Objetivos

- ✅ Validar manejo correcto de errores HTTP (400, 401, 403, 404, 500)
- ✅ Verificar funcionamiento del rate limiting
- ✅ Asegurar que el middleware de seguridad funciona correctamente
- ✅ Medir tiempos de respuesta bajo diferentes cargas
- ✅ Probar comportamiento con múltiples usuarios concurrentes
- ✅ Validar recuperación ante timeouts y errores

---

## Tipos de Tests

### 1. Tests de Errores HTTP

Validan que el API responde correctamente con los códigos de estado HTTP apropiados.

**Códigos Cubiertos:**
- `400 Bad Request` - Solicitudes malformadas
- `401 Unauthorized` - Autenticación fallida
- `403 Forbidden` - Permisos insuficientes
- `404 Not Found` - Recursos no encontrados
- `500 Internal Server Error` - Errores del servidor

### 2. Tests de Rate Limiting

Verifican que los límites de tasa se aplican correctamente para prevenir abuso.

**Límites Configurados:**
- **Auth endpoints**: 5 requests por 15 minutos
- **General endpoints**: 100 requests por 15 minutos

### 3. Tests de Seguridad

Validan que los middleware de seguridad (Helmet) están activos y configurados correctamente.

**Validaciones:**
- Headers de seguridad presentes
- Límite de payload (10MB)
- Validación de Content-Type
- Protección XSS

### 4. Tests de Performance

Miden tiempos de respuesta y throughput del sistema.

**Métricas:**
- Tiempo de respuesta promedio
- Throughput (requests/segundo)
- Latencia bajo carga
- Tiempo de respuesta máximo/mínimo

### 5. Tests de Carga Concurrente

Simulan múltiples usuarios accediendo al sistema simultáneamente.

**Escenarios:**
- 10-20 usuarios concurrentes
- 50-100 requests simultáneas
- Operaciones mixtas (login, GET, POST)

### 6. Tests de Timeout y Recuperación

Validan el comportamiento del sistema ante timeouts y su capacidad de recuperación.

---

## Configuración

### Dependencias Requeridas

```json
{
  "supertest": "^7.1.4",
  "jest": "^30.2.0",
  "express-rate-limit": "^6.7.0",
  "helmet": "^6.0.0"
}
```

### Variables de Entorno

```env
# Test Configuration
TEST_TIMEOUT=10000
RATE_LIMIT_WINDOW=900000  # 15 minutes in ms
RATE_LIMIT_MAX=100
AUTH_RATE_LIMIT_MAX=5
```

---

## Tests de Errores HTTP

### 400 - Bad Request

**Casos Cubiertos:**
- ✅ Campos requeridos faltantes
- ✅ JSON malformado
- ✅ Email inválido
- ✅ Valores null/undefined

```typescript
// Ejemplo
await request(app)
  .post('/api/auth/login')
  .send({})  // Sin email ni password
  .expect(400);
```

### 401 - Unauthorized

**Casos Cubiertos:**
- ✅ Credenciales inválidas
- ✅ Token ausente
- ✅ Token inválido

```typescript
// Ejemplo
await request(app)
  .get('/api/protected')
  .expect(401);  // Sin token
```

### 403 - Forbidden

**Casos Cubiertos:**
- ✅ Permisos insuficientes
- ✅ Acceso a recursos de admin sin rol admin

```typescript
// Ejemplo
await request(app)
  .get('/api/admin/users')
  .set('Authorization', 'Bearer valid-token')
  .expect(403);  // Usuario sin rol admin
```

### 404 - Not Found

**Casos Cubiertos:**
- ✅ Rutas inexistentes
- ✅ Recursos no encontrados

```typescript
// Ejemplo
await request(app)
  .get('/api/nonexistent')
  .expect(404);
```

### 500 - Internal Server Error

**Casos Cubiertos:**
- ✅ Errores no manejados
- ✅ Excepciones del servidor

```typescript
// Ejemplo
await request(app)
  .get('/api/error')
  .expect(500);
```

---

## Tests de Rate Limiting

### Configuración

```typescript
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutos
  max: 5,                     // 5 requests máximo
  message: 'Too many requests from this IP'
});
```

### Tests Implementados

#### Test 1: Límite en Endpoints de Auth

```typescript
it('should enforce rate limiting on auth endpoints', async () => {
  // Hacer 5 requests (el límite)
  for (let i = 0; i < 5; i++) {
    await request(app)
      .post('/api/auth/login')
      .send(loginData)
      .expect(401);
  }
  
  // La 6ta request debe ser bloqueada
  await request(app)
    .post('/api/auth/login')
    .send(loginData)
    .expect(429);  // Too Many Requests
});
```

#### Test 2: Headers de Rate Limit

Verifica que se incluyen los headers:
- `RateLimit-Limit`
- `RateLimit-Remaining`
- `RateLimit-Reset`

---

## Tests de Middleware de Seguridad

### Helmet Security Headers

**Headers Validados:**
```
✅ X-Content-Type-Options: nosniff
✅ X-Frame-Options: DENY
✅ X-XSS-Protection: 1; mode=block
✅ Strict-Transport-Security
```

### Límite de Payload

```typescript
it('should reject excessively large payloads', async () => {
  const largeData = { data: 'x'.repeat(11 * 1024 * 1024) }; // 11MB
  
  await request(app)
    .post('/api/large-payload')
    .send(largeData)
    .expect(413);  // Payload Too Large
});
```

### Validación de Content-Type

Verifica que solo se acepten tipos de contenido válidos (`application/json`).

---

## Tests de Performance

### Test 1: Tiempo de Respuesta Individual

**Objetivo:** Verificar que requests individuales se completan rápidamente.

```typescript
it('should respond to health check within 100ms', async () => {
  const startTime = Date.now();
  
  await request(app)
    .get('/health')
    .expect(200);
  
  const duration = Date.now() - startTime;
  expect(duration).toBeLessThan(100);
});
```

**Criterio de Éxito:** < 100ms

### Test 2: Requests Secuenciales

**Objetivo:** Medir performance bajo carga secuencial.

```typescript
it('should handle 100 sequential requests', async () => {
  for (let i = 0; i < 100; i++) {
    await request(app).get('/health').expect(200);
  }
  
  const avgResponseTime = duration / 100;
  expect(avgResponseTime).toBeLessThan(100);
});
```

**Criterio de Éxito:** Promedio < 100ms por request

### Test 3: Operaciones Mixtas

**Objetivo:** Validar performance con diferentes tipos de operaciones.

```typescript
it('should maintain performance under mixed operations', async () => {
  const operations = [
    request(app).get('/health'),
    request(app).post('/api/auth/login').send(loginData),
    request(app).get('/api/protected'),
    // ... más operaciones
  ];
  
  await Promise.all(operations);
  expect(duration).toBeLessThan(1000);
});
```

**Criterio de Éxito:** < 1 segundo para todas las operaciones

---

## Tests de Carga Concurrente

### Test 1: 50 Requests Concurrentes

**Escenario:** Simular 50 usuarios accediendo simultáneamente.

```typescript
it('should handle 50 concurrent requests', async () => {
  const requests = Array(50)
    .fill(null)
    .map(() => request(app).get('/health'));
  
  const responses = await Promise.all(requests);
  
  expect(responses).toHaveLength(50);
  expect(duration).toBeLessThan(5000);
});
```

**Criterios de Éxito:**
- ✅ Todas las requests completan exitosamente
- ✅ Tiempo total < 5 segundos
- ✅ Sin errores de servidor

### Test 2: 10 Logins Concurrentes

**Escenario:** Múltiples usuarios intentando login simultáneamente.

```typescript
it('should handle 10 concurrent user login attempts', async () => {
  const loginRequests = Array(10)
    .fill(null)
    .map((_, i) => 
      request(app)
        .post('/api/auth/login')
        .send({ email: `user${i}@example.com`, password: 'pass' })
    );
  
  await Promise.all(loginRequests);
});
```

**Criterios de Éxito:**
- ✅ Todas las requests procesadas
- ✅ Tiempo total < 3 segundos
- ✅ Rate limiting funciona correctamente

### Test 3: Operaciones Mixtas Concurrentes

**Escenario:** Simular comportamiento real con múltiples tipos de operaciones.

```typescript
it('should handle mixed concurrent operations', async () => {
  const operations = [
    // User 1
    request(app).post('/api/auth/login').send(user1Data),
    request(app).get('/api/protected'),
    
    // User 2
    request(app).post('/api/auth/login').send(user2Data),
    request(app).get('/health'),
    
    // ... más operaciones
  ];
  
  const responses = await Promise.all(operations);
  expect(responses.every(r => r.status > 0)).toBe(true);
});
```

---

## Tests de Timeout y Recuperación

### Test 1: Timeout en Endpoints Lentos

**Objetivo:** Verificar que el sistema maneja timeouts correctamente.

```typescript
it('should timeout on slow endpoints', async () => {
  try {
    await request(app)
      .get('/api/slow?delay=5000')
      .timeout(2000);  // 2 segundo timeout
    
    fail('Request should have timed out');
  } catch (error) {
    expect(error.code).toBe('ECONNABORTED');
  }
});
```

### Test 2: Recuperación Post-Timeout

**Objetivo:** Asegurar que el sistema se recupera después de un timeout.

```typescript
it('should recover after timeout errors', async () => {
  // Primera request con timeout
  try {
    await request(app)
      .get('/api/slow?delay=5000')
      .timeout(1000);
  } catch (error) {
    // Expected
  }
  
  // Segunda request debe funcionar normalmente
  const response = await request(app)
    .get('/health')
    .expect(200);
  
  expect(response.body.status).toBe('healthy');
});
```

---

## Métricas de Performance

### Métricas Recolectadas

#### 1. Tiempo de Respuesta

```typescript
const responseTimes: number[] = [];

for (let i = 0; i < iterations; i++) {
  const start = Date.now();
  await request(app).get('/health');
  responseTimes.push(Date.now() - start);
}

const metrics = {
  avg: responseTimes.reduce((a, b) => a + b) / iterations,
  min: Math.min(...responseTimes),
  max: Math.max(...responseTimes)
};
```

**Valores Esperados:**
- Promedio: < 200ms
- Máximo: < 500ms
- Mínimo: < 50ms

#### 2. Throughput (Requests/segundo)

```typescript
const duration = 2000; // 2 segundos
let requestCount = 0;

while (Date.now() - startTime < duration) {
  await request(app).get('/health');
  requestCount++;
}

const throughput = requestCount / (duration / 1000);
```

**Valor Esperado:** > 10 requests/segundo

#### 3. Tasa de Éxito

```typescript
const totalRequests = 100;
const successfulRequests = responses.filter(r => r.status === 200).length;
const successRate = (successfulRequests / totalRequests) * 100;
```

**Valor Esperado:** > 99%

---

## Cómo Ejecutar los Tests

### Ejecutar Todos los Tests E2E

```bash
npm run test:e2e
```

### Ejecutar Solo Tests de Performance

```bash
npm run test:e2e -- edge-cases-and-performance
```

### Ejecutar con Cobertura

```bash
npm run test:coverage -- --testPathPattern=edge-cases-and-performance
```

### Ejecutar Tests Específicos

```bash
# Solo tests de errores HTTP
npm run test:e2e -- --testNamePattern="HTTP Error Status Codes"

# Solo tests de performance
npm run test:e2e -- --testNamePattern="Performance Tests"

# Solo tests de carga
npm run test:e2e -- --testNamePattern="Load Tests"
```

### Ejecutar en Modo Watch

```bash
npm run test:watch -- edge-cases-and-performance
```

---

## Interpretación de Resultados

### Resultados Exitosos

```
PASS  src/__tests__/e2e/edge-cases-and-performance.test.ts
  Edge Cases and Performance Tests
    HTTP Error Status Codes
      ✓ should return 400 for missing required fields (45ms)
      ✓ should return 401 for invalid credentials (32ms)
      ✓ should return 403 for insufficient permissions (28ms)
      ✓ should return 404 for nonexistent routes (25ms)
      ✓ should return 500 for internal errors (30ms)
    Rate Limiting
      ✓ should enforce rate limiting on auth endpoints (125ms)
    Performance Tests
      ✓ should respond within 100ms (25ms)
      ✓ should handle 50 concurrent requests (1250ms)
```

### Análisis de Métricas

**Métricas de Ejemplo:**
```
Performance Metrics (10 requests):
  Average: 45.20ms
  Min: 32ms
  Max: 67ms

Throughput: 22.50 requests/second
```

**Interpretación:**
- ✅ Promedio < 100ms → Excelente
- ✅ Max < 100ms → Muy bueno
- ✅ Throughput > 20 req/s → Excelente

### Señales de Alerta

⚠️ **Tiempos de Respuesta Altos**
```
Average: 350ms  // > 200ms
Max: 1200ms     // > 500ms
```
**Acción:** Investigar cuellos de botella

⚠️ **Rate Limiting No Funciona**
```
✗ should enforce rate limiting (Expected 429, received 401)
```
**Acción:** Verificar configuración de express-rate-limit

⚠️ **Timeouts Frecuentes**
```
✗ Multiple timeout errors in concurrent tests
```
**Acción:** Revisar recursos del servidor y optimizar queries

---

## Mejores Prácticas

### 1. Ejecución Regular

- ✅ Ejecutar tests de performance antes de cada release
- ✅ Incluir en pipeline de CI/CD
- ✅ Monitorear tendencias a lo largo del tiempo

### 2. Umbrales de Performance

Definir umbrales claros:

```typescript
const PERFORMANCE_THRESHOLDS = {
  singleRequest: 100,        // ms
  avgResponseTime: 200,      // ms
  maxResponseTime: 500,      // ms
  concurrentRequests: 5000,  // ms para 50 requests
  throughput: 10             // requests/second
};
```

### 3. Monitoreo de Degradación

Comparar resultados entre versiones:

```bash
# Guardar resultados
npm run test:e2e -- --json --outputFile=performance-results.json

# Comparar con versión anterior
node scripts/compare-performance.js current.json previous.json
```

### 4. Tests en Entorno Similar a Producción

- Usar datos realistas
- Simular latencia de red
- Considerar límites de recursos

### 5. Documentar Cambios

Cuando los resultados cambian significativamente:

```markdown
## Performance Change Log

### v1.3.4 (2025-10-11)
- **Mejora**: Throughput aumentó de 15 a 22 req/s
- **Causa**: Optimización de queries MongoDB
- **Issue**: TEN-80
```

---

## Troubleshooting

### Problema: Tests Fallan por Timeout

**Síntomas:**
```
Timeout - Async callback was not invoked within the 10000 ms timeout
```

**Solución:**
```typescript
// Aumentar timeout específico
it('should handle load', async () => {
  // test code
}, 30000);  // 30 segundos

// O en jest.config.js
testTimeout: 30000
```

### Problema: Rate Limiting No Se Aplica

**Síntomas:**
```
Expected status 429, received 200
```

**Solución:**
1. Verificar configuración de `express-rate-limit`
2. Asegurar que el middleware está registrado
3. Verificar orden de middlewares

### Problema: Resultados Inconsistentes

**Síntomas:**
```
Performance varies wildly between runs
```

**Solución:**
1. Limpiar caché antes de cada run
2. Usar `beforeEach` para reset
3. Aumentar número de iteraciones para promedios más estables

---

## Referencias

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Supertest](https://github.com/visionmedia/supertest)
- [Express Rate Limit](https://www.npmjs.com/package/express-rate-limit)
- [Helmet Security](https://helmetjs.github.io/)
- [Performance Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)

---

## Changelog

| Fecha | Versión | Cambios | Issue |
|-------|---------|---------|-------|
| 2025-10-11 | 1.0.0 | Implementación inicial de tests de performance y edge cases | TEN-80 |

---

## Contacto y Soporte

Para preguntas o problemas relacionados con estos tests:

- **Issue Tracker**: [Linear - TEN-80](https://linear.app/tennis-management-system/issue/TEN-80)
- **Documentación**: `/docs/PERFORMANCE_TESTING.md`
- **Tests**: `/src/__tests__/e2e/edge-cases-and-performance.test.ts`

