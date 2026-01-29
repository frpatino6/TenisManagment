# Implementación Técnica: Resolución de Conflictos Court Rental vs Schedules

## 📝 Queries MongoDB Específicas

### Query 1: Detectar Conflictos de Schedule con Court Rental

```typescript
/**
 * Query MongoDB para encontrar bookings de court_rental que se solapan con un schedule
 * 
 * @param tenantId - ID del tenant
 * @param courtId - ID de la cancha
 * @param scheduleStartTime - Hora de inicio del schedule
 * @param scheduleEndTime - Hora de fin del schedule
 * @returns BookingDocument | null
 */
const findConflictingCourtRental = async (
  tenantId: Types.ObjectId,
  courtId: Types.ObjectId,
  scheduleStartTime: Date,
  scheduleEndTime: Date
): Promise<BookingDocument | null> => {
  return await BookingModel.findOne({
    tenantId: tenantId,
    courtId: courtId,
    serviceType: 'court_rental',
    status: { $in: ['confirmed', 'pending'] },
    $or: [
      // Caso 1: Booking se solapa parcialmente con el schedule
      // Booking empieza antes del schedule y termina durante el schedule
      {
        bookingDate: { $lt: scheduleEndTime },
        endTime: { $gt: scheduleStartTime }
      },
      // Caso 2: Booking sin endTime (duración por defecto 1 hora)
      // Verificar si el bookingDate está dentro del rango del schedule
      {
        endTime: { $exists: false },
        bookingDate: {
          $gte: scheduleStartTime,
          $lt: scheduleEndTime
        }
      },
      // Caso 3: Booking contiene completamente el schedule
      {
        bookingDate: { $lte: scheduleStartTime },
        endTime: { $gte: scheduleEndTime }
      },
      // Caso 4: Booking está completamente dentro del schedule
      {
        bookingDate: { $gte: scheduleStartTime },
        endTime: { $lte: scheduleEndTime }
      }
    ]
  });
};
```

### Query 2: Filtrar Múltiples Schedules en Batch

```typescript
/**
 * Query optimizada para obtener todos los court_rental bookings relevantes
 * y luego filtrar schedules en memoria (más eficiente que N queries)
 * 
 * @param schedules - Array de schedules a validar
 * @param tenantId - ID del tenant
 * @returns Array de schedules sin conflictos
 */
const filterSchedulesBatch = async (
  schedules: ScheduleDocument[],
  tenantId: Types.ObjectId
): Promise<ScheduleDocument[]> => {
  if (schedules.length === 0) return [];

  // Extraer courtIds únicos de los schedules que tienen cancha asignada
  const courtIds = [...new Set(
    schedules
      .map(s => s.courtId?.toString())
      .filter(Boolean) as string[]
  )];

  if (courtIds.length === 0) {
    // Si ningún schedule tiene cancha, todos están disponibles
    return schedules;
  }

  // Obtener TODOS los court_rental bookings activos para estas canchas
  // en un rango de tiempo que cubra todos los schedules
  const minStartTime = new Date(Math.min(...schedules.map(s => s.startTime.getTime())));
  const maxEndTime = new Date(Math.max(...schedules.map(s => s.endTime.getTime())));

  const courtRentalBookings = await BookingModel.find({
    tenantId: tenantId,
    courtId: { $in: courtIds.map(id => new Types.ObjectId(id)) },
    serviceType: 'court_rental',
    status: { $in: ['confirmed', 'pending'] },
    $or: [
      // Bookings que se solapan con el rango total
      {
        bookingDate: { $lt: maxEndTime },
        endTime: { $gt: minStartTime }
      },
      // Bookings sin endTime dentro del rango
      {
        endTime: { $exists: false },
        bookingDate: {
          $gte: minStartTime,
          $lt: maxEndTime
        }
      }
    ]
  }).lean();

  // Filtrar schedules en memoria
  return schedules.filter(schedule => {
    // Si el schedule no tiene cancha, no puede tener conflicto
    if (!schedule.courtId) {
      return true;
    }

    const scheduleStart = schedule.startTime;
    const scheduleEnd = schedule.endTime;

    // Buscar si hay algún booking que se solape con este schedule
    const hasConflict = courtRentalBookings.some(booking => {
      // Verificar que el booking sea para la misma cancha
      if (!booking.courtId || 
          booking.courtId.toString() !== schedule.courtId.toString()) {
        return false;
      }

      const bookingStart = booking.bookingDate;
      // Si no tiene endTime, asumir duración de 1 hora
      const bookingEnd = booking.endTime || 
        new Date(bookingStart.getTime() + 60 * 60 * 1000);

      // Verificar solapamiento temporal
      // Dos intervalos se solapan si: start1 < end2 && start2 < end1
      return bookingStart < scheduleEnd && bookingEnd > scheduleStart;
    });

    // Incluir solo si NO hay conflicto
    return !hasConflict;
  });
};
```

