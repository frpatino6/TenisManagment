# Demo Environment Provisioning Guide

## Propósito

Este documento describe cómo aprovisionar un **entorno DEMO completo** en la base de datos de UAT para que potenciales clientes puedan probar la aplicación con datos reales de demostración.

## Credenciales de Acceso Demo

| Rol | Email | Password | Descripción |
|-----|-------|----------|-------------|
| **Admin** | `admin@demo.courthub.co` | `Demo2024!` | Administrador del centro demo |
| **Profesor** | `profesor@demo.courthub.co` | `Demo2024!` | Profesor de tenis demo |
| **Estudiante** | `estudiante@demo.courthub.co` | `Demo2024!` | Cliente/estudiante demo |

## Prerequisitos

1. Acceso al MCP de MongoDB (`user-MongoDB`)
2. Conexión a la base de datos de **UAT**
3. Usuarios creados en Firebase Auth con los emails anteriores

---

## Paso 1: Crear Usuarios en Firebase Auth

**IMPORTANTE**: Antes de insertar en MongoDB, crear los usuarios en Firebase Auth:

```
Email: admin@demo.courthub.co
Password: Demo2024!

Email: profesor@demo.courthub.co
Password: Demo2024!

Email: estudiante@demo.courthub.co
Password: Demo2024!
```

Guardar los `firebaseUid` generados para usarlos en los pasos siguientes.

---

## Paso 2: Insertar AuthUsers en MongoDB

### 2.1 AuthUser - Admin del Tenant

