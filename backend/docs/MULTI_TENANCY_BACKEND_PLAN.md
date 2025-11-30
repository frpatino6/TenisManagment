# Plan de Implementación: Multi-Tenancy Backend

## 📋 Resumen Ejecutivo

Este documento detalla el plan de implementación para las 9 historias de backend de multi-tenancy, en orden lógico de dependencias.

**Total de Story Points:** 52 puntos  
**Tiempo Estimado:** 6-8 semanas (dependiendo del equipo)

---

## 🎯 Fase 1: Fundación - Modelos de Datos

### **TEN-83: MT-BACK-001 - Modelos de Datos Multi-Tenant** (8 pts)

#### Objetivo
Crear la base de datos multi-tenant: modelos nuevos y actualización de modelos existentes.

#### Pasos de Implementación

1. **Crear nuevos modelos** (`backend/src/infrastructure/database/models/`):
   - `TenantModel.ts`
     - Campos: `name`, `slug` (único), `domain` (opcional), `adminUserId`, `config` (logo, colores, precios base), `isActive`
     - Índices: `slug` (único), `domain` (sparse, único)
   
   - `TenantAdminModel.ts`
     - Campos: `tenantId`, `adminUserId`, `isActive`, `joinedAt`
     - Índices compuestos: `{ tenantId: 1, adminUserId: 1 }` (único)
   
   - `ProfessorTenantModel.ts`
     - Campos: `professorId`, `tenantId`, `pricing` (específico por centro), `isActive`, `joinedAt`
     - Índices compuestos: `{ professorId: 1, tenantId: 1 }` (único), `{ tenantId: 1, isActive: 1 }`
   
   - `StudentTenantModel.ts`
     - Campos: `studentId`, `tenantId`, `balance` (por centro), `isActive`, `joinedAt`
     - Índices compuestos: `{ studentId: 1, tenantId: 1 }` (único), `{ tenantId: 1, isActive: 1 }`

2. **Actualizar modelos existentes**:
   - `AuthUserModel.ts`:
     - Actualizar `UserRole`: `'super_admin' | 'tenant_admin' | 'professor' | 'student'`
     - Mantener compatibilidad con roles existentes
   
   - `BookingModel.ts`:
     - Agregar `tenantId: Types.ObjectId` (required, indexed)
     - Índice compuesto: `{ tenantId: 1, studentId: 1 }`, `{ tenantId: 1, professorId: 1 }`
   
   - `ScheduleModel.ts`:
     - Agregar `tenantId: Types.ObjectId` (required, indexed)
     - Índice compuesto: `{ tenantId: 1, professorId: 1, date: 1 }`
   
   - `PaymentModel.ts`:
     - Agregar `tenantId: Types.ObjectId` (required, indexed)
     - Índice compuesto: `{ tenantId: 1, studentId: 1 }`
   
   - `ServiceRequestModel.ts`:
     - Agregar `tenantId: Types.ObjectId` (required, indexed)

3. **Crear script de migración** (`backend/scripts/migrations/`):
   - Script para agregar `tenantId` a documentos existentes
   - Asignar un tenant por defecto a datos legacy (opcional)
   - Validar integridad de datos después de migración

#### Criterios de Aceptación
- ✅ Todos los modelos creados con validaciones
- ✅ Índices compuestos funcionando
- ✅ Script de migración probado
- ✅ Tests unitarios >80% coverage
- ✅ Documentación JSDoc completa

#### Dependencias
- Ninguna (es la base)

#### Riesgos
- Migración de datos existentes puede ser compleja
- Necesidad de crear tenant por defecto para datos legacy

---

## 🔧 Fase 2: Lógica de Negocio

### **TEN-84: MT-BACK-002 - TenantService** (5 pts)

#### Objetivo
Implementar servicio de gestión de tenants y relaciones usuario-tenant.

#### Pasos de Implementación

1. **Crear TenantService** (`backend/src/application/services/TenantService.ts`):
   ```typescript
   class TenantService {
     // CRUD de tenants
     createTenant(data, adminEmail): Promise<Tenant>
     getTenantById(tenantId): Promise<Tenant>
     updateTenant(tenantId, data): Promise<Tenant>
     listTenants(filters?): Promise<Tenant[]>
     
     // Relaciones usuario-tenant
     getUserTenants(userId, role): Promise<Tenant[]>
     addProfessorToTenant(professorId, tenantId, pricing?): Promise<ProfessorTenant>
     addStudentToTenant(studentId, tenantId): Promise<StudentTenant>
     removeUserFromTenant(userId, tenantId, role): Promise<void>
     
     // Validación y acceso
     validateTenantAccess(userId, tenantId, role): Promise<boolean>
     getTenantConfig(tenantId): Promise<TenantConfig>
   }
   ```