### Query 3: Validación en getCourtAvailableSlots

```typescript
/**
 * Modificación del método getCourtAvailableSlots para incluir validación
 * de schedules disponibles contra court_rental bookings
 */
getCourtAvailableSlots = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  // ... código existente hasta obtener bookings y blockedSchedules ...

  // ✅ NUEVO: Obtener schedules disponibles para esta cancha y fecha
  const availableSchedules = await ScheduleModel.find({
    tenantId: new Types.ObjectId(tenantId),
    courtId: new Types.ObjectId(courtId),
    isAvailable: true,
    $or: [
      { isBlocked: { $exists: false } },
      { isBlocked: false }
    ],
    startTime: {
      $gte: queryStart,
      $lt: queryEnd
    }
  }).lean();

  // Marcar slots ocupados por bookings existentes (código existente)
  bookings.forEach((booking) => {
    // ... código existente ...
  });

  // Marcar slots ocupados por schedules bloqueados (código existente)
  blockedSchedules.forEach((schedule) => {
    // ... código existente ...
  });

  // ✅ NUEVO: Validar schedules disponibles contra court_rental bookings
  // Usar batch filtering para mejor performance
  const validSchedules = await filterSchedulesBatch(
    availableSchedules,
    new Types.ObjectId(tenantId)
  );

  // Marcar como ocupados los schedules que fueron filtrados (tienen conflicto)
  const invalidScheduleIds = new Set(
    availableSchedules
      .filter(s => !validSchedules.some(vs => vs._id.toString() === s._id.toString()))
      .map(s => s._id.toString())
  );

  availableSchedules.forEach((schedule) => {
    if (invalidScheduleIds.has(schedule._id.toString())) {
      const scheduleStart = new Date(schedule.startTime);
      const hour = scheduleStart.getUTCHours();
      bookedSlots.add(`${hour.toString().padStart(2, '0')}:00`);
    }
  });

  // Generar slots disponibles (código existente)
  for (let hour = startHour; hour < endHour; hour++) {
    const slot = `${hour.toString().padStart(2, '0')}:00`;
    if (!bookedSlots.has(slot)) {
      availableSlots.push(slot);
    }
  }

  res.json({
    courtId: court._id.toString(),
    date: targetDate.toISOString().split('T')[0],
    availableSlots,
    bookedSlots: Array.from(bookedSlots),
  });
};
```

---

## 🔧 Pseudocódigo Completo del Algoritmo

### Algoritmo Principal: Validación de Disponibilidad

