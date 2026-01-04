# Análisis Completo: Aplicación de Administración del Tenant

## 📋 Resumen Ejecutivo

Este documento analiza el estado actual de la funcionalidad de Tenant Admin en el backend, identifica las funcionalidades que debería tener una aplicación Flutter completamente independiente para la administración de centros, y propone la arquitectura y endpoints necesarios.

**Fecha de Análisis:** 30 de Diciembre, 2025  
**Historia Principal:** TEN-88 (MT-BACK-006: Controladores Tenant Admin)  
**Estado Backend:** Done - Completado  
**Estado Frontend:** No implementado - Requiere nueva app Flutter independiente

---

## 🎯 Historia de Linear Relacionada

### ✅ TEN-88: MT-BACK-006 - Controladores Tenant Admin (COMPLETADO)
**Estado:** Done  
**Prioridad:** Urgent (P0)  
**Story Points:** 8

**Descripción:** Implementar controladores para que Tenant Admin pueda gestionar su centro: configuración, profesores, canchas, reportes.

**Criterios de Aceptación Cumplidos:**
- ✅ `GET /api/tenant/me` - Información del tenant
- ✅ `PUT /api/tenant/me` - Actualizar configuración
- ✅ `PUT /api/tenant/operating-hours` - Configurar horarios de operación
- ✅ `GET /api/tenant/professors` - Listar profesores
- ✅ `POST /api/tenant/professors/invite` - Invitar profesor
- ✅ `PATCH /api/tenant/professors/:id/activate` - Activar profesor
- ✅ `PATCH /api/tenant/professors/:id/deactivate` - Desactivar profesor
- ✅ `GET /api/tenant/courts` - Listar canchas
- ✅ `POST /api/tenant/courts` - Crear cancha
- ✅ `PUT /api/tenant/courts/:id` - Actualizar cancha
- ✅ `DELETE /api/tenant/courts/:id` - Eliminar cancha
- ✅ `GET /api/tenant/metrics` - Métricas del centro
- ✅ Validación de rol (solo Tenant Admin de ese tenant)
- ✅ Tests unitarios >80% coverage
- ✅ Documentado en JSDoc

---

## 🔍 Análisis del Backend

### ✅ Estado Actual: COMPLETADO

#### 1. **TenantAdminController** (`backend/src/application/controllers/TenantAdminController.ts`)

**Endpoints Implementados:**

| Método | Ruta | Descripción | Estado |
|--------|------|-------------|--------|
| GET | `/api/tenant/me` | Obtener información del tenant | ✅ |
| PUT | `/api/tenant/me` | Actualizar configuración del tenant | ✅ |
| PUT | `/api/tenant/operating-hours` | Configurar horarios de operación | ✅ |
| GET | `/api/tenant/professors` | Listar profesores del tenant | ✅ |
| POST | `/api/tenant/professors/invite` | Invitar profesor al tenant | ✅ |
| PATCH | `/api/tenant/professors/:id/activate` | Activar profesor | ✅ |
| PATCH | `/api/tenant/professors/:id/deactivate` | Desactivar profesor | ✅ |
| GET | `/api/tenant/courts` | Listar canchas del tenant | ✅ |
| POST | `/api/tenant/courts` | Crear cancha | ✅ |
| PUT | `/api/tenant/courts/:id` | Actualizar cancha | ✅ |
| DELETE | `/api/tenant/courts/:id` | Eliminar cancha | ✅ |
| GET | `/api/tenant/metrics` | Obtener métricas del centro | ✅ |

**Total: 12 endpoints implementados**

#### 2. **Estructura de Respuestas**