```javascript
// Colección: authusers
// Usar MCP MongoDB: insertOne
{
  "_id": ObjectId("demo00000000000000000001"),
  "email": "admin@demo.courthub.co",
  "name": "Admin Demo",
  "role": "tenant_admin",
  "firebaseUid": "<FIREBASE_UID_ADMIN>",
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

### 2.2 AuthUser - Profesor

```javascript
// Colección: authusers
{
  "_id": ObjectId("demo00000000000000000002"),
  "email": "profesor@demo.courthub.co",
  "name": "Carlos Demo",
  "role": "professor",
  "linkedId": ObjectId("demo00000000000000000012"), // ID del Professor
  "firebaseUid": "<FIREBASE_UID_PROFESOR>",
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

### 2.3 AuthUser - Estudiante

```javascript
// Colección: authusers
{
  "_id": ObjectId("demo00000000000000000003"),
  "email": "estudiante@demo.courthub.co",
  "name": "María Demo",
  "role": "student",
  "linkedId": ObjectId("demo00000000000000000013"), // ID del Student
  "firebaseUid": "<FIREBASE_UID_ESTUDIANTE>",
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 3: Crear el Tenant (Centro Demo)

```javascript
// Colección: tenants
{
  "_id": ObjectId("demo00000000000000000010"),
  "name": "Academia Demo CourtHub",
  "slug": "demo-courthub",
  "adminUserId": ObjectId("demo00000000000000000001"),
  "config": {
    "logo": "https://placeholder.com/demo-logo.png",
    "website": "https://demo.courthub.co",
    "address": "Calle Demo 123, Bogotá, Colombia",
    "basePricing": {
      "individualClass": 80000,
      "groupClass": 50000,
      "courtRental": 60000
    },
    "operatingHours": {
      "schedule": [
        { "dayOfWeek": 1, "open": "06:00", "close": "22:00" },
        { "dayOfWeek": 2, "open": "06:00", "close": "22:00" },
        { "dayOfWeek": 3, "open": "06:00", "close": "22:00" },
        { "dayOfWeek": 4, "open": "06:00", "close": "22:00" },
        { "dayOfWeek": 5, "open": "06:00", "close": "22:00" },
        { "dayOfWeek": 6, "open": "07:00", "close": "20:00" },
        { "dayOfWeek": 0, "open": "08:00", "close": "18:00" }
      ]
    },
    "payments": {
      "enableOnlinePayments": false,
      "activeProvider": null
    }
  },
  "isActive": true,
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 4: Crear TenantAdmin (Relación)

```javascript
// Colección: tenantadmins
{
  "_id": ObjectId("demo00000000000000000020"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "adminUserId": ObjectId("demo00000000000000000001"),
  "isActive": true,
  "joinedAt": new Date(),
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 5: Crear Professor

```javascript
// Colección: professors
{
  "_id": ObjectId("demo00000000000000000012"),
  "authUserId": ObjectId("demo00000000000000000002"),
  "name": "Carlos Demo",
  "email": "profesor@demo.courthub.co",
  "phone": "+57 300 123 4567",
  "specialties": ["Tenis Individual", "Tenis Grupal", "Clínicas"],
  "hourlyRate": 80000,
  "experienceYears": 8,
  "pricing": {
    "individualClass": 85000,
    "groupClass": 55000,
    "courtRental": 60000
  },
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 6: Crear ProfessorTenant (Relación)

```javascript
// Colección: professortenants
{
  "_id": ObjectId("demo00000000000000000021"),
  "professorId": ObjectId("demo00000000000000000012"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "pricing": {
    "individualClass": 85000,
    "groupClass": 55000,
    "courtRental": 60000
  },
  "isActive": true,
  "joinedAt": new Date(),
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 7: Crear Student

```javascript
// Colección: students
{
  "_id": ObjectId("demo00000000000000000013"),
  "authUserId": ObjectId("demo00000000000000000003"),
  "name": "María Demo",
  "email": "estudiante@demo.courthub.co",
  "phone": "+57 310 987 6543",
  "membershipType": "premium",
  "balance": 250000,
  "activeTenantId": ObjectId("demo00000000000000000010"),
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 8: Crear StudentTenant (Relación)

```javascript
// Colección: studenttenants
{
  "_id": ObjectId("demo00000000000000000022"),
  "studentId": ObjectId("demo00000000000000000013"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "balance": 250000,
  "isActive": true,
  "joinedAt": new Date(),
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 9: Crear Canchas (Courts)

```javascript
// Colección: courts
// Insertar múltiples documentos

// Cancha 1 - Tenis Principal
{
  "_id": ObjectId("demo00000000000000000030"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Cancha Central",
  "type": "tennis",
  "price": 70000,
  "isActive": true,
  "description": "Cancha principal con superficie de arcilla, iluminación LED profesional",
  "features": ["Iluminación LED", "Graderías", "Arcilla", "Techada"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Cancha 2 - Tenis Secundaria
{
  "_id": ObjectId("demo00000000000000000031"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Cancha 2",
  "type": "tennis",
  "price": 60000,
  "isActive": true,
  "description": "Cancha de tenis con superficie dura",
  "features": ["Iluminación", "Superficie dura"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Cancha 3 - Tenis
{
  "_id": ObjectId("demo00000000000000000032"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Cancha 3",
  "type": "tennis",
  "price": 60000,
  "isActive": true,
  "description": "Cancha de tenis con césped sintético",
  "features": ["Iluminación", "Césped sintético"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Cancha 4 - Padel
{
  "_id": ObjectId("demo00000000000000000033"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Padel 1",
  "type": "padel",
  "price": 80000,
  "isActive": true,
  "description": "Cancha de pádel panorámica",
  "features": ["Panorámica", "Iluminación LED", "Césped artificial"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Cancha 5 - Padel
{
  "_id": ObjectId("demo00000000000000000034"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Padel 2",
  "type": "padel",
  "price": 75000,
  "isActive": true,
  "description": "Cancha de pádel estándar",
  "features": ["Iluminación", "Césped artificial"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Cancha 6 - Multi
{
  "_id": ObjectId("demo00000000000000000035"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "name": "Cancha Multideporte",
  "type": "multi",
  "price": 50000,
  "isActive": true,
  "description": "Cancha multiusos para entrenamiento",
  "features": ["Multiusos", "Iluminación básica"],
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 10: Crear Schedules (Horarios del Profesor)

Crear horarios para los próximos 7 días con slots de 1 hora:

```javascript
// Colección: schedules
// Crear múltiples slots para cada día

// Ejemplo para un día (repetir para cada día de la semana)
// Fecha: HOY + índice del día

// Slot 8:00 - 9:00
{
  "_id": ObjectId(), // Auto-generado
  "tenantId": ObjectId("demo00000000000000000010"),
  "professorId": ObjectId("demo00000000000000000012"),
  "courtId": ObjectId("demo00000000000000000030"),
  "date": new Date("2024-XX-XX"), // Fecha del día
  "startTime": new Date("2024-XX-XXT08:00:00"),
  "endTime": new Date("2024-XX-XXT09:00:00"),
  "isAvailable": true,
  "isBlocked": false,
  "status": "pending",
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Repetir para slots: 9:00-10:00, 10:00-11:00, 11:00-12:00, etc.
```

**Nota**: Los schedules deben crearse con fechas dinámicas relativas a la fecha actual.

---

## Paso 11: Crear Bookings de Ejemplo

```javascript
// Colección: bookings
// Crear algunas reservas de ejemplo (pasadas y futuras)

// Booking 1 - Clase individual confirmada (pasada)
{
  "_id": ObjectId("demo00000000000000000040"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "scheduleId": ObjectId(), // ID del schedule correspondiente
  "studentId": ObjectId("demo00000000000000000013"),
  "professorId": ObjectId("demo00000000000000000012"),
  "courtId": ObjectId("demo00000000000000000030"),
  "serviceType": "individual_class",
  "price": 85000,
  "status": "completed",
  "notes": "Clase de técnica de saque",
  "bookingDate": new Date("2024-XX-XXT09:00:00"), // Fecha pasada
  "endTime": new Date("2024-XX-XXT10:00:00"),
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Booking 2 - Alquiler de cancha (futura)
{
  "_id": ObjectId("demo00000000000000000041"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "studentId": ObjectId("demo00000000000000000013"),
  "courtId": ObjectId("demo00000000000000000031"),
  "serviceType": "court_rental",
  "price": 60000,
  "status": "confirmed",
  "notes": "Práctica libre",
  "bookingDate": new Date(), // Fecha futura
  "endTime": new Date(),
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Paso 12: Crear Payments de Ejemplo

```javascript
// Colección: payments
// Crear algunos pagos históricos

// Payment 1 - Recarga de saldo
{
  "_id": ObjectId("demo00000000000000000050"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "studentId": ObjectId("demo00000000000000000013"),
  "amount": 200000,
  "date": new Date("2024-01-15"),
  "status": "paid",
  "method": "transfer",
  "description": "Recarga de saldo inicial",
  "isOnline": false,
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Payment 2 - Pago de clase
{
  "_id": ObjectId("demo00000000000000000051"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "studentId": ObjectId("demo00000000000000000013"),
  "professorId": ObjectId("demo00000000000000000012"),
  "bookingId": ObjectId("demo00000000000000000040"),
  "amount": 85000,
  "date": new Date("2024-01-20"),
  "status": "paid",
  "method": "wallet",
  "description": "Pago clase individual - Técnica de saque",
  "isOnline": false,
  "createdAt": new Date(),
  "updatedAt": new Date()
}

// Payment 3 - Recarga adicional
{
  "_id": ObjectId("demo00000000000000000052"),
  "tenantId": ObjectId("demo00000000000000000010"),
  "studentId": ObjectId("demo00000000000000000013"),
  "amount": 150000,
  "date": new Date("2024-02-01"),
  "status": "paid",
  "method": "card",
  "description": "Recarga de saldo",
  "isOnline": false,
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

---

## Resumen de IDs Demo

| Entidad | ObjectId |
|---------|----------|
| **AuthUser Admin** | `demo00000000000000000001` |
| **AuthUser Profesor** | `demo00000000000000000002` |
| **AuthUser Estudiante** | `demo00000000000000000003` |
| **Tenant** | `demo00000000000000000010` |
| **Professor** | `demo00000000000000000012` |
| **Student** | `demo00000000000000000013` |
| **TenantAdmin** | `demo00000000000000000020` |
| **ProfessorTenant** | `demo00000000000000000021` |
| **StudentTenant** | `demo00000000000000000022` |
| **Court Central** | `demo00000000000000000030` |
| **Court 2** | `demo00000000000000000031` |
| **Court 3** | `demo00000000000000000032` |
| **Padel 1** | `demo00000000000000000033` |
| **Padel 2** | `demo00000000000000000034` |
| **Court Multi** | `demo00000000000000000035` |

---

## Ejecución con MCP MongoDB

Para ejecutar este aprovisionamiento usando el MCP de MongoDB:

1. **Conectar a la base de datos UAT**
2. **Ejecutar cada insert en orden** (respetando dependencias)
3. **Verificar los datos insertados**

### Orden de Ejecución

1. AuthUsers (3 documentos)
2. Tenant (1 documento)
3. TenantAdmin (1 documento)
4. Professor (1 documento)
5. ProfessorTenant (1 documento)
6. Student (1 documento)
7. StudentTenant (1 documento)
8. Courts (6 documentos)
9. Schedules (múltiples - dinámico)
10. Bookings (ejemplos)
11. Payments (ejemplos)

---

## Script de Limpieza (Rollback)

Para eliminar todos los datos demo:

```javascript
// Eliminar en orden inverso (por dependencias)
db.payments.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.bookings.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.schedules.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.courts.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.studenttenants.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.students.deleteMany({ _id: ObjectId("demo00000000000000000013") });
db.professortenants.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.professors.deleteMany({ _id: ObjectId("demo00000000000000000012") });
db.tenantadmins.deleteMany({ tenantId: ObjectId("demo00000000000000000010") });
db.tenants.deleteMany({ _id: ObjectId("demo00000000000000000010") });
db.authusers.deleteMany({ 
  _id: { 
    $in: [
      ObjectId("demo00000000000000000001"),
      ObjectId("demo00000000000000000002"),
      ObjectId("demo00000000000000000003")
    ]
  }
});
```

---

## Notas Importantes

1. **Firebase UIDs**: Reemplazar `<FIREBASE_UID_*>` con los UIDs reales de Firebase Auth
2. **Fechas Dinámicas**: Los schedules y bookings deben usar fechas relativas a la fecha actual
3. **Ambiente**: Este aprovisionamiento es para **UAT solamente**
4. **Mantenimiento**: Considerar crear un cron job para regenerar datos demo periódicamente
5. **Seguridad**: Las credenciales demo son públicas - NO usar en producción

---

## Verificación Post-Aprovisionamiento

Después de ejecutar el aprovisionamiento, verificar:

- [ ] Los 3 usuarios pueden hacer login en la app
- [ ] El admin puede ver el dashboard del centro
- [ ] El profesor puede ver sus horarios y clases
- [ ] El estudiante puede ver canchas y reservar
- [ ] Los reportes muestran datos históricos
- [ ] El balance del estudiante es correcto (250,000 COP)