2. **Implementar lógica de negocio**:
   - Crear tenant: crear `Tenant` + `AuthUser` (tenant_admin) + `TenantAdmin`
   - Validar acceso: según rol (super_admin, tenant_admin, professor, student)
   - Gestión de relaciones: crear/actualizar `ProfessorTenant` y `StudentTenant`
   - Configuración: obtener y cachear configuración del tenant

3. **Integrar con email service** (si existe):
   - Enviar email de activación al Tenant Admin
   - Enviar email de invitación a profesores

#### Criterios de Aceptación
- ✅ 9 métodos implementados y testeados
- ✅ Validación de acceso según roles
- ✅ Manejo de errores completo
- ✅ Tests unitarios >80% coverage
- ✅ Documentación JSDoc con ejemplos

#### Dependencias
- ✅ TEN-83 (requiere los modelos)

#### Riesgos
- Lógica de validación de acceso puede ser compleja
- Necesidad de manejar casos edge (usuario en múltiples tenants)

---

## 🛡️ Fase 3: Infraestructura

### **TEN-85: MT-BACK-003 - Middleware de Tenant** (8 pts)

#### Objetivo
Implementar middleware para extraer y validar tenantId en requests.

#### Pasos de Implementación

1. **Crear middleware** (`backend/src/application/middleware/tenantMiddleware.ts`):
   ```typescript
   // Extraer tenantId del header
   export const extractTenantId = (req, res, next) => {
     const tenantId = req.headers['x-tenant-id'];
     if (!tenantId) {
       return res.status(400).json({ error: 'X-Tenant-ID header required' });
     }
     req.tenantId = tenantId;
     next();
   };
   
   // Validar acceso según rol
   export const requireTenantAccess = async (req, res, next) => {
     const { tenantId } = req;
     const userId = req.user?.id || req.user?.uid; // JWT o Firebase
     const role = req.user?.role;
     
     // Super Admin: acceso total
     if (role === 'super_admin') {
       return next();
     }
     
     // Validar acceso usando TenantService
     const hasAccess = await tenantService.validateTenantAccess(userId, tenantId, role);
     if (!hasAccess) {
       return res.status(403).json({ error: 'Access denied to this tenant' });
     }
     
     next();
   };
   ```

2. **Integrar con Express**:
   - Aplicar middleware en rutas que requieren tenant
   - Orden: `firebaseAuthMiddleware` → `extractTenantId` → `requireTenantAccess`

3. **Optimizar performance**:
   - Cachear validaciones de acceso (Redis opcional)
   - Medir overhead (<5ms objetivo)

#### Criterios de Aceptación
- ✅ Middleware extrae tenantId correctamente
- ✅ Validación de acceso según rol funciona
- ✅ Performance <5ms overhead
- ✅ Tests unitarios >90% coverage
- ✅ Tests de error handling (4+ escenarios)
- ✅ Integrado con Express middleware chain

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-84 (TenantService para validación)

#### Riesgos
- Performance puede ser un problema si no se cachea
- Validación de acceso puede ser lenta con muchas queries

---

### **TEN-86: MT-BACK-004 - Actualizar Repositories** (5 pts)

#### Objetivo
Actualizar todos los repositories para filtrar automáticamente por tenantId.

#### Pasos de Implementación

1. **Actualizar repositories** (`backend/src/infrastructure/repositories/`):
   - `BookingRepository.ts`:
     - Todos los métodos deben incluir `tenantId` en filtros
     - `findByStudent()` → `find({ studentId, tenantId })`
     - `findByProfessor()` → `find({ professorId, tenantId })`
   
   - `ScheduleRepository.ts`:
     - `findByProfessor()` → `find({ professorId, tenantId })`
     - `findAvailable()` → `find({ isAvailable: true, tenantId })`
   
   - `PaymentRepository.ts`:
     - `findByStudent()` → `find({ studentId, tenantId })`
     - `findByProfessor()` → `find({ professorId, tenantId })`
   
   - `ServiceRequestRepository.ts`:
     - Todos los métodos con filtro `tenantId`

2. **Crear helper para filtros**:
   ```typescript
   // backend/src/infrastructure/repositories/helpers/tenantFilter.ts
   export const addTenantFilter = (filter: any, tenantId: string) => {
     if (!tenantId) {
       throw new Error('tenantId is required');
     }
     return { ...filter, tenantId };
   };
   ```