```
FUNCIÓN validarDisponibilidadCancha(courtId, fecha, tenantId):
  
  // Paso 1: Obtener bookings activos para la cancha
  bookings = CONSULTAR BookingModel DONDE:
    - tenantId = tenantId
    - courtId = courtId
    - status IN ['confirmed', 'pending']
    - fecha está dentro del rango del booking
  
  // Paso 2: Obtener schedules bloqueados
  schedulesBloqueados = CONSULTAR ScheduleModel DONDE:
    - tenantId = tenantId
    - courtId = courtId
    - isBlocked = true
    - startTime está en la fecha
  
  // Paso 3: Obtener schedules disponibles
  schedulesDisponibles = CONSULTAR ScheduleModel DONDE:
    - tenantId = tenantId
    - courtId = courtId
    - isAvailable = true
    - isBlocked != true
    - startTime está en la fecha
  
  // Paso 4: Extraer court_rental bookings
  courtRentalBookings = FILTRAR bookings DONDE:
    - serviceType = 'court_rental'
  
  // Paso 5: Validar cada schedule disponible contra court_rental
  slotsOcupados = SET()
  
  PARA CADA booking EN bookings:
    hora = EXTRAER_HORA(booking.bookingDate)
    slotsOcupados.AGREGAR(hora)
  
  PARA CADA schedule EN schedulesBloqueados:
    hora = EXTRAER_HORA(schedule.startTime)
    slotsOcupados.AGREGAR(hora)
  
  PARA CADA schedule EN schedulesDisponibles:
    tieneConflicto = false
    
    PARA CADA courtRental EN courtRentalBookings:
      SI schedule.courtId == courtRental.courtId:
        SI SE_SOLAPAN(schedule, courtRental):
          tieneConflicto = true
          BREAK
    
    SI tieneConflicto:
      hora = EXTRAER_HORA(schedule.startTime)
      slotsOcupados.AGREGAR(hora)
  
  // Paso 6: Generar slots disponibles
  slotsDisponibles = []
  PARA hora DESDE horaApertura HASTA horaCierre:
    slot = FORMATO_HORA(hora)
    SI slot NO ESTÁ EN slotsOcupados:
      slotsDisponibles.AGREGAR(slot)
  
  RETORNAR {
    availableSlots: slotsDisponibles,
    bookedSlots: slotsOcupados
  }

FIN FUNCIÓN

FUNCIÓN SE_SOLAPAN(schedule, booking):
  scheduleInicio = schedule.startTime
  scheduleFin = schedule.endTime
  bookingInicio = booking.bookingDate
  bookingFin = booking.endTime O (bookingInicio + 1 hora)
  
  // Dos intervalos se solapan si:
  // inicio1 < fin2 Y inicio2 < fin1
  RETORNAR (bookingInicio < scheduleFin) Y (scheduleInicio < bookingFin)

FIN FUNCIÓN
```

---

## 📊 Estructura de Datos

### ScheduleDocument
```typescript
interface ScheduleDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId;
  professorId: Types.ObjectId;
  studentId?: Types.ObjectId;        // null si está disponible
  courtId?: Types.ObjectId;          // Cancha asignada
  date: Date;
  startTime: Date;                    // Hora de inicio (UTC)
  endTime: Date;                      // Hora de fin (UTC)
  isAvailable: boolean;               // true = disponible para reserva
  isBlocked?: boolean;                // true = bloqueado manualmente
  status?: 'pending' | 'confirmed' | 'cancelled' | 'completed';
}
```

### BookingDocument
```typescript
interface BookingDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId;
  scheduleId?: Types.ObjectId;        // null para court_rental
  studentId: Types.ObjectId;
  professorId?: Types.ObjectId;       // null para court_rental
  courtId?: Types.ObjectId;           // Cancha reservada
  serviceType: 'individual_class' | 'group_class' | 'court_rental';
  price: number;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  bookingDate?: Date;                 // Para court_rental: hora de inicio
  endTime?: Date;                      // Para court_rental: hora de fin
}
```

---

## 🎯 Lógica de Solapamiento Temporal

### Reglas de Solapamiento

Dos intervalos de tiempo `[A_start, A_end]` y `[B_start, B_end]` se solapan si:

```
A_start < B_end AND B_start < A_end
```

### Casos Específicos

1. **Solapamiento Parcial Izquierdo**:
   ```
   Schedule:    [----8:00----9:00----]
   Booking:           [----8:30----9:30----]
   Resultado: CONFLICTO ✅
   ```

2. **Solapamiento Parcial Derecho**:
   ```
   Schedule:         [----8:30----9:30----]
   Booking:    [----8:00----9:00----]
   Resultado: CONFLICTO ✅
   ```

3. **Booking Contiene Schedule**:
   ```
   Schedule:         [----8:30----9:00----]
   Booking:    [----8:00----9:30----]
   Resultado: CONFLICTO ✅
   ```

4. **Schedule Contiene Booking**:
   ```
   Schedule:    [----8:00----9:30----]
   Booking:         [----8:30----9:00----]
   Resultado: CONFLICTO ✅
   ```

