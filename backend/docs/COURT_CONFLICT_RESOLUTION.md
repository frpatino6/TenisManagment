# Resolución de Conflictos: Slots de Profesor vs Alquiler Directo de Cancha

## 📋 Contexto del Problema

### Flujos del Sistema

1. **Agenda de Profesor**: 
   - El profesor define un rango horario (ej: 6am-12pm) en una cancha específica
   - Esto genera `Schedule` con `isAvailable: true` (slots virtuales disponibles)
   - Los estudiantes pueden reservar estos slots creando un `Booking` con `scheduleId`

2. **Alquiler Directo (Court Rental)**:
   - Un cliente puede reservar la cancha directamente sin profesor
   - Crea un `Booking` con `serviceType: 'court_rental'` y `courtId` asignado

### El Bug

**Escenario Problemático:**
1. Profesor crea schedule: Cancha 1, 6am-12pm → Genera slots virtuales (7:00, 8:00, 9:00, etc.)
2. Cliente alquila cancha directamente: Cancha 1, 8:00 AM → Se crea `Booking` con `court_rental`
3. **PROBLEMA**: El slot de 8:00 AM del profesor sigue apareciendo como disponible
4. Estudiante intenta reservar el slot de 8:00 AM → Se genera doble reserva (overbooking)

### Análisis de la Causa Raíz

El método `getCourtAvailableSlots` en `StudentDashboardController.ts` (líneas 1330-1405):

✅ **Hace bien:**
- Consulta `Bookings` con `court_rental` y los marca como ocupados
- Consulta `Schedules` con `isBlocked: true` y los marca como ocupados

❌ **No hace:**
- NO valida si un `Schedule` disponible (`isAvailable: true`) tiene conflicto temporal con un `Booking` de tipo `court_rental`
- NO filtra los schedules disponibles que están en conflicto con alquileres directos

Los métodos que listan schedules disponibles (`getAvailableSchedules`, `getProfessorSchedules`, etc.) tampoco validan conflictos con `court_rental`.

---

## 🎯 Solución Propuesta

### Enfoque: Validación en Tiempo Real (Recomendado)

**Principio**: Los `Bookings` son la fuente de verdad para la ocupación real de la cancha. Los `Schedules` son "intenciones" que deben validarse contra la realidad.

**Ventajas:**
- ✅ No modifica datos existentes (schedules permanecen intactos)
- ✅ Permite reactivación automática si se cancela el `court_rental`
- ✅ Más flexible y fácil de mantener
- ✅ Single Source of Truth (Bookings = realidad)

### Alternativa Rechazada: Invalidación Automática

**Por qué NO invalidar automáticamente:**
- ❌ Modifica datos existentes (schedules)
- ❌ Requiere lógica adicional para reactivar schedules al cancelar
- ❌ Más complejo de mantener
- ❌ Puede causar inconsistencias si hay errores en la invalidación

---

## 📊 Diagrama de Flujo de la Solución

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONSULTA DE SLOTS DISPONIBLES                │
│              (getCourtAvailableSlots / getAvailableSchedules)   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  1. Obtener Schedules Disponibles   │
        │     (isAvailable: true,              │
        │      isBlocked: false)               │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  2. Obtener Bookings Activos        │
        │     - court_rental bookings         │
        │     - bookings con scheduleId        │
        │     (status: 'confirmed'|'pending')  │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  3. VALIDACIÓN CRUZADA               │
        │     Para cada Schedule disponible:   │
        │     ┌─────────────────────────────┐ │
        │     │ ¿Hay Booking court_rental    │ │
        │     │ que se solape con este       │ │
        │     │ Schedule?                    │ │
        │     └─────────────────────────────┘ │
        │              │                       │
        │         ┌────┴────┐                 │
        │         │         │                 │
        │        SÍ        NO                │
        │         │         │                 │
        │         ▼         ▼                 │
        │    EXCLUIR    INCLUIR              │
        │    Schedule    Schedule             │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  4. Retornar Schedules Válidos      │
        │     (sin conflictos con court_rental)│
        └─────────────────────────────────────┘