3. **Tests de aislamiento**:
   - Crear datos de múltiples tenants
   - Verificar que queries no retornan datos de otros tenants

#### Criterios de Aceptación
- ✅ Todos los repositories actualizados
- ✅ Filtrado automático por tenantId
- ✅ Tests de aislamiento pasando
- ✅ Tests unitarios >80% coverage
- ✅ No hay data leaks entre tenants

#### Dependencias
- ✅ TEN-83 (modelos con tenantId)
- ✅ TEN-85 (req.tenantId disponible)

#### Riesgos
- Olvidar agregar filtro en algún método
- Performance si no se usan índices correctamente

---

## 👑 Fase 4: Controladores de Administración

### **TEN-87: MT-BACK-005 - Controladores Super Admin** (5 pts)

#### Objetivo
Implementar endpoints para que Super Admin gestione tenants.

#### Pasos de Implementación

1. **Crear SuperAdminController** (`backend/src/application/controllers/SuperAdminController.ts`):
   ```typescript
   class SuperAdminController {
     // CRUD de tenants
     createTenant(req, res): Promise<void>
     listTenants(req, res): Promise<void>
     getTenant(req, res): Promise<void>
     updateTenant(req, res): Promise<void>
     activateTenant(req, res): Promise<void>
     deactivateTenant(req, res): Promise<void>
     
     // Métricas globales
     getGlobalMetrics(req, res): Promise<void>
   }
   ```

2. **Crear rutas** (`backend/src/presentation/routes/admin.ts`):
   ```typescript
   router.post('/tenants', controller.createTenant);
   router.get('/tenants', controller.listTenants);
   router.get('/tenants/:id', controller.getTenant);
   router.put('/tenants/:id', controller.updateTenant);
   router.patch('/tenants/:id/activate', controller.activateTenant);
   router.patch('/tenants/:id/deactivate', controller.deactivateTenant);
   router.get('/metrics', controller.getGlobalMetrics);
   ```

3. **Validación de rol**:
   - Middleware: solo usuarios con `role === 'super_admin'`
   - Verificar en cada endpoint

4. **Integrar con TenantService**:
   - Usar métodos de `TenantService` para operaciones

#### Criterios de Aceptación
- ✅ 7 endpoints implementados
- ✅ Validación de rol en todos los endpoints
- ✅ Tests unitarios >80% coverage
- ✅ Tests de integración
- ✅ Documentación JSDoc

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-84 (TenantService)
- ✅ TEN-85 (middleware de validación)

#### Riesgos
- Seguridad: validación de rol debe ser estricta
- Métricas globales pueden ser lentas con muchos tenants

---

### **TEN-88: MT-BACK-006 - Controladores Tenant Admin** (8 pts)

#### Objetivo
Implementar endpoints para que Tenant Admin gestione su centro.

#### Pasos de Implementación

1. **Crear TenantAdminController** (`backend/src/application/controllers/TenantAdminController.ts`):
   ```typescript
   class TenantAdminController {
     // Configuración del centro
     getTenantInfo(req, res): Promise<void>
     updateTenantConfig(req, res): Promise<void>
     
     // Gestión de profesores
     listProfessors(req, res): Promise<void>
     inviteProfessor(req, res): Promise<void>
     activateProfessor(req, res): Promise<void>
     deactivateProfessor(req, res): Promise<void>
     
     // Gestión de canchas
     listCourts(req, res): Promise<void>
     createCourt(req, res): Promise<void>
     updateCourt(req, res): Promise<void>
     deleteCourt(req, res): Promise<void>
     
     // Reportes
     getMetrics(req, res): Promise<void>
   }
   ```

2. **Crear rutas** (`backend/src/presentation/routes/tenant.ts`):
   ```typescript
   router.get('/me', controller.getTenantInfo);
   router.put('/me', controller.updateTenantConfig);
   router.get('/professors', controller.listProfessors);
   router.post('/professors/invite', controller.inviteProfessor);
   router.patch('/professors/:id/activate', controller.activateProfessor);
   router.patch('/professors/:id/deactivate', controller.deactivateProfessor);
   router.get('/courts', controller.listCourts);
   router.post('/courts', controller.createCourt);
   router.put('/courts/:id', controller.updateCourt);
   router.delete('/courts/:id', controller.deleteCourt);
   router.get('/metrics', controller.getMetrics);
   ```

3. **Validación de acceso**:
   - Middleware: verificar que es Tenant Admin de ese tenant
   - Usar `requireTenantAccess` + validación de rol