5. **Sin Solapamiento**:
   ```
   Schedule:    [----8:00----9:00----]
   Booking:                        [----10:00----11:00----]
   Resultado: SIN CONFLICTO ✅
   ```

6. **Adyacentes (Sin Solapamiento)**:
   ```
   Schedule:    [----8:00----9:00----]
   Booking:                        [----9:00----10:00----]
   Resultado: SIN CONFLICTO ✅ (no se solapan, son adyacentes)
   ```

---

## ⚡ Optimizaciones de Performance

### 1. Índices Necesarios

```typescript
// BookingModel - Ya existen estos índices:
BookingModel.index({ 
  tenantId: 1, 
  courtId: 1, 
  bookingDate: 1, 
  endTime: 1, 
  status: 1 
});

BookingModel.index({ 
  tenantId: 1, 
  serviceType: 1, 
  bookingDate: 1, 
  status: 1 
});

// ScheduleModel - Ya existen estos índices:
ScheduleModel.index({ 
  tenantId: 1, 
  courtId: 1, 
  isAvailable: 1 
});

ScheduleModel.index({ 
  tenantId: 1, 
  courtId: 1, 
  startTime: 1 
});
```

### 2. Estrategia de Caching

```typescript
// Cachear resultados por 30 segundos
const CACHE_TTL = 30 * 1000; // 30 segundos
const cache = new Map<string, { data: any, timestamp: number }>();

function getCachedSlots(cacheKey: string) {
  const cached = cache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }
  return null;
}

function setCachedSlots(cacheKey: string, data: any) {
  cache.set(cacheKey, { data, timestamp: Date.now() });
}

// Uso en getCourtAvailableSlots:
const cacheKey = `slots:${tenantId}:${courtId}:${date}`;
const cached = getCachedSlots(cacheKey);
if (cached) {
  return res.json(cached);
}

// ... calcular slots ...
const result = { availableSlots, bookedSlots };
setCachedSlots(cacheKey, result);
return res.json(result);
```

### 3. Query Agregada Optimizada

```typescript
/**
 * Versión ultra-optimizada usando agregación de MongoDB
 * Hace todo el filtrado en la base de datos
 */
async function getAvailableSlotsOptimized(
  tenantId: Types.ObjectId,
  courtId: Types.ObjectId,
  targetDate: Date,
  nextDay: Date
) {
  const result = await BookingModel.aggregate([
    // Paso 1: Obtener court_rental bookings activos
    {
      $match: {
        tenantId: tenantId,
        courtId: courtId,
        serviceType: 'court_rental',
        status: { $in: ['confirmed', 'pending'] },
        $or: [
          {
            bookingDate: { $lt: nextDay },
            endTime: { $gt: targetDate }
          },
          {
            endTime: { $exists: false },
            bookingDate: { $gte: targetDate, $lt: nextDay }
          }
        ]
      }
    },
    // Paso 2: Proyectar horas ocupadas
    {
      $project: {
        hour: { $hour: '$bookingDate' },
        startTime: '$bookingDate',
        endTime: { $ifNull: ['$endTime', { $add: ['$bookingDate', 3600000] }] }
      }
    }
  ]);

  // Obtener schedules disponibles y filtrar en agregación
  const availableSchedules = await ScheduleModel.aggregate([
    {
      $match: {
        tenantId: tenantId,
        courtId: courtId,
        isAvailable: true,
        $or: [{ isBlocked: { $exists: false } }, { isBlocked: false }],
        startTime: { $gte: targetDate, $lt: nextDay }
      }
    },
    {
      $lookup: {
        from: 'bookings',
        let: { scheduleStart: '$startTime', scheduleEnd: '$endTime' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$tenantId', tenantId] },
                  { $eq: ['$courtId', courtId] },
                  { $eq: ['$serviceType', 'court_rental'] },
                  { $in: ['$status', ['confirmed', 'pending']] },
                  {
                    $or: [
                      {
                        $and: [
                          { $lt: ['$bookingDate', '$$scheduleEnd'] },
                          { $gt: [{ $ifNull: ['$endTime', { $add: ['$bookingDate', 3600000] }] }, '$$scheduleStart'] }
                        ]
                      }
                    ]
                  }
                ]
              }
            }
          }
        ],
        as: 'conflicts'
      }
    },
    {
      $match: {
        conflicts: { $size: 0 } // Solo schedules sin conflictos
      }
    }
  ]);

  return availableSchedules;
}
```