```

---

## 🔍 Pseudocódigo de la Solución

### 1. Query para Validar Conflictos de Schedule con Court Rental

```typescript
/**
 * Valida si un Schedule tiene conflicto con un Booking de tipo court_rental
 * @param schedule - El Schedule a validar
 * @param tenantId - ID del tenant
 * @returns true si hay conflicto, false si está disponible
 */
async function hasCourtRentalConflict(
  schedule: ScheduleDocument,
  tenantId: Types.ObjectId
): Promise<boolean> {
  // Si el schedule no tiene courtId asignado, no puede tener conflicto
  if (!schedule.courtId) {
    return false;
  }

  // Buscar bookings de tipo court_rental que se solapen con el schedule
  const conflictingBooking = await BookingModel.findOne({
    tenantId: tenantId,
    courtId: schedule.courtId,
    serviceType: 'court_rental',
    status: { $in: ['confirmed', 'pending'] },
    // Validar solapamiento temporal
    $or: [
      // Caso 1: Booking empieza antes y termina durante el schedule
      {
        bookingDate: { $lt: schedule.endTime },
        endTime: { $gt: schedule.startTime }
      },
      // Caso 2: Booking sin endTime (duración por defecto 1 hora)
      {
        endTime: { $exists: false },
        bookingDate: {
          $gte: schedule.startTime,
          $lt: schedule.endTime
        }
      },
      // Caso 3: Booking contiene completamente el schedule
      {
        bookingDate: { $lte: schedule.startTime },
        endTime: { $gte: schedule.endTime }
      }
    ]
  });

  return !!conflictingBooking;
}
```

### 2. Modificación de getCourtAvailableSlots

```typescript
getCourtAvailableSlots = async (req: AuthenticatedRequest, res: Response) => {
  // ... código existente hasta línea 1329 ...

  // Obtener bookings (ya existe)
  const bookings = await BookingModel.find({
    tenantId: new Types.ObjectId(tenantId),
    courtId: new Types.ObjectId(courtId),
    status: { $in: ['confirmed', 'pending'] },
    $or: [
      { serviceType: 'court_rental', bookingDate: { $gte: targetDate, $lt: nextDay } },
      { scheduleId: { $exists: true } }
    ]
  }).populate('scheduleId').lean();

  // Obtener schedules bloqueados (ya existe)
  const blockedSchedules = await ScheduleModel.find({
    tenantId: new Types.ObjectId(tenantId),
    courtId: new Types.ObjectId(courtId),
    isBlocked: true,
    startTime: { $gte: queryStart, $lt: queryEnd }
  }).lean();

  // ✅ NUEVO: Obtener schedules disponibles y validar conflictos
  const availableSchedules = await ScheduleModel.find({
    tenantId: new Types.ObjectId(tenantId),
    courtId: new Types.ObjectId(courtId),
    isAvailable: true,
    isBlocked: { $ne: true },
    startTime: { $gte: queryStart, $lt: queryEnd }
  }).lean();

  // Marcar slots ocupados por bookings (código existente)
  bookings.forEach((booking) => {
    // ... código existente ...
  });

  // Marcar slots ocupados por schedules bloqueados (código existente)
  blockedSchedules.forEach((schedule) => {
    // ... código existente ...
  });

  // ✅ NUEVO: Validar schedules disponibles contra court_rental bookings
  for (const schedule of availableSchedules) {
    const hasConflict = await hasCourtRentalConflict(schedule, new Types.ObjectId(tenantId));
    
    if (hasConflict) {
      // Marcar el slot como ocupado si hay conflicto con court_rental
      const scheduleStart = new Date(schedule.startTime);
      const hour = scheduleStart.getUTCHours();
      bookedSlots.add(`${hour.toString().padStart(2, '0')}:00`);
    }
  }

  // Generar slots disponibles (código existente)
  // ... resto del código ...
};
```

### 3. Modificación de getAvailableSchedules

```typescript
getAvailableSchedules = async (req: AuthenticatedRequest, res: Response) => {
  // ... código existente hasta obtener schedules ...

  const schedules = await ScheduleModel.find(query)
    .populate('tenantId', 'name slug config')
    .populate('courtId', 'name')
    .sort({ startTime: 1 })
    .limit(100);

  const schedulesData: any[] = [];

  for (const schedule of schedules) {
    // ... validaciones existentes ...

    // ✅ NUEVO: Validar conflicto con court_rental
    if (schedule.courtId) {
      const hasConflict = await hasCourtRentalConflict(
        schedule,
        new Types.ObjectId(tenantId || schedule.tenantId.toString())
      );
      
      // Excluir schedules con conflicto
      if (hasConflict) {
        continue;
      }
    }

    schedulesData.push({
      // ... datos del schedule ...
    });
  }

  res.json({ items: schedulesData });
};
```

### 4. Optimización: Query Agregada para Mejor Performance

```typescript
/**
 * Versión optimizada usando agregación de MongoDB
 * Valida múltiples schedules en una sola query
 */