4. **Modelo de Court** (si no existe):
   - Crear `CourtModel.ts` con `tenantId`, `name`, `type`, `price`, etc.

#### Criterios de Aceptación
- ✅ 11 endpoints implementados
- ✅ Validación de rol y acceso
- ✅ Tests unitarios >80% coverage
- ✅ Tests de integración
- ✅ Documentación JSDoc

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-84 (TenantService)
- ✅ TEN-85 (middleware)
- ✅ TEN-87 (patrón de controladores)

#### Riesgos
- Invitación de profesores puede requerir email service
- Gestión de canchas puede requerir nuevo modelo

---

## 🎯 Fase 5: Endpoints de Funcionalidad Core

### **TEN-89: MT-BACK-007 - Actualizar Endpoints de Reservas** (5 pts)

#### Objetivo
Actualizar endpoints de reservas para funcionar con multi-tenancy.

#### Pasos de Implementación

1. **Actualizar `StudentDashboardController.bookLesson()`**:
   - Obtener `tenantId` del schedule seleccionado
   - Crear `StudentTenant` automáticamente si no existe
   - Asociar `tenantId` al booking

2. **Actualizar `StudentDashboardController.getBookings()`**:
   - Filtrar por `tenantId` del tenant activo
   - Usar `BookingRepository` actualizado (ya filtra por tenant)

3. **Crear nuevo endpoint `bookCourt()`**:
   - Similar a `bookLesson()` pero sin `professorId`
   - Crear booking de tipo `court_rental`
   - Crear `StudentTenant` si no existe

4. **Actualizar `ProfessorDashboardController.getBookings()`**:
   - Filtrar por `tenantId` del tenant activo

5. **Lógica de creación automática de StudentTenant**:
   ```typescript
   // En TenantService o en el controller
   async ensureStudentTenant(studentId: string, tenantId: string) {
     let studentTenant = await StudentTenantModel.findOne({ studentId, tenantId });
     if (!studentTenant) {
       studentTenant = await StudentTenantModel.create({
         studentId,
         tenantId,
         balance: 0,
         isActive: true,
         joinedAt: new Date(),
       });
     }
     return studentTenant;
   }
   ```

#### Criterios de Aceptación
- ✅ `book-lesson` actualizado con tenantId
- ✅ `bookings` filtrado por tenant
- ✅ `book-court` implementado
- ✅ Creación automática de StudentTenant
- ✅ Tests unitarios >80% coverage
- ✅ Tests de integración (flujo completo)

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-84 (TenantService)
- ✅ TEN-85 (middleware)
- ✅ TEN-86 (repositories actualizados)

#### Riesgos
- Lógica de creación automática puede tener race conditions
- Necesidad de manejar casos donde schedule no tiene tenantId

---

### **TEN-90: MT-BACK-008 - Endpoints de Horarios Agrupados** (5 pts)

#### Objetivo
Implementar endpoints para obtener horarios agrupados por centro.

#### Pasos de Implementación

1. **Crear endpoint `GET /api/student-dashboard/professors/:professorId/schedules`**:
   ```typescript
   // En StudentDashboardController
   getProfessorSchedules = async (req, res) => {
     const { professorId } = req.params;
     const schedules = await ScheduleRepository.findByProfessor(professorId);
     
     // Agrupar por tenantId
     const grouped = schedules.reduce((acc, schedule) => {
       const tenantId = schedule.tenantId.toString();
       if (!acc[tenantId]) {
         acc[tenantId] = {
           tenantId,
           tenantName: schedule.tenant?.name,
           schedules: [],
         };
       }
       acc[tenantId].schedules.push(schedule);
       return acc;
     }, {});
     
     res.json({ items: Object.values(grouped) });
   };
   ```

2. **Crear endpoint `GET /api/student-dashboard/tenants/:tenantId/schedules`**:
   - Retornar todos los horarios disponibles de un centro específico
   - Agrupar por profesor

3. **Crear endpoint `GET /api/student-dashboard/available-schedules`**:
   - Retornar todos los horarios disponibles
   - Agrupar por centro y profesor
   - Incluir información del centro en cada horario

4. **Optimizar queries**:
   - Usar `populate` para obtener información del tenant
   - Usar índices compuestos para performance

#### Criterios de Aceptación
- ✅ 3 endpoints implementados
- ✅ Agrupación correcta por centro
- ✅ Información del centro incluida
- ✅ Tests unitarios >80% coverage
- ✅ Tests de integración
- ✅ Performance optimizada

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-86 (repositories)
- ✅ TEN-89 (patrón de endpoints)