**GET /api/tenant/me:**
```json
{
  "id": "string",
  "name": "string",
  "slug": "string",
  "domain": "string",
  "config": {
    "logo": "string",
    "primaryColor": "string",
    "secondaryColor": "string",
    "basePricing": {
      "individualClass": number,
      "groupClass": number,
      "courtRental": number
    },
    "operatingHours": {
      "open": "HH:mm",
      "close": "HH:mm",
      "daysOfWeek": [number]
    }
  },
  "isActive": boolean,
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

**GET /api/tenant/professors:**
```json
{
  "professors": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "phone": "string",
      "specialties": [string],
      "hourlyRate": number,
      "experienceYears": number,
      "pricing": {
        "individualClass": number,
        "groupClass": number,
        "courtRental": number
      },
      "isActive": boolean,
      "joinedAt": "ISO8601",
      "bookingsCount": number,
      "authUserId": "string"
    }
  ]
}
```

**GET /api/tenant/courts:**
```json
{
  "courts": [
    {
      "id": "string",
      "name": "string",
      "type": "tennis" | "padel" | "multi",
      "price": number,
      "isActive": boolean,
      "description": "string",
      "features": [string],
      "createdAt": "ISO8601",
      "updatedAt": "ISO8601"
    }
  ]
}
```

**GET /api/tenant/metrics:**
```json
{
  "bookings": {
    "total": number
  },
  "payments": {
    "total": number,
    "revenue": number
  },
  "users": {
    "professors": number,
    "students": number
  },
  "courts": {
    "total": number
  },
  "topProfessors": [
    {
      "professorId": "string",
      "professorName": "string",
      "bookingsCount": number
    }
  ]
}
```

#### 3. **Middleware de Autenticación**

- ✅ `authMiddleware`: Autenticación con JWT
- ✅ `requireRole('tenant_admin')`: Validación de rol
- ✅ `extractTenantId`: Extracción de tenantId del header `X-Tenant-ID`
- ✅ `requireTenantAccess`: Validación de acceso al tenant

#### 4. **Rutas Configuradas** (`backend/src/presentation/routes/tenant.ts`)

- ✅ Todas las rutas protegidas con autenticación y validación de rol
- ✅ Montadas en `/api/tenant` en el router principal

---

## 📱 Análisis del Frontend

### ❌ Estado Actual: NO IMPLEMENTADO

**Requisito Especial:** La aplicación debe ser **completamente independiente** de la app móvil existente (profesor/estudiante), pero usar el mismo backend.

**Implicaciones:**
- ✅ Nueva app Flutter separada
- ✅ Mismo backend (`/api/tenant/*`)
- ✅ Autenticación independiente (Firebase Auth)
- ✅ Puede tener su propio diseño/branding
- ✅ No comparte código con la app móvil existente

---

## 🎯 Funcionalidades Requeridas para la App

### 1. **Dashboard Principal**

**Objetivo:** Vista general del centro con métricas clave y accesos rápidos.

**Componentes:**
- Cards con métricas principales:
  - Total de reservas
  - Ingresos totales
  - Profesores activos
  - Estudiantes activos
  - Canchas disponibles
- Gráficos de tendencias (opcional):
  - Reservas por mes
  - Ingresos por mes
  - Profesores más activos
- Accesos rápidos:
  - Ver reservas
  - Gestionar profesores
  - Gestionar canchas
  - Ver reportes

**Endpoint Backend:** `GET /api/tenant/metrics` ✅

### 2. **Configuración del Centro**

**Objetivo:** Permitir al Tenant Admin configurar su centro.

**Funcionalidades:**
- **Información Básica:**
  - Nombre del centro
  - Slug (URL-friendly)
  - Dominio (opcional)
- **Branding:**
  - Subir logo
  - Colores primarios y secundarios
- **Precios Base:**
  - Precio clase individual
  - Precio clase grupal
  - Precio alquiler de cancha
- **Horarios de Operación (Ciclos Diarios):**
  - Hora de apertura (formato HH:mm, ej: "06:00")
  - Hora de cierre (formato HH:mm, ej: "22:00")
  - Días de la semana (opcional, array de números 0-6 donde 0=Domingo, 6=Sábado)
  - **Cálculo Automático de Slots:**
    - El sistema genera automáticamente slots horarios desde la hora de apertura hasta la hora de cierre
    - Ejemplo: Si `open = "06:00"` y `close = "22:00"`, se generan slots: 06:00, 07:00, 08:00, ..., 21:00
    - Estos slots se usan para:
      - Mostrar horarios disponibles para reservas de cancha
      - Validar que las reservas estén dentro del horario de operación
      - Filtrar días de la semana si está configurado `daysOfWeek`
    - Si no se configuran horarios, se usan valores por defecto: 06:00 - 22:00

**Endpoints Backend:**
- `GET /api/tenant/me` ✅
- `PUT /api/tenant/me` ✅
- `PUT /api/tenant/operating-hours` ✅

**📌 Nota Importante sobre Ciclos Diarios (Horarios de Operación):**

Los horarios de operación configuran los **ciclos diarios** del centro, es decir, el rango de horas en que se pueden realizar reservas. El sistema calcula automáticamente los slots disponibles basándose en esta configuración:

- **Configuración:**
  - `open`: Hora de apertura (formato "HH:mm", ej: "06:00")
  - `close`: Hora de cierre (formato "HH:mm", ej: "22:00")
  - `daysOfWeek`: Días de la semana opcionales (array de números 0-6, donde 0=Domingo, 6=Sábado)

- **Cálculo Automático de Slots:**
  - El sistema genera slots horarios automáticamente desde `open` hasta `close`
  - Ejemplo: Si `open = "06:00"` y `close = "22:00"`, se generan slots: **06:00, 07:00, 08:00, ..., 21:00** (cada hora)
  - Estos slots se usan para:
    - Mostrar horarios disponibles en la app de estudiantes (reservas de cancha)
    - Validar que las reservas manuales estén dentro del horario de operación
    - Filtrar días de la semana si está configurado `daysOfWeek`
    - Mostrar mensaje "El centro no opera en este día" si se intenta reservar fuera de los días configurados

- **Valores por Defecto:**
  - Si no se configuran horarios, el sistema usa: **06:00 - 22:00** (todos los días)
  - Se muestra una advertencia en los logs del backend

- **Uso en la App de Tenant Admin:**
  - Al crear una reserva manual, el sistema valida automáticamente que la hora esté dentro del rango configurado
  - El selector de hora debe mostrar solo los slots disponibles según los horarios de operación
  - Si se intenta crear una reserva fuera del horario, se debe mostrar un error claro

### 3. **Gestión de Profesores**

**Objetivo:** Gestionar los profesores que trabajan en el centro.

**Funcionalidades:**
- **Listar Profesores:**
  - Ver todos los profesores del centro
  - Filtrar por activos/inactivos
  - Buscar por nombre/email
  - Ver estadísticas de cada profesor (reservas, ingresos)
- **Invitar Profesor:**
  - Formulario para invitar por email
  - Configurar precios personalizados
  - Enviar invitación
- **Activar/Desactivar:**
  - Activar profesor inactivo
  - Desactivar profesor activo
  - Ver historial de cambios

**Endpoints Backend:**
- `GET /api/tenant/professors` ✅
- `POST /api/tenant/professors/invite` ✅
- `PATCH /api/tenant/professors/:id/activate` ✅
- `PATCH /api/tenant/professors/:id/deactivate` ✅

### 4. **Gestión de Canchas**

**Objetivo:** Gestionar las canchas/instalaciones del centro.

**Funcionalidades:**
- **Listar Canchas:**
  - Ver todas las canchas
  - Filtrar por tipo (tennis, padel, multi)
  - Filtrar por activas/inactivas
  - Ver disponibilidad
- **Crear Cancha:**
  - Nombre
  - Tipo (tennis, padel, multi)
  - Precio por hora
  - Descripción
  - Características (techada, iluminación, etc.)
- **Editar Cancha:**
  - Modificar todos los campos
  - Activar/desactivar
- **Eliminar Cancha:**
  - Confirmación antes de eliminar
  - Validar que no tenga reservas futuras

**Endpoints Backend:**
- `GET /api/tenant/courts` ✅
- `POST /api/tenant/courts` ✅
- `PUT /api/tenant/courts/:id` ✅
- `DELETE /api/tenant/courts/:id` ✅

### 5. **Gestión de Reservas** (NUEVO - Requiere Endpoint)

**Objetivo:** Ver y gestionar todas las reservas del centro, incluyendo la creación manual de reservas.

**Funcionalidades:**
- **Listar Reservas:**
  - Ver todas las reservas del centro
  - Filtrar por fecha
  - Filtrar por estado (pending, confirmed, cancelled, completed)
  - Filtrar por tipo (individual_class, group_class, court_rental)
  - Filtrar por profesor
  - Filtrar por estudiante
  - Buscar por nombre de estudiante/profesor
- **Crear Reserva Manual:**
  - Crear reserva con profesor (clase individual o grupal):
    - Seleccionar estudiante (búsqueda por nombre/email/teléfono)
    - Seleccionar profesor
    - Seleccionar fecha y hora
    - Seleccionar cancha (o asignar automáticamente)
    - Configurar precio (usar precio del profesor o precio base)
    - Agregar notas opcionales
  - Crear reserva sin profesor (alquiler de cancha):
    - Seleccionar estudiante (búsqueda por nombre/email/teléfono)
    - Seleccionar cancha
    - Seleccionar fecha y hora
    - Configurar precio (usar precio de la cancha)
    - Agregar notas opcionales
  - Validaciones:
    - Verificar disponibilidad de cancha
    - Verificar disponibilidad del profesor (si aplica)
    - Validar horarios de operación del centro
    - Confirmar que no haya conflictos
- **Ver Detalle de Reserva:**
  - Información completa
  - Estudiante
  - Profesor (si aplica)
  - Cancha asignada
  - Fecha y hora
  - Precio
  - Estado
- **Gestionar Reservas:**
  - Confirmar reserva pendiente
  - Cancelar reserva
  - Marcar como completada
  - Editar reserva (fecha, hora, cancha, precio)
  - Ver historial de cambios

**Endpoints Backend Requeridos:**
- ❌ `GET /api/tenant/bookings` - **FALTA IMPLEMENTAR**
- ❌ `POST /api/tenant/bookings` - **FALTA IMPLEMENTAR** (Crear reserva manual)
- ❌ `GET /api/tenant/bookings/:id` - **FALTA IMPLEMENTAR**
- ❌ `PUT /api/tenant/bookings/:id` - **FALTA IMPLEMENTAR** (Editar reserva)
- ❌ `PATCH /api/tenant/bookings/:id/confirm` - **FALTA IMPLEMENTAR**
- ❌ `PATCH /api/tenant/bookings/:id/cancel` - **FALTA IMPLEMENTAR**

### 6. **Gestión de Pagos** (NUEVO - Requiere Endpoint)

**Objetivo:** Ver y gestionar todos los pagos del centro.

**Funcionalidades:**
- **Listar Pagos:**
  - Ver todos los pagos del centro
  - Filtrar por fecha
  - Filtrar por estado (pending, paid, cancelled)
  - Filtrar por método (cash, card, transfer)
  - Filtrar por profesor
  - Filtrar por estudiante
  - Buscar
- **Ver Detalle de Pago:**
  - Información completa
  - Estudiante
  - Profesor
  - Reserva asociada
  - Monto
  - Método
  - Estado
  - Fecha
- **Gestionar Pagos:**
  - Marcar como pagado
  - Cancelar pago
  - Ver historial

**Endpoints Backend Requeridos:**
- ❌ `GET /api/tenant/payments` - **FALTA IMPLEMENTAR**
- ❌ `GET /api/tenant/payments/:id` - **FALTA IMPLEMENTAR**
- ❌ `PATCH /api/tenant/payments/:id/mark-paid` - **FALTA IMPLEMENTAR**

### 7. **Gestión de Estudiantes** (NUEVO - Requiere Endpoint)

**Objetivo:** Ver información de los estudiantes del centro.

**Funcionalidades:**
- **Listar Estudiantes:**
  - Ver todos los estudiantes del centro
  - Filtrar por activos/inactivos
  - Buscar por nombre/email
  - Ver balance de cada estudiante
- **Ver Detalle de Estudiante:**
  - Información completa
  - Reservas del estudiante
  - Historial de pagos
  - Balance actual
  - Profesores favoritos

**Endpoints Backend Requeridos:**
- ❌ `GET /api/tenant/students` - **FALTA IMPLEMENTAR**
- ❌ `GET /api/tenant/students/:id` - **FALTA IMPLEMENTAR**

### 8. **Reportes y Analytics** (NUEVO - Requiere Endpoints)

**Objetivo:** Reportes detallados del centro.

**Funcionalidades:**
- **Reportes Financieros:**
  - Ingresos por período
  - Ingresos por profesor
  - Ingresos por tipo de servicio
  - Comparación de períodos
- **Reportes de Reservas:**
  - Reservas por período
  - Reservas por profesor
  - Reservas por tipo
  - Tasa de cancelación
  - Ocupación de canchas
- **Reportes de Usuarios:**
  - Nuevos estudiantes por período
  - Profesores más activos
  - Estudiantes más activos
- **Exportación:**
  - Exportar a PDF
  - Exportar a Excel/CSV

**Endpoints Backend Requeridos:**
- ❌ `GET /api/tenant/reports/revenue` - **FALTA IMPLEMENTAR**
- ❌ `GET /api/tenant/reports/bookings` - **FALTA IMPLEMENTAR**
- ❌ `GET /api/tenant/reports/users` - **FALTA IMPLEMENTAR**

### 9. **Notificaciones** (OPCIONAL)

**Objetivo:** Notificaciones importantes para el Tenant Admin.

**Funcionalidades:**
- Notificaciones de nuevas reservas
- Notificaciones de cancelaciones
- Notificaciones de pagos pendientes
- Notificaciones de profesores inactivos
- Configuración de preferencias de notificaciones

**Endpoints Backend Requeridos:**
- ❌ `GET /api/tenant/notifications` - **FALTA IMPLEMENTAR**
- ❌ `PATCH /api/tenant/notifications/:id/read` - **FALTA IMPLEMENTAR**

---

## 📊 Comparación: Endpoints Existentes vs Requeridos

| Funcionalidad | Endpoint | Estado Backend | Prioridad |
|---------------|----------|----------------|-----------|
| **Configuración** |
| Obtener info del tenant | `GET /api/tenant/me` | ✅ | Alta |
| Actualizar configuración | `PUT /api/tenant/me` | ✅ | Alta |
| Configurar horarios | `PUT /api/tenant/operating-hours` | ✅ | Alta |
| **Profesores** |
| Listar profesores | `GET /api/tenant/professors` | ✅ | Alta |
| Invitar profesor | `POST /api/tenant/professors/invite` | ✅ | Alta |
| Activar profesor | `PATCH /api/tenant/professors/:id/activate` | ✅ | Alta |
| Desactivar profesor | `PATCH /api/tenant/professors/:id/deactivate` | ✅ | Alta |
| **Canchas** |
| Listar canchas | `GET /api/tenant/courts` | ✅ | Alta |
| Crear cancha | `POST /api/tenant/courts` | ✅ | Alta |
| Actualizar cancha | `PUT /api/tenant/courts/:id` | ✅ | Alta |
| Eliminar cancha | `DELETE /api/tenant/courts/:id` | ✅ | Alta |
| **Métricas** |
| Métricas del centro | `GET /api/tenant/metrics` | ✅ | Alta |
| **Reservas** |
| Listar reservas | `GET /api/tenant/bookings` | ❌ | Alta |
| Crear reserva manual | `POST /api/tenant/bookings` | ❌ | Alta |
| Ver detalle reserva | `GET /api/tenant/bookings/:id` | ❌ | Media |
| Editar reserva | `PUT /api/tenant/bookings/:id` | ❌ | Media |
| Confirmar reserva | `PATCH /api/tenant/bookings/:id/confirm` | ❌ | Media |
| Cancelar reserva | `PATCH /api/tenant/bookings/:id/cancel` | ❌ | Media |
| **Pagos** |
| Listar pagos | `GET /api/tenant/payments` | ❌ | Alta |
| Ver detalle pago | `GET /api/tenant/payments/:id` | ❌ | Media |
| Marcar como pagado | `PATCH /api/tenant/payments/:id/mark-paid` | ❌ | Media |
| **Estudiantes** |
| Listar estudiantes | `GET /api/tenant/students` | ❌ | Alta |
| Ver detalle estudiante | `GET /api/tenant/students/:id` | ❌ | Media |
| **Reportes** |
| Reporte de ingresos | `GET /api/tenant/reports/revenue` | ❌ | Media |
| Reporte de reservas | `GET /api/tenant/reports/bookings` | ❌ | Media |
| Reporte de usuarios | `GET /api/tenant/reports/users` | ❌ | Baja |
| **Notificaciones** |
| Listar notificaciones | `GET /api/tenant/notifications` | ❌ | Baja |
| Marcar como leída | `PATCH /api/tenant/notifications/:id/read` | ❌ | Baja |

**Resumen:**
- ✅ **12 endpoints implementados** (Configuración, Profesores, Canchas, Métricas)
- ❌ **17 endpoints faltantes** (Reservas, Pagos, Estudiantes, Reportes, Notificaciones)

---

## 🏗️ Arquitectura Propuesta

### Estructura de la Nueva App Flutter

```
tenant-admin-app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart      # Configuración de la app (API URL, etc.)
│   │   ├── router/
│   │   │   └── app_router.dart      # GoRouter configuration
│   │   ├── services/
│   │   │   ├── http_client.dart      # HTTP client con interceptors
│   │   │   └── auth_service.dart     # Firebase Auth service
│   │   └── providers/
│   │       ├── auth_provider.dart    # Auth state provider
│   │       └── tenant_provider.dart  # Tenant context provider
│   ├── features/
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── user_model.dart
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   └── splash_screen.dart
│   │   │   │   └── providers/
│   │   │   │       └── auth_provider.dart
│   │   ├── dashboard/
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── metrics_model.dart
│   │   │   ├── domain/
│   │   │   │   └── services/
│   │   │   │       └── metrics_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── dashboard_screen.dart
│   │   │       ├── providers/
│   │   │       │   └── dashboard_provider.dart
│   │   │       └── widgets/
│   │   │           ├── metrics_card_widget.dart
│   │   │           └── metrics_chart_widget.dart
│   │   ├── configuration/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── tenant_config_model.dart
│   │   │   │   └── services/
│   │   │   │       └── tenant_config_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── tenant_config_screen.dart
│   │   │       │   ├── branding_config_screen.dart
│   │   │       │   ├── pricing_config_screen.dart
│   │   │       │   └── operating_hours_screen.dart
│   │   │       └── providers/
│   │   │           └── tenant_config_provider.dart
│   │   ├── professors/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── professor_model.dart
│   │   │   │   └── services/
│   │   │   │       └── professor_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── professors_list_screen.dart
│   │   │       │   ├── professor_detail_screen.dart
│   │   │       │   └── invite_professor_screen.dart
│   │   │       └── providers/
│   │   │           └── professors_provider.dart
│   │   ├── courts/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── court_model.dart
│   │   │   │   └── services/
│   │   │   │       └── court_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── courts_list_screen.dart
│   │   │       │   ├── court_detail_screen.dart
│   │   │       │   ├── create_court_screen.dart
│   │   │       │   └── edit_court_screen.dart
│   │   │       └── providers/
│   │   │           └── courts_provider.dart
│   │   ├── bookings/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── booking_model.dart
│   │   │   │   └── services/
│   │   │   │       └── booking_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── bookings_list_screen.dart
│   │   │       │   ├── booking_detail_screen.dart
│   │   │       │   └── create_booking_screen.dart
│   │   │       └── providers/
│   │   │           └── bookings_provider.dart
│   │   ├── payments/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── payment_model.dart
│   │   │   │   └── services/
│   │   │   │       └── payment_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── payments_list_screen.dart
│   │   │       │   └── payment_detail_screen.dart
│   │   │       └── providers/
│   │   │           └── payments_provider.dart
│   │   ├── students/
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   └── student_model.dart
│   │   │   │   └── services/
│   │   │   │       └── student_service.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── students_list_screen.dart
│   │   │       │   └── student_detail_screen.dart
│   │   │       └── providers/
│   │   │           └── students_provider.dart
│   │   └── reports/
│   │       ├── domain/
│   │       │   ├── models/
│   │       │   │   └── report_model.dart
│   │       │   └── services/
│   │       │       └── report_service.dart
│   │       └── presentation/
│   │           ├── screens/
│   │           │   ├── reports_screen.dart
│   │           │   ├── revenue_report_screen.dart
│   │           │   └── bookings_report_screen.dart
│   │           └── providers/
│   │               └── reports_provider.dart
│   └── shared/
│       ├── widgets/
│       │   ├── loading_widget.dart
│       │   ├── error_widget.dart
│       │   └── empty_state_widget.dart
│       └── utils/
│           ├── date_utils.dart
│           └── currency_utils.dart
├── pubspec.yaml
└── README.md
```

### Flujo de Navegación

```
Splash Screen
  ↓
Login Screen
  ↓
[Verificar rol tenant_admin]
  ↓
Dashboard
  ├── Configuración
  │   ├── Información Básica
  │   ├── Branding
  │   ├── Precios Base
  │   └── Horarios de Operación
  ├── Profesores
  │   ├── Lista de Profesores
  │   ├── Invitar Profesor
  │   └── Detalle de Profesor
  ├── Canchas
  │   ├── Lista de Canchas
  │   ├── Crear Cancha
  │   └── Editar Cancha
  ├── Reservas
  │   ├── Lista de Reservas
  │   ├── Crear Reserva Manual
  │   └── Detalle de Reserva
  ├── Pagos
  │   ├── Lista de Pagos
  │   └── Detalle de Pago
  ├── Estudiantes
  │   ├── Lista de Estudiantes
  │   └── Detalle de Estudiante
  └── Reportes
      ├── Reporte de Ingresos
      ├── Reporte de Reservas
      └── Reporte de Usuarios
```

---

## 🔐 Autenticación y Seguridad

### Autenticación

**Mismo sistema que la app móvil:**
- Firebase Authentication
- JWT tokens del backend
- Refresh tokens

**Flujo:**
1. Usuario inicia sesión con Firebase Auth
2. App obtiene Firebase ID token
3. App envía token al backend para obtener JWT
4. App guarda JWT y lo envía en cada request
5. Backend valida JWT y verifica rol `tenant_admin`

### Headers Requeridos

Todas las requests deben incluir:
- `Authorization: Bearer <JWT_TOKEN>`
- `X-Tenant-ID: <TENANT_ID>` (obtenido automáticamente del usuario autenticado)

### Validación de Rol

El backend ya valida:
- ✅ Usuario autenticado
- ✅ Rol `tenant_admin`
- ✅ Acceso al tenant (solo su propio tenant)

---

## 📝 Endpoints Adicionales Requeridos

### 1. Gestión de Reservas

#### `GET /api/tenant/bookings`
Listar todas las reservas del tenant con filtros.

**Query Parameters:**
- `startDate` (opcional): Fecha de inicio
- `endDate` (opcional): Fecha de fin
- `status` (opcional): pending, confirmed, cancelled, completed
- `serviceType` (opcional): individual_class, group_class, court_rental
- `professorId` (opcional): Filtrar por profesor
- `studentId` (opcional): Filtrar por estudiante
- `page` (opcional): Número de página
- `limit` (opcional): Límite de resultados

**Response:**
```json
{
  "bookings": [
    {
      "id": "string",
      "studentId": "string",
      "studentName": "string",
      "professorId": "string",
      "professorName": "string",
      "courtId": "string",
      "courtName": "string",
      "serviceType": "string",
      "status": "string",
      "price": number,
      "bookingDate": "ISO8601",
      "startTime": "ISO8601",
      "endTime": "ISO8601",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "totalPages": number
  }
}
```

#### `GET /api/tenant/bookings/:id`
Obtener detalle de una reserva específica.

#### `PATCH /api/tenant/bookings/:id/confirm`
Confirmar una reserva pendiente.

#### `POST /api/tenant/bookings`
Crear una reserva manualmente desde el Tenant Admin.

**Request Body:**
```json
{
  "studentId": "string", // ID del estudiante (requerido)
  "professorId": "string", // ID del profesor (opcional, requerido para individual_class/group_class)
  "courtId": "string", // ID de la cancha (opcional, se asigna automáticamente si no se proporciona)
  "serviceType": "individual_class" | "group_class" | "court_rental", // Requerido
  "bookingDate": "ISO8601", // Fecha y hora de inicio (requerido)
  "endTime": "ISO8601", // Fecha y hora de fin (requerido)
  "price": number, // Precio (opcional, se calcula automáticamente si no se proporciona)
  "notes": "string" // Notas opcionales
}
```

**Validaciones:**
- Si `serviceType` es `individual_class` o `group_class`, `professorId` es requerido
- Si `serviceType` es `court_rental`, `professorId` no debe estar presente
- **Validar horarios de operación (ciclos diarios):**
  - Verificar que la hora de `bookingDate` esté dentro del rango `open - close` configurado en `tenant.config.operatingHours`
  - Verificar que el día de la semana esté en `daysOfWeek` (si está configurado)
  - Si no hay horarios configurados, usar valores por defecto: 06:00 - 22:00
  - **Cálculo de slots disponibles:**
    - El sistema genera automáticamente slots horarios desde `open` hasta `close`
    - Ejemplo: Si `open = "06:00"` y `close = "22:00"`, se generan slots: 06:00, 07:00, 08:00, ..., 21:00 (cada hora)
    - Estos slots se usan para mostrar horarios disponibles y validar reservas
- Verificar disponibilidad de cancha en el horario seleccionado
- Verificar disponibilidad del profesor (si aplica)
- Verificar que no haya conflictos con otras reservas

**Response:**
```json
{
  "id": "string",
  "studentId": "string",
  "studentName": "string",
  "professorId": "string",
  "professorName": "string",
  "courtId": "string",
  "courtName": "string",
  "serviceType": "string",
  "status": "confirmed", // Se crea directamente como confirmada
  "price": number,
  "bookingDate": "ISO8601",
  "startTime": "ISO8601",
  "endTime": "ISO8601",
  "notes": "string",
  "createdAt": "ISO8601"
}
```

#### `PUT /api/tenant/bookings/:id`
Editar una reserva existente.

**Request Body:**
```json
{
  "professorId": "string", // Opcional
  "courtId": "string", // Opcional
  "bookingDate": "ISO8601", // Opcional
  "endTime": "ISO8601", // Opcional
  "price": number, // Opcional
  "notes": "string" // Opcional
}
```

**Validaciones:**
- Mismas validaciones que al crear
- No permitir editar reservas completadas o canceladas
- Verificar disponibilidad en el nuevo horario

#### `PATCH /api/tenant/bookings/:id/cancel`
Cancelar una reserva.

### 2. Gestión de Pagos

#### `GET /api/tenant/payments`
Listar todos los pagos del tenant con filtros.

**Query Parameters:**
- `startDate` (opcional)
- `endDate` (opcional)
- `status` (opcional): pending, paid, cancelled
- `method` (opcional): cash, card, transfer
- `professorId` (opcional)
- `studentId` (opcional)
- `page` (opcional)
- `limit` (opcional)

**Response:**
```json
{
  "payments": [
    {
      "id": "string",
      "studentId": "string",
      "studentName": "string",
      "professorId": "string",
      "professorName": "string",
      "bookingId": "string",
      "amount": number,
      "status": "string",
      "method": "string",
      "date": "ISO8601",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "totalPages": number
  }
}
```

#### `GET /api/tenant/payments/:id`
Obtener detalle de un pago específico.

#### `PATCH /api/tenant/payments/:id/mark-paid`
Marcar un pago como pagado.

### 3. Gestión de Estudiantes

#### `GET /api/tenant/students`
Listar todos los estudiantes del tenant.

**Query Parameters:**
- `isActive` (opcional): boolean
- `search` (opcional): Buscar por nombre/email
- `page` (opcional)
- `limit` (opcional)

**Response:**
```json
{
  "students": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "phone": "string",
      "balance": number,
      "isActive": boolean,
      "joinedAt": "ISO8601",
      "bookingsCount": number,
      "totalSpent": number
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "totalPages": number
  }
}
```

#### `GET /api/tenant/students/:id`
Obtener detalle de un estudiante específico con:
- Información completa
- Lista de reservas
- Historial de pagos
- Balance actual

### 4. Reportes

#### `GET /api/tenant/reports/revenue`
Reporte de ingresos por período.

**Query Parameters:**
- `startDate` (requerido)
- `endDate` (requerido)
- `groupBy` (opcional): day, week, month

**Response:**
```json
{
  "period": {
    "start": "ISO8601",
    "end": "ISO8601"
  },
  "totalRevenue": number,
  "revenueByServiceType": {
    "individualClass": number,
    "groupClass": number,
    "courtRental": number
  },
  "revenueByProfessor": [
    {
      "professorId": "string",
      "professorName": "string",
      "revenue": number
    }
  ],
  "dailyRevenue": [
    {
      "date": "ISO8601",
      "revenue": number
    }
  ]
}
```

#### `GET /api/tenant/reports/bookings`
Reporte de reservas por período.

#### `GET /api/tenant/reports/users`
Reporte de usuarios (nuevos estudiantes, profesores activos, etc.).

---

## 🎨 Diseño UI/UX Recomendado

### Principios de Diseño

1. **Dashboard-Centric:** El dashboard es la pantalla principal
2. **Navegación Clara:** Menú lateral o bottom navigation
3. **Acciones Rápidas:** Accesos directos a funciones comunes
4. **Información Visual:** Gráficos y métricas visuales
5. **Responsive:** Funciona en tablets y móviles

### Paleta de Colores

- **Primario:** Configurable por tenant (desde `config.primaryColor`)
- **Secundario:** Configurable por tenant (desde `config.secondaryColor`)
- **Neutros:** Grises para texto y fondos
- **Estados:**
  - Verde: Activo, Éxito
  - Rojo: Inactivo, Error, Cancelado
  - Amarillo: Pendiente, Advertencia
  - Azul: Información

### Componentes Reutilizables

- **MetricsCard:** Card con métrica y cambio porcentual
- **DataTable:** Tabla con datos paginados y filtros
- **FilterBar:** Barra de filtros con chips
- **StatusChip:** Chip de estado (activo/inactivo, etc.)
- **ActionButton:** Botón de acción con icono
- **EmptyState:** Estado vacío con mensaje y acción
- **LoadingState:** Estado de carga
- **ErrorState:** Estado de error con retry

---

## 📋 Plan de Implementación

### Fase 1: Infraestructura Base (3-4 días)

1. **Crear nueva app Flutter**
   - Inicializar proyecto
   - Configurar estructura de carpetas
   - Configurar dependencias (Riverpod, GoRouter, HTTP, etc.)

2. **Autenticación**
   - Integrar Firebase Auth
   - Crear AuthService
   - Crear AuthProvider
   - Pantalla de Login
   - Pantalla de Splash

3. **Configuración**
   - AppConfig (API URL, etc.)
   - HTTP Client con interceptors
   - Manejo de errores global

4. **Router**
   - Configurar GoRouter
   - Rutas básicas
   - Guards de autenticación

### Fase 2: Dashboard y Configuración (4-5 días)

1. **Dashboard**
   - Pantalla principal
   - Cards de métricas
   - Gráficos (opcional)
   - Accesos rápidos

2. **Configuración del Centro**
   - Pantalla de configuración
   - Formularios de edición
   - Subida de logo
   - Selector de colores
   - Configuración de precios
   - Configuración de horarios

3. **Servicios y Providers**
   - TenantConfigService
   - MetricsService
   - Providers correspondientes

### Fase 3: Gestión de Profesores (3-4 días)

1. **Lista de Profesores**
   - Pantalla de lista
   - Filtros y búsqueda
   - Cards de profesores

2. **Invitar Profesor**
   - Formulario de invitación
   - Validaciones
   - Confirmación

3. **Detalle de Profesor**
   - Información completa
   - Estadísticas
   - Acciones (activar/desactivar)

### Fase 4: Gestión de Canchas (3-4 días)

1. **Lista de Canchas**
   - Pantalla de lista
   - Filtros
   - Cards de canchas

2. **Crear/Editar Cancha**
   - Formularios
   - Validaciones
   - Selector de tipo
   - Selector de características

3. **Eliminar Cancha**
   - Confirmación
   - Validación de reservas

### Fase 5: Gestión de Reservas, Pagos y Estudiantes (6-7 días)

1. **Reservas**
   - Lista con filtros avanzados
   - **Crear reserva manual:**
     - Formulario para reserva con profesor (clase individual/grupal)
     - Formulario para reserva sin profesor (alquiler de cancha)
     - Búsqueda de estudiante
     - Selector de profesor (si aplica)
     - Selector de cancha
     - Selector de fecha y hora
     - **Validación de horarios de operación (ciclos diarios):**
       - Verificar que la hora seleccionada esté dentro del rango configurado (open - close)
       - Verificar que el día seleccionado esté en `daysOfWeek` (si está configurado)
       - Mostrar solo slots disponibles según los horarios de operación del centro
       - El sistema calcula automáticamente los slots desde `open` hasta `close` (cada hora)
     - Validación de disponibilidad (cancha y profesor)
     - Cálculo automático de precio
   - Detalle de reserva
   - Editar reserva
   - Acciones (confirmar, cancelar)

2. **Pagos**
   - Lista con filtros
   - Detalle de pago
   - Marcar como pagado

3. **Estudiantes**
   - Lista con búsqueda
   - Detalle de estudiante
   - Ver reservas y pagos del estudiante

**Nota:** Esta fase requiere implementar los endpoints faltantes en el backend primero.

### Fase 6: Reportes (3-4 días)

1. **Pantalla de Reportes**
   - Selector de tipo de reporte
   - Selector de período
   - Visualización de datos
   - Exportación (opcional)

**Nota:** Requiere implementar endpoints de reportes en el backend.

### Fase 7: Polish y Optimización (2-3 días)

1. **UI/UX**
   - Animaciones
   - Loading states mejorados
   - Error handling mejorado
   - Empty states

2. **Performance**
   - Optimización de rebuilds
   - Caching de datos
   - Lazy loading

3. **Tests**
   - Tests unitarios de servicios
   - Tests de widgets
   - Tests de integración

---

## 🚀 Endpoints Backend a Implementar (Prioridad)

### Alta Prioridad (MVP)

1. **GET /api/tenant/bookings** - Listar reservas
2. **POST /api/tenant/bookings** - Crear reserva manual
3. **GET /api/tenant/payments** - Listar pagos
4. **GET /api/tenant/students** - Listar estudiantes

### Media Prioridad

5. **GET /api/tenant/bookings/:id** - Detalle de reserva
6. **PUT /api/tenant/bookings/:id** - Editar reserva
7. **GET /api/tenant/payments/:id** - Detalle de pago
8. **GET /api/tenant/students/:id** - Detalle de estudiante
9. **PATCH /api/tenant/bookings/:id/confirm** - Confirmar reserva
10. **PATCH /api/tenant/bookings/:id/cancel** - Cancelar reserva
11. **PATCH /api/tenant/payments/:id/mark-paid** - Marcar pago como pagado
12. **GET /api/tenant/reports/revenue** - Reporte de ingresos
13. **GET /api/tenant/reports/bookings** - Reporte de reservas

### Baja Prioridad

12. **GET /api/tenant/reports/users** - Reporte de usuarios
13. **GET /api/tenant/notifications** - Notificaciones
14. **PATCH /api/tenant/notifications/:id/read** - Marcar notificación como leída

---

## 📊 Estimación de Tiempo

### Backend (Endpoints Faltantes)
- **Alta Prioridad:** 3-4 días
- **Media Prioridad:** 4-5 días
- **Baja Prioridad:** 2-3 días
- **Total Backend:** 9-12 días

### Frontend (App Flutter)
- **Fase 1:** 3-4 días
- **Fase 2:** 4-5 días
- **Fase 3:** 3-4 días
- **Fase 4:** 3-4 días
- **Fase 5:** 5-6 días
- **Fase 6:** 3-4 días
- **Fase 7:** 2-3 días
- **Total Frontend:** 24-31 días

### Total General
- **Backend + Frontend:** 33-43 días (~6-8 semanas)

---

## ✅ Checklist de Implementación

### Backend
- [ ] `GET /api/tenant/bookings`
- [ ] `POST /api/tenant/bookings` (Crear reserva manual)
- [ ] `GET /api/tenant/bookings/:id`
- [ ] `PUT /api/tenant/bookings/:id` (Editar reserva)
- [ ] `PATCH /api/tenant/bookings/:id/confirm`
- [ ] `PATCH /api/tenant/bookings/:id/cancel`
- [ ] `GET /api/tenant/payments`
- [ ] `GET /api/tenant/payments/:id`
- [ ] `PATCH /api/tenant/payments/:id/mark-paid`
- [ ] `GET /api/tenant/students`
- [ ] `GET /api/tenant/students/:id`
- [ ] `GET /api/tenant/reports/revenue`
- [ ] `GET /api/tenant/reports/bookings`
- [ ] `GET /api/tenant/reports/users`
- [ ] Tests unitarios
- [ ] Tests de integración

### Frontend
- [ ] Crear proyecto Flutter
- [ ] Configurar estructura
- [ ] Autenticación (Firebase Auth)
- [ ] Dashboard principal
- [ ] Configuración del centro
- [ ] Gestión de profesores
- [ ] Gestión de canchas
- [ ] Gestión de reservas (incluyendo creación manual)
- [ ] Gestión de pagos
- [ ] Gestión de estudiantes
- [ ] Reportes
- [ ] Tests
- [ ] Polish y optimización

---

## 📚 Referencias

- **Backend Controller:** `backend/src/application/controllers/TenantAdminController.ts`
- **Backend Routes:** `backend/src/presentation/routes/tenant.ts`
- **Historia Linear TEN-88:** https://linear.app/tennis-management-system/issue/TEN-88
- **Modelo Court:** `backend/src/infrastructure/database/models/CourtModel.ts`
- **Modelo Tenant:** `backend/src/infrastructure/database/models/TenantModel.ts`

---

**Documento creado:** 30 de Diciembre, 2025  
**Última actualización:** 30 de Diciembre, 2025  
**Autor:** Análisis Automatizado