async function filterSchedulesWithCourtRentalConflicts(
  schedules: ScheduleDocument[],
  tenantId: Types.ObjectId
): Promise<ScheduleDocument[]> {
  if (schedules.length === 0) return [];

  // Obtener todos los court_rental bookings activos para las canchas involucradas
  const courtIds = [...new Set(schedules.map(s => s.courtId?.toString()).filter(Boolean))];
  
  const courtRentalBookings = await BookingModel.find({
    tenantId: tenantId,
    courtId: { $in: courtIds.map(id => new Types.ObjectId(id)) },
    serviceType: 'court_rental',
    status: { $in: ['confirmed', 'pending'] }
  }).lean();

  // Filtrar schedules que tienen conflicto
  return schedules.filter(schedule => {
    if (!schedule.courtId) return true; // Sin cancha = sin conflicto

    const scheduleStart = schedule.startTime;
    const scheduleEnd = schedule.endTime;

    // Buscar bookings que se solapen con este schedule
    const hasConflict = courtRentalBookings.some(booking => {
      if (!booking.courtId || booking.courtId.toString() !== schedule.courtId.toString()) {
        return false;
      }

      const bookingStart = booking.bookingDate;
      const bookingEnd = booking.endTime || new Date(bookingStart.getTime() + 60 * 60 * 1000); // Default 1 hora

      // Verificar solapamiento
      return bookingStart < scheduleEnd && bookingEnd > scheduleStart;
    });

    return !hasConflict; // Incluir solo si NO hay conflicto
  });
}
```

---

## 🛠️ Implementación Recomendada

### Paso 1: Crear Servicio de Validación

Crear `src/application/services/ScheduleValidationService.ts`:

```typescript
import { Types } from 'mongoose';
import { ScheduleModel, ScheduleDocument } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';

export class ScheduleValidationService {
  /**
   * Valida si un schedule tiene conflicto con un court_rental booking
   */
  async hasCourtRentalConflict(
    schedule: ScheduleDocument,
    tenantId: Types.ObjectId
  ): Promise<boolean> {
    if (!schedule.courtId) {
      return false;
    }

    const conflictingBooking = await BookingModel.findOne({
      tenantId,
      courtId: schedule.courtId,
      serviceType: 'court_rental',
      status: { $in: ['confirmed', 'pending'] },
      $or: [
        {
          bookingDate: { $lt: schedule.endTime },
          endTime: { $gt: schedule.startTime }
        },
        {
          endTime: { $exists: false },
          bookingDate: {
            $gte: schedule.startTime,
            $lt: schedule.endTime
          }
        }
      ]
    });

    return !!conflictingBooking;
  }