#### Riesgos
- Queries pueden ser lentas con muchos horarios
- Agrupación puede ser compleja con múltiples tenants

---

## 🔧 Fase 6: Utilidades

### **TEN-91: MT-BACK-009 - Endpoint para Obtener Tenants de Usuario** (3 pts)

#### Objetivo
Implementar endpoint para que usuarios vean en qué centros están activos.

#### Pasos de Implementación

1. **Crear endpoint `GET /api/professor-dashboard/tenants`**:
   ```typescript
   // En ProfessorDashboardController
   getMyTenants = async (req, res) => {
     const professorId = req.user.professorId;
     const professorTenants = await ProfessorTenantModel.find({
       professorId,
       isActive: true,
     }).populate('tenantId');
     
     const tenants = professorTenants.map(pt => ({
       id: pt.tenantId._id,
       name: pt.tenantId.name,
       logo: pt.tenantId.config?.logo,
       isActive: pt.isActive,
       joinedAt: pt.joinedAt,
     }));
     
     res.json({ items: tenants });
   };
   ```

2. **Crear endpoint `GET /api/student-dashboard/tenants`**:
   - Similar pero usando `StudentTenantModel`
   - Incluir balance por tenant

3. **Optimizar queries**:
   - Usar `populate` para obtener información del tenant
   - Cachear resultados (opcional)

#### Criterios de Aceptación
- ✅ 2 endpoints implementados
- ✅ Información básica del tenant incluida
- ✅ Estado de relación incluido
- ✅ Tests unitarios >80% coverage
- ✅ Tests de integración

#### Dependencias
- ✅ TEN-83 (modelos)
- ✅ TEN-84 (TenantService opcional)
- ✅ Todas las anteriores (patrones establecidos)

#### Riesgos
- Mínimos, es un endpoint simple de lectura

---

## 📊 Resumen de Dependencias

```
TEN-83 (Modelos)
  ↓
TEN-84 (TenantService)
  ↓
TEN-85 (Middleware) ──┐
                      ├──→ TEN-87 (Super Admin)
TEN-86 (Repositories) ─┤
                      ├──→ TEN-88 (Tenant Admin)
                      ├──→ TEN-89 (Reservas)
                      ├──→ TEN-90 (Horarios)
                      └──→ TEN-91 (Utilidades)
```

## 🚀 Estrategia de Implementación

### Sprint 1 (2 semanas)
- **TEN-83**: Modelos de Datos Multi-Tenant (8 pts)
- **TEN-84**: TenantService (5 pts)
- **Total:** 13 pts

### Sprint 2 (2 semanas)
- **TEN-85**: Middleware de Tenant (8 pts)
- **TEN-86**: Actualizar Repositories (5 pts)
- **Total:** 13 pts

### Sprint 3 (2 semanas)
- **TEN-87**: Controladores Super Admin (5 pts)
- **TEN-88**: Controladores Tenant Admin (8 pts)
- **Total:** 13 pts

### Sprint 4 (1-2 semanas)
- **TEN-89**: Actualizar Endpoints de Reservas (5 pts)
- **TEN-90**: Endpoints de Horarios Agrupados (5 pts)
- **TEN-91**: Endpoint para Obtener Tenants (3 pts)
- **Total:** 13 pts

## ⚠️ Consideraciones Importantes

1. **Migración de Datos**:
   - Crear script de migración para datos existentes
   - Asignar tenant por defecto o crear tenant inicial
   - Validar integridad después de migración

2. **Testing**:
   - Tests unitarios para cada componente
   - Tests de integración para flujos completos
   - Tests de aislamiento (verificar que no hay data leaks)

3. **Performance**:
   - Usar índices compuestos correctamente
   - Cachear validaciones de acceso
   - Optimizar queries con populate

4. **Seguridad**:
   - Validación estricta de roles
   - Verificar acceso a tenant en cada request
   - Proteger contra inyección de tenantId

5. **Compatibilidad**:
   - Mantener compatibilidad con datos existentes
   - Migración gradual si es posible
   - Documentar breaking changes

## 📝 Checklist de Inicio

Antes de comenzar, asegurar:
- [ ] Base de datos MongoDB accesible
- [ ] Entorno de desarrollo configurado
- [ ] Tests existentes pasando
- [ ] Documentación de arquitectura revisada
- [ ] Acceso a Linear para tracking de tareas

---

**Última actualización:** 2025-11-30  
**Autor:** Plan generado automáticamente