---

## 🧪 Casos de Prueba Detallados

### Test Case 1: Schedule Disponible Sin Conflicto
```typescript
it('should show schedule as available when no court_rental exists', async () => {
  // Setup
  const schedule = await ScheduleModel.create({
    tenantId: tenantId,
    professorId: professorId,
    courtId: courtId,
    startTime: new Date('2026-01-28T08:00:00Z'),
    endTime: new Date('2026-01-28T09:00:00Z'),
    isAvailable: true
  });

  // Action
  const hasConflict = await scheduleValidationService.hasCourtRentalConflict(
    schedule,
    tenantId
  );

  // Assert
  expect(hasConflict).toBe(false);
});
```

### Test Case 2: Schedule Con Conflicto Por Court Rental
```typescript
it('should detect conflict when court_rental overlaps with schedule', async () => {
  // Setup
  const schedule = await ScheduleModel.create({
    tenantId: tenantId,
    professorId: professorId,
    courtId: courtId,
    startTime: new Date('2026-01-28T08:00:00Z'),
    endTime: new Date('2026-01-28T09:00:00Z'),
    isAvailable: true
  });

  await BookingModel.create({
    tenantId: tenantId,
    courtId: courtId,
    studentId: studentId,
    serviceType: 'court_rental',
    bookingDate: new Date('2026-01-28T08:30:00Z'),
    endTime: new Date('2026-01-28T09:30:00Z'),
    status: 'confirmed',
    price: 50000
  });

  // Action
  const hasConflict = await scheduleValidationService.hasCourtRentalConflict(
    schedule,
    tenantId
  );

  // Assert
  expect(hasConflict).toBe(true);
});
```

### Test Case 3: Filtrado en Batch
```typescript
it('should filter multiple schedules in batch efficiently', async () => {
  // Setup: Crear 10 schedules y 2 court_rentals
  const schedules = [];
  for (let i = 0; i < 10; i++) {
    schedules.push(await ScheduleModel.create({
      tenantId: tenantId,
      professorId: professorId,
      courtId: courtId,
      startTime: new Date(`2026-01-28T${8 + i}:00:00Z`),
      endTime: new Date(`2026-01-28T${9 + i}:00:00Z`),
      isAvailable: true
    }));
  }

  // Crear court_rentals que bloquean schedules 2 y 5
  await BookingModel.create({
    tenantId: tenantId,
    courtId: courtId,
    serviceType: 'court_rental',
    bookingDate: new Date('2026-01-28T10:00:00Z'),
    endTime: new Date('2026-01-28T11:00:00Z'),
    status: 'confirmed',
    price: 50000
  });

  // Action
  const filtered = await scheduleValidationService.filterSchedulesWithoutConflicts(
    schedules,
    tenantId
  );

  // Assert: Deben quedar 8 schedules (se excluyen los que tienen conflicto)
  expect(filtered.length).toBe(8);
  expect(filtered.find(s => s._id.toString() === schedules[2]._id.toString())).toBeUndefined();
});
```

---

## 📋 Checklist de Implementación

- [ ] Crear `ScheduleValidationService` con métodos de validación
- [ ] Agregar tests unitarios para `ScheduleValidationService`
- [ ] Modificar `getCourtAvailableSlots` para incluir validación
- [ ] Modificar `getAvailableSchedules` para filtrar conflictos
- [ ] Modificar `getProfessorSchedules` para filtrar conflictos
- [ ] Modificar `getTenantSchedules` para filtrar conflictos
- [ ] Modificar `getAllAvailableSchedules` para filtrar conflictos
- [ ] Agregar validación en `BookingService.createBooking` al crear booking desde schedule
- [ ] Agregar tests de integración para flujos completos
- [ ] Verificar índices de base de datos
- [ ] Documentar cambios en CHANGELOG
- [ ] Actualizar documentación de API