  /**
   * Filtra múltiples schedules removiendo los que tienen conflicto con court_rental
   */
  async filterSchedulesWithoutConflicts(
    schedules: ScheduleDocument[],
    tenantId: Types.ObjectId
  ): Promise<ScheduleDocument[]> {
    if (schedules.length === 0) return [];

    const courtIds = [...new Set(
      schedules
        .map(s => s.courtId?.toString())
        .filter(Boolean) as string[]
    )];

    if (courtIds.length === 0) return schedules;

    const courtRentalBookings = await BookingModel.find({
      tenantId,
      courtId: { $in: courtIds.map(id => new Types.ObjectId(id)) },
      serviceType: 'court_rental',
      status: { $in: ['confirmed', 'pending'] }
    }).lean();

    return schedules.filter(schedule => {
      if (!schedule.courtId) return true;

      const scheduleStart = schedule.startTime;
      const scheduleEnd = schedule.endTime;

      const hasConflict = courtRentalBookings.some(booking => {
        if (!booking.courtId || 
            booking.courtId.toString() !== schedule.courtId.toString()) {
          return false;
        }

        const bookingStart = booking.bookingDate;
        const bookingEnd = booking.endTime || 
          new Date(bookingStart.getTime() + 60 * 60 * 1000);

        return bookingStart < scheduleEnd && bookingEnd > scheduleStart;
      });

      return !hasConflict;
    });
  }
}
```

### Paso 2: Modificar Controllers

1. **StudentDashboardController.getCourtAvailableSlots**: Agregar validación antes de generar slots disponibles
2. **StudentDashboardController.getAvailableSchedules**: Filtrar schedules con conflictos
3. **StudentDashboardController.getProfessorSchedules**: Filtrar schedules con conflictos
4. **StudentDashboardController.getTenantSchedules**: Filtrar schedules con conflictos
5. **StudentDashboardController.getAllAvailableSchedules**: Filtrar schedules con conflictos

### Paso 3: Validación en BookingService

También validar al crear un booking desde un schedule:

```typescript
// En BookingService.createBooking
if (scheduleId) {
  // ... código existente ...
  
  // ✅ NUEVO: Validar que el schedule no tenga conflicto con court_rental
  const schedule = await ScheduleModel.findById(scheduleId);
  if (schedule && schedule.courtId) {
    const hasConflict = await this.scheduleValidationService.hasCourtRentalConflict(
      schedule,
      tenantId
    );
    
    if (hasConflict) {
      throw new Error('El horario seleccionado no está disponible debido a un alquiler de cancha');
    }
  }
}
```

---

## ✅ Casos de Prueba

### Caso 1: Slot Disponible Sin Conflicto
- **Setup**: Profesor crea schedule 8:00-9:00, Cancha 1
- **Acción**: Consultar slots disponibles
- **Esperado**: Slot 8:00 aparece como disponible

### Caso 2: Slot Bloqueado Por Court Rental
- **Setup**: 
  1. Profesor crea schedule 8:00-9:00, Cancha 1
  2. Cliente alquila cancha 8:00-9:00, Cancha 1
- **Acción**: Consultar slots disponibles
- **Esperado**: Slot 8:00 NO aparece como disponible

### Caso 3: Intento de Reserva Con Conflicto
- **Setup**: 
  1. Profesor crea schedule 8:00-9:00, Cancha 1
  2. Cliente alquila cancha 8:00-9:00, Cancha 1
- **Acción**: Estudiante intenta reservar schedule 8:00-9:00
- **Esperado**: Error "El horario seleccionado no está disponible"

### Caso 4: Reactivación Automática
- **Setup**: 
  1. Profesor crea schedule 8:00-9:00, Cancha 1
  2. Cliente alquila cancha 8:00-9:00, Cancha 1
  3. Cliente cancela alquiler
- **Acción**: Consultar slots disponibles
- **Esperado**: Slot 8:00 vuelve a aparecer como disponible

---

## 📈 Consideraciones de Performance

1. **Índices Necesarios**:
   ```typescript
   // Ya existen en BookingModel:
   BookingModel.index({ tenantId: 1, courtId: 1, bookingDate: 1, endTime: 1, status: 1 });
   BookingModel.index({ tenantId: 1, serviceType: 1, bookingDate: 1, status: 1 });
   ```

2. **Optimización**: Usar `filterSchedulesWithoutConflicts` para validar múltiples schedules en batch en lugar de hacer queries individuales.

3. **Caching**: Considerar cachear resultados de disponibilidad por cortos períodos (ej: 30 segundos) para reducir carga en la base de datos.

---

## 🎯 Resumen de la Solución

**Problema**: Los slots de profesor no se validan contra alquileres directos de cancha, causando overbooking.

**Solución**: Validación en tiempo real que filtra schedules disponibles que tienen conflicto temporal con bookings de tipo `court_rental`.

**Implementación**:
1. Crear `ScheduleValidationService` con métodos de validación
2. Modificar endpoints que listan schedules para filtrar conflictos
3. Validar al crear bookings desde schedules
4. Usar queries optimizadas en batch para mejor performance

**Ventajas**:
- ✅ No modifica datos existentes
- ✅ Reactivación automática al cancelar
- ✅ Single Source of Truth (Bookings)
- ✅ Fácil de mantener y debuggear
