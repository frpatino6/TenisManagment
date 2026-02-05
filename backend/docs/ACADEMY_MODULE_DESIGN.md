# Módulo de Academias - Diseño Técnico CourtFlow

**Versión:** 1.0  
**Fecha:** Febrero 2025  
**Autor:** CourtFlow Technical Team

---

## 1. Resumen Ejecutivo

Este documento define el diseño del módulo de **Academias** para CourtFlow, permitiendo a los centros deportivos gestionar programas de formación estructurados (escuelas de tenis/pádel) que difieren de las reservas puntuales de canchas y clases individuales.

**Diferencias clave con el modelo actual:**

| Concepto | Reservas Actuales | Academias |
|----------|-------------------|-----------|
| Naturaleza | Puntual (una clase, una reserva) | Programática (ciclo + grupo fijo) |
| Horario | Variable, el alumno elige slot | Fijo, asignado por grupo |
| Pago | Por sesión/por reserva | Mensualidad recurrente |
| Asistencia | Implícita (booking = asistió) | Explícita (pase de lista) |
| Recuperación | N/A | Clases de recuperación |

---

## 2. Modelo de Datos (MongoDB)

### 2.1 Diagrama de Relaciones

```
Tenant
   │
   ├── Academy (1:N) ──────────────────────────────────────┐
   │      │                                                 │
   │      ├── AcademyCycle (1:N) ──────────────────────────┤
   │      │      │                                          │
   │      │      ├── AcademyProgram (1:N) ──────────────────┤
   │      │      │      │                                    │
   │      │      │      └── AcademyGroup (1:N) ◄────────────┤
   │      │      │             │                             │
   │      │      │             ├── courtId ──► Court         │
   │      │      │             ├── professorId ──► Professor │
   │      │      │             ├── scheduleTemplate          │
   │      │      │             │                             │
   │      │      │             └── AcademyEnrollment (1:N) ◄─┤
   │      │      │                    │                      │
   │      │      │                    ├── studentId ──► Student
   │      │      │                    └── AcademyPayment (1:N)
   │      │      │                                             │
   │      │      └── AcademyBlock (1:N) ──────────────────────┘
   │      │             (bloqueos de cancha recurrentes)
   │      │
   │      └── AcademySession (1:N)
   │             (sesiones concretas para asistencia)
   │
   └── Booking (existente) ◄── Sigue funcionando para court_rental, individual_class
```

### 2.2 Colecciones y Schemas

#### 2.2.1 Academy

Define una academia dentro del tenant (puede haber varias por centro).

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "name": "Academia de Tenis Club Central",
  "description": "Escuela de formación para todas las edades",
  "isActive": true,
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

#### 2.2.2 AcademyCycle

Representa un periodo de la academia (trimestre, semestre, ciclo mensual).

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "name": "Trimestre Primavera 2025",
  "startDate": "2025-03-01T00:00:00.000Z",
  "endDate": "2025-05-31T23:59:59.999Z",
  "type": "quarterly",
  "status": "active",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campo `type`:** `"monthly"` | `"quarterly"` | `"semester"` | `"annual"`

#### 2.2.3 AcademyProgram

Niveles o programas dentro de un ciclo (Pre-tenis, Intermedio, Competición).

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "cycleId": "ObjectId",
  "name": "Pre-tenis",
  "description": "Iniciación para niños 4-8 años",
  "minAge": 4,
  "maxAge": 8,
  "maxStudentsPerGroup": 8,
  "monthlyPrice": 120000,
  "order": 1,
  "maxMakeupsPerCycle": 2,
  "coachPayPerSession": 25000,
  "paymentType": "per_session",
  "isActive": true,
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campos de gestión de nómina:**
- `coachPayPerSession` (Number): Pago por sesión al profesor cuando `paymentType: "per_session"`.
- `paymentType` (String): `"per_session"` | `"fixed"`. En `per_session` se calcula el pago multiplicando `coachPayPerSession` por las `AcademySession` con `status: "completed"`. En `fixed` se usa un monto fijo mensual configurado externamente.

**Campo de política de recuperación:**
- `maxMakeupsPerCycle` (Number): Máximo de clases de recuperación permitidas por alumno por ciclo. Configurable por centro.

#### 2.2.4 AcademyGroup

Grupo concreto con horarios fijos, cancha y profesor asignados.

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "cycleId": "ObjectId",
  "programId": "ObjectId",
  "name": "Pre-tenis Lunes-Miércoles Mañana",
  "courtId": "ObjectId",
  "professorId": "ObjectId",
  "scheduleTemplate": {
    "recurrence": "weekly",
    "slots": [
      {
        "dayOfWeek": 1,
        "startTime": "09:00",
        "endTime": "10:00",
        "durationMinutes": 60
      },
      {
        "dayOfWeek": 3,
        "startTime": "09:00",
        "endTime": "10:00",
        "durationMinutes": 60
      }
    ]
  },
  "maxCapacity": 8,
  "currentEnrollments": 6,
  "isActive": true,
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campo `dayOfWeek`:** 0 = Domingo, 1 = Lunes, ..., 6 = Sábado.

#### 2.2.5 AcademyBlock

**Bloqueos recurrentes en la cancha** para evitar que las academias generen conflictos con reservas libres. Se usa para validar disponibilidad (similar a `Schedule` bloqueado pero con patrón recurrente).

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "groupId": "ObjectId",
  "cycleId": "ObjectId",
  "courtId": "ObjectId",
  "dayOfWeek": 1,
  "startTime": "09:00",
  "endTime": "10:00",
  "effectiveFrom": "2025-03-01",
  "effectiveTo": "2025-05-31",
  "status": "active",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Nota:** Los `AcademyBlock` se materializan o se consultan dinámicamente para verificar conflictos con `Booking` (court_rental) y `Schedule`.

#### 2.2.6 AcademyEnrollment

Inscripción de un alumno en un grupo.

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "cycleId": "ObjectId",
  "groupId": "ObjectId",
  "studentId": "ObjectId",
  "status": "active",
  "enrolledAt": "2025-02-15T00:00:00.000Z",
  "droppedAt": null,
  "notes": "",
  "firstMonthProratedAmount": 80000,
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campo `status`:** `"active"` | `"dropped"` | `"completed"` | `"suspended"` | `"waiting"`

**Campo `firstMonthProratedAmount` (Number, opcional):** Monto prorrateado para inscripciones que inician a mitad de mes. Si `enrolledAt` cae en el día 15, el primer `AcademyPayment` usa este valor en lugar de `monthlyPrice`. Si es `null` o no existe, se cobra el precio mensual completo.

#### 2.2.6b AcademyWaitlist (opcional)

Colección dedicada para **lista de espera** cuando el grupo alcanza `maxCapacity`. Alternativa: usar `AcademyEnrollment` con `status: "waiting"` si no se requiere historial de posiciones.

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "groupId": "ObjectId",
  "cycleId": "ObjectId",
  "studentId": "ObjectId",
  "position": 1,
  "requestedAt": "2025-02-20T10:00:00.000Z",
  "status": "waiting",
  "notifiedAt": null,
  "expiresAt": "2025-03-05T23:59:59.000Z",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campo `status`:** `"waiting"` | `"converted"` | `"expired"` | `"cancelled"`  
**Campo `position`:** Orden en la cola (1 = primero en salir cuando haya cupo).  
**Campo `expiresAt`:** Si el alumno no responde a la notificación de cupo, la posición expira.

**Enfoque simplificado:** Si no se usa `AcademyWaitlist`, crear `AcademyEnrollment` con `status: "waiting"` cuando no hay cupos. Al dar de baja un alumno activo, el primero en `waiting` pasa a `active` (o se le notifica para completar pago).

#### 2.2.7 AcademySession

Sesión concreta de clase para control de asistencia y recuperaciones.

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "academyId": "ObjectId",
  "groupId": "ObjectId",
  "courtId": "ObjectId",
  "professorId": "ObjectId",
  "scheduledDate": "2025-03-03",
  "startTime": "2025-03-03T09:00:00.000Z",
  "endTime": "2025-03-03T10:00:00.000Z",
  "type": "regular",
  "status": "scheduled",
  "attendance": [
    {
      "studentId": "ObjectId",
      "status": "present",
      "markedAt": "2025-03-03T09:05:00.000Z",
      "markedBy": "ObjectId"
    }
  ],
  "cancellationReason": null,
  "makeupSessionId": null,
  "coachNotes": "Excelente avance en el golpe de revés. Trabajar saque en próxima sesión.",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campos `type`:** `"regular"` | `"makeup"` (recuperación)  
**Campos `status`:** `"scheduled"` | `"completed"` | `"cancelled"` | `"rescheduled"`  
**Campos `attendance[].status`:** `"present"` | `"absent"` | `"excused"` | `"late"`

**Campo `coachNotes` (String, opcional):** Comentarios pedagógicos del profesor sobre el progreso del grupo o aspectos a trabajar. Visibles para el alumno en la pantalla "Mi Academia" en Flutter.

#### 2.2.8 AcademyPayment

Pagos de mensualidad (extiende o complementa el modelo `Payment` existente).

```json
{
  "_id": "ObjectId",
  "tenantId": "ObjectId",
  "enrollmentId": "ObjectId",
  "studentId": "ObjectId",
  "groupId": "ObjectId",
  "cycleId": "ObjectId",
  "amount": 120000,
  "periodStart": "2025-03-01",
  "periodEnd": "2025-03-31",
  "dueDate": "2025-03-05",
  "paidAt": "2025-03-02T14:30:00.000Z",
  "status": "paid",
  "method": "card",
  "externalReference": "wompi_trx_xxx",
  "isOnline": true,
  "concept": "Mensualidad Marzo - Pre-tenis",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

**Campo `status`:** `"pending"` | `"paid"` | `"overdue"` | `"cancelled"` | `"refunded"`  
**Relación con Payment:** Se recomienda crear también un `Payment` con `bookingId: null` y `description` que referencie el `enrollmentId` para mantener consistencia con el saldo del `StudentTenant`.

---

### 2.3 Índices Recomendados

```javascript
// Academy
db.academies.createIndex({ tenantId: 1, isActive: 1 });

// AcademyCycle
db.academycycles.createIndex({ tenantId: 1, academyId: 1, status: 1 });
db.academycycles.createIndex({ startDate: 1, endDate: 1 });

// AcademyProgram
db.academyprograms.createIndex({ tenantId: 1, cycleId: 1, isActive: 1 });

// AcademyGroup
db.academygroups.createIndex({ tenantId: 1, cycleId: 1, isActive: 1 });
db.academygroups.createIndex({ professorId: 1, cycleId: 1 });
db.academygroups.createIndex({ courtId: 1, cycleId: 1 });

// AcademyBlock
db.academyblocks.createIndex({ tenantId: 1, courtId: 1, dayOfWeek: 1, effectiveFrom: 1, effectiveTo: 1 });
db.academyblocks.createIndex({ groupId: 1, cycleId: 1 });

// AcademyEnrollment
db.academyenrollments.createIndex({ tenantId: 1, studentId: 1, status: 1 });
db.academyenrollments.createIndex({ groupId: 1, status: 1 });
db.academyenrollments.createIndex({ cycleId: 1, status: 1 });

// AcademyWaitlist (si se usa)
db.academywaitlists.createIndex({ groupId: 1, status: 1, position: 1 });
db.academywaitlists.createIndex({ studentId: 1, status: 1 });

// AcademySession
db.academysessions.createIndex({ tenantId: 1, groupId: 1, scheduledDate: 1 });
db.academysessions.createIndex({ professorId: 1, scheduledDate: 1 });
db.academysessions.createIndex({ courtId: 1, startTime: 1, endTime: 1 });

// AcademyPayment
db.academypayments.createIndex({ tenantId: 1, enrollmentId: 1, periodStart: 1 });
db.academypayments.createIndex({ studentId: 1, status: 1 });
db.academypayments.createIndex({ dueDate: 1, status: 1 });
```

---

## 3. Lógica de Negocio y Pagos

### 3.1 Pagos Recurrentes vs. Únicos

| Escenario | Estrategia |
|-----------|------------|
| **Mensualidad estándar** | Crear `AcademyPayment` con `periodStart`/`periodEnd` mensual. Cobro manual o automático (cron) según `dueDate`. |
| **Pago único por ciclo** | Un solo `AcademyPayment` con `periodStart` = inicio ciclo, `periodEnd` = fin ciclo. |
| **Integración con wallet** | Al pagar mensualidad: crear `Payment` (method: card/wallet), descontar `StudentTenant.balance` si aplica, vincular `AcademyPayment` con `externalReference`. |

**Recomendación:** Mantener `AcademyPayment` como entidad separada para reportes de academia, y crear `Payment` cuando el pago se efectúe para consistencia con el modelo actual de saldo.

```typescript
// Pseudocódigo: Cobro de mensualidad
async function processMonthlyPayment(enrollmentId: ObjectId, period: { start: Date, end: Date }) {
  const enrollment = await AcademyEnrollment.findById(enrollmentId).populate('groupId');
  const program = await AcademyProgram.findById(enrollment.groupId.programId);
  const amount = program.monthlyPrice;

  // 1. Procesar pago (Wompi o wallet)
  const paymentResult = await processPayment(studentId, amount, { enrollmentId, period });

  // 2. Crear AcademyPayment
  await AcademyPayment.create({
    enrollmentId,
    studentId: enrollment.studentId,
    amount,
    periodStart: period.start,
    periodEnd: period.end,
    status: 'paid',
    paidAt: new Date(),
    externalReference: paymentResult.reference,
  });

  // 3. (Opcional) Crear Payment para auditoría/saldo
  await PaymentModel.create({
    tenantId, studentId, amount, date: new Date(),
    status: 'paid', method: 'card', isOnline: true,
    description: `Mensualidad academia: ${period.start} - ${period.end}`,
  });
}
```

### 3.2 Control de Asistencia (Pase de Lista)

**Flujo:**

1. El profesor accede a la vista de sesiones del día (o de la semana).
2. Se listan las `AcademySession` del grupo con `scheduledDate` = hoy.
3. Para cada sesión, se muestra la lista de alumnos inscritos (`AcademyEnrollment` del grupo).
4. El profesor marca: presente / ausente / excusado / tarde.
5. Se actualiza `AcademySession.attendance`.

**Endpoint propuesto:** `PATCH /api/academy/sessions/:sessionId/attendance`

**Payload:**
```json
{
  "attendance": [
    { "studentId": "ObjectId", "status": "present" },
    { "studentId": "ObjectId", "status": "absent" }
  ]
}
```

**Vista profesor (Flutter):** Ver sección 4.3 para el flujo de UI basado en gestos (swipe).

### 3.3 Recuperación de Clases

**Casos:**
- **Alumno falta:** Puede tener derecho a X recuperaciones por ciclo (ej: 2).
- **Clase cancelada (lluvia, etc.):** Todos los alumnos del grupo tienen derecho a recuperación.

**Modelo de recuperación:**

1. `AcademySession` cancelada: `status: "cancelled"`, `cancellationReason: "rain"`.
2. Se crea `AcademySession` de tipo `"makeup"` con `scheduledDate` y horario acordado.
3. Se enlaza: `originalSession.makeupSessionId = makeupSession._id`.
4. Contador de recuperaciones por alumno: consulta `AcademySession` con `attendance.status: "absent"` + sesiones de tipo `makeup` usadas.

**Lógica sugerida:**
- Usar `AcademyProgram.maxMakeupsPerCycle` para limitar recuperaciones por alumno.
- Al crear sesión makeup: validar que el alumno no haya excedido su cupo consultando sesiones makeup previas.
- Validar que el slot esté libre (court + profesor) usando `BookingService.isCourtAvailable` y validando contra `AcademyBlock` de otros grupos.

### 3.4 Lista de Espera

**Escenario:** Grupo con `currentEnrollments >= maxCapacity`. Un alumno solicita inscribirse.

**Opciones de implementación:**

| Enfoque | Pros | Contras |
|---------|------|---------|
| `AcademyEnrollment` con `status: "waiting"` | Simple, una sola colección | Sin orden explícito; requiere `requestedAt` para ordenar |
| `AcademyWaitlist` dedicada | Posición en cola, historial, notificaciones | Más colecciones y lógica |

**Flujo con status waiting:**
1. Alumno solicita inscribirse → Crear `AcademyEnrollment` con `status: "waiting"`.
2. Admin o sistema ordena por `requestedAt` (FIFO).
3. Cuando un alumno activo se da de baja → El primer `waiting` pasa a `pending` o se le notifica para completar pago y pasar a `active`.

**Flujo con AcademyWaitlist:**
1. Alumno solicita → Crear `AcademyWaitlist` con `position` calculado.
2. Cupo disponible → Notificar al `position: 1`, dar tiempo (ej: 48h) para confirmar.
3. Si confirma → Crear `AcademyEnrollment` activo, eliminar de waitlist, actualizar posiciones.
4. Si no confirma → `status: "expired"`, notificar al siguiente.

### 3.5 Automatización de Notificaciones (FCM)

Cuando una `AcademySession` cambia a `status: "cancelled"` (ej: lluvia):

```
┌─────────────────────────────────────────────────────────────────┐
│ AcademySession.status = "cancelled"                              │
│ (PATCH /api/academy/sessions/:id con body: { status: "cancelled",│
│  cancellationReason: "rain" })                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ AcademySessionService (o Controller) emite evento:               │
│   event: "academy.session.cancelled"                             │
│   payload: { sessionId, groupId, scheduledDate, reason }         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ NotificationService / Event Handler:                             │
│   1. Obtener enrollments activos del groupId                     │
│   2. Obtener FCM tokens de cada studentId (AuthUser)             │
│   3. Enviar push vía Firebase Admin SDK                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Alumno recibe: "Clase cancelada (lluvia). Fecha: 03/03.         │
│ Recuperación disponible."                                        │
└─────────────────────────────────────────────────────────────────┘
```

**Implementación recomendada:**
- **Pub/Sub:** Emitir evento `academy.session.cancelled` (EventEmitter, Bull/BullMQ, o PubSub de GCP).
- **Handler:** Suscriptor que llama a `NotificationService.sendAcademySessionCancelled(session, studentIds)`.
- **FCM:** Usar `firebase-admin` para enviar mensajes a tokens. Tema opcional: `academy_{groupId}` para suscripción grupal.

### 3.6 Prorrateo del Primer Mes

Al crear el primer `AcademyPayment` para un enrollment:

```typescript
function calculateFirstMonthAmount(
  enrollment: AcademyEnrollment,
  program: AcademyProgram,
  cycle: AcademyCycle
): number {
  if (enrollment.firstMonthProratedAmount != null) {
    return enrollment.firstMonthProratedAmount;
  }
  const enrolledDay = getDayOfMonth(enrollment.enrolledAt);
  const totalDays = getDaysInMonth(enrollment.enrolledAt);
  const remainingDays = totalDays - enrolledDay + 1;
  return Math.round((program.monthlyPrice * remainingDays) / totalDays);
}
```

---

## 4. Experiencia de Usuario (Flutter)

### 4.1 Flujo Administrador del Centro

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Crear Academia                                                │
│    - Nombre, descripción                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Crear Ciclo                                                   │
│    - Nombre (ej: Trimestre Primavera)                            │
│    - Fechas inicio/fin                                           │
│    - Tipo (mensual, trimestral, semestral)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Crear Programas/Niveles                                       │
│    - Pre-tenis, Intermedio, Competición                          │
│    - Precio mensual, cupos máximos, rangos de edad               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Crear Grupos y Horarios                                       │
│    - Asignar programa                                            │
│    - Seleccionar cancha                                          │
│    - Asignar profesor                                            │
│    - Definir días y horas (ej: Lunes 9-10, Miércoles 9-10)       │
│    - Sistema crea AcademyBlock automáticamente                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Gestión de Inscripciones                                      │
│    - Listar alumnos por grupo                                    │
│    - Aprobar/Rechazar solicitudes                                │
│    - Dar de baja                                                │
└─────────────────────────────────────────────────────────────────┘
```

**Pantallas Flutter sugeridas:**
- `AcademyListScreen` → Lista de academias del tenant
- `AcademyDetailScreen` → Ciclos, programas, grupos
- `AcademyGroupFormScreen` → Crear/editar grupo con asignación cancha/profesor/horario
- `AcademyEnrollmentsScreen` → Inscritos por grupo
- `AcademyPaymentsScreen` → Estado de mensualidades

### 4.2 Flujo Alumno

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Explorar Academias                                            │
│    - Ver academias activas del centro                            │
│    - Ver programas, horarios, precios                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Inscripción                                                   │
│    - Seleccionar grupo con cupos disponibles                     │
│    - Solicitar inscripción (crea Enrollment en pending si aplica)│
│    - Pagar primera mensualidad                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Mi Academia                                                   │
│    - Ver mis grupos y horarios                                   │
│    - Calendario de próximas clases                               │
│    - Historial de asistencia                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Pagos                                                        │
│    - Próxima mensualidad: fecha y monto                          │
│    - Botón "Pagar ahora" (Wompi)                                 │
│    - Historial de pagos                                          │
└─────────────────────────────────────────────────────────────────┘
```

**Pantallas Flutter sugeridas:**
- `AcademyCatalogScreen` → Programas y grupos disponibles
- `AcademyEnrollmentScreen` → Inscribirse a un grupo
- `MyAcademyScreen` → Mis grupos, próximas clases, asistencia, coachNotes
- `AcademyPaymentScreen` → Estado de pagos y botón de pago

### 4.3 Pase de Lista Ágil (Profesor) — UX con Gestos

Optimizado para uso en cancha con **una sola mano**, minimizando taps y permitiendo marcar asistencia rápidamente.

**Patrón de gestos propuesto:**

| Gesto | Acción |
|-------|--------|
| **Swipe right** sobre alumno | Marcar como **presente** |
| **Swipe left** sobre alumno | Marcar como **ausente** |
| **Tap largo** | Abrir menú: excusado / tarde |
| **Doble tap** | Deshacer último cambio de ese alumno |

**Layout recomendado:**

```
┌─────────────────────────────────────────────────┐
│ Sesión: Pre-tenis · Lun 09:00-10:00 · Cancha 1  │
├─────────────────────────────────────────────────┤
│ [✓] María García      ← swipe right = presente  │
│ [✗] Juan Pérez        ← swipe left = ausente    │
│ [~] Ana López         ← tap largo = menú        │
│ [ ] Carlos Ruiz       ← pendiente de marcar     │
│ ...                                              │
├─────────────────────────────────────────────────┤
│ [ Guardar ]  5/8 presentes · 2 ausentes         │
└─────────────────────────────────────────────────┘
```

**Componentes Flutter sugeridos:**
- `Dismissible` o `Slidable` para swipe right/left con feedback visual (color verde/rojo).
- `LongPressGestureDetector` para menú contextual.
- Estado local que acumula cambios y sincroniza con `PATCH /api/academy/sessions/:id/attendance` al "Guardar" o con debounce automático.
- Indicador de estado sin conexión si se usa en cancha con wifi limitado (modo offline-first opcional).

**Accesibilidad:** Asegurar targets táctiles mínimos de 48x48 dp y contraste suficiente para uso bajo sol.

---

## 5. Integración con el Calendario Actual

### 5.1 Convivencia: Canchas Libres vs. Bloques de Academia

El sistema actual utiliza:
- **Bookings** (`court_rental`, `individual_class`, `group_class`) para ocupación real.
- **Schedules** para slots de profesor (clases individuales/grupales).
- **ScheduleValidationService** para filtrar schedules que chocan con `court_rental`.

**Propuesta:** Los bloques de academia **NO** crean `Booking` por cada sesión. En su lugar:

1. **AcademyBlock** define el patrón recurrente (día, hora, cancha).
2. Al consultar disponibilidad para **court_rental** o **schedule**, se valida contra:
   - Bookings existentes
   - Schedules ocupados/bloqueados
   - **AcademyBlocks** activos en el rango de fechas del ciclo

### 5.2 Algoritmo de Validación de Conflictos (Extensión)

```typescript
// ScheduleValidationService (extender)
async hasAcademyBlockConflict(
  courtId: ObjectId,
  startTime: Date,
  endTime: Date,
  tenantId: ObjectId,
  excludeGroupId?: ObjectId
): Promise<boolean> {
  const dayOfWeek = startTime.getDay(); // 0-6
  const startStr = formatTime(startTime); // "09:00"
  const endStr = formatTime(endTime);
  const date = startTime;

  const conflict = await AcademyBlockModel.findOne({
    tenantId,
    courtId,
    dayOfWeek,
    status: 'active',
    effectiveFrom: { $lte: date },
    effectiveTo: { $gte: date },
    $or: [
      { startTime: { $lt: endStr }, endTime: { $gt: startStr } }
    ],
    ...(excludeGroupId && { groupId: { $ne: excludeGroupId } })
  });

  return !!conflict;
}
```

### 5.3 Modificaciones a BookingService

En `BookingService.isCourtAvailable`:

1. Verificar conflictos con **Bookings** (existente).
2. Verificar conflictos con **Schedules** (existente).
3. **Nuevo:** Verificar conflictos con **AcademyBlocks** en el rango de fechas.

Así, cuando un usuario intente reservar una cancha (court_rental) en Lunes 9-10, si existe un `AcademyBlock` para ese slot, la cancha aparecerá como no disponible.

### 5.4 Visualización en Calendario

- **Vista Admin/Profesor:** Mostrar bloques de academia como eventos bloqueados (por ejemplo, color distinto).
- **Vista Estudiante (reservar cancha):** Los slots ocupados por academia no deben mostrarse como disponibles.
- **AcademySession:** Se pueden materializar como eventos en el calendario del profesor para el "pase de lista" (sin crear Booking).

### 5.5 Advertencia de Performance: Estrategia de Caching para AcademyBlock

La consulta de `AcademyBlock` en cada validación de disponibilidad puede aumentar la latencia en horas pico (muchas reservas simultáneas). Se recomienda:

#### Opción A: Cache en Memoria (Node.js)

- **TTL:** 60-120 segundos.
- **Clave:** `academy_blocks:${tenantId}:${courtId}:${dayOfWeek}`.
- **Invalidación:** Al crear/actualizar/eliminar `AcademyBlock`, invalidar las claves afectadas.

```typescript
// Pseudocódigo
const cacheKey = `academy_blocks:${tenantId}:${courtId}:${dayOfWeek}`;
let blocks = await cache.get(cacheKey);
if (!blocks) {
  blocks = await AcademyBlockModel.find({ tenantId, courtId, dayOfWeek, status: 'active' }).lean();
  await cache.set(cacheKey, blocks, { ttl: 90 }); // 90 segundos
}
return blocks;
```

#### Opción B: Proyección y Índice Compuesto

- Usar proyección mínima: `{ _id: 1, startTime: 1, endTime: 1, effectiveFrom: 1, effectiveTo: 1 }`.
- Índice: `{ tenantId: 1, courtId: 1, dayOfWeek: 1, status: 1, effectiveFrom: 1, effectiveTo: 1 }`.
- Evitar `populate` y devolver solo campos necesarios.

#### Opción C: Materialización de Bloques por Fecha

- Pre-calcular, en un job nocturno, los slots bloqueados por fecha para las próximas 2-4 semanas.
- Colección `AcademyBlockByDate` con `{ tenantId, courtId, date, startTime, endTime }`.
- La validación de disponibilidad consulta esta colección en lugar de calcular desde `AcademyBlock` recurrentes.
- Trade-off: más almacenamiento, menor CPU en tiempo real.

#### Recomendación

- **Fase 1:** Opción B (proyección + índice) sin cache.
- **Fase 2:** Si métricas muestran picos de latencia > 200ms, añadir Opción A con Redis o cache en memoria (node-cache).

---

## 6. Endpoints Necesarios

### 6.1 CRUD Básico

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/tenant/:tenantId/academies` | Listar academias |
| POST | `/api/tenant/:tenantId/academies` | Crear academia |
| GET | `/api/academies/:academyId` | Detalle academia |
| PATCH | `/api/academies/:academyId` | Actualizar academia |
| GET | `/api/academies/:academyId/cycles` | Listar ciclos |
| POST | `/api/academies/:academyId/cycles` | Crear ciclo |
| GET | `/api/cycles/:cycleId/programs` | Listar programas |
| POST | `/api/cycles/:cycleId/programs` | Crear programa |
| GET | `/api/programs/:programId/groups` | Listar grupos |
| POST | `/api/programs/:programId/groups` | Crear grupo |
| PATCH | `/api/academy/groups/:groupId` | Actualizar grupo |

### 6.2 Inscripciones y Pagos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/academy/groups/:groupId/enroll` | Inscribir alumno |
| DELETE | `/api/academy/enrollments/:enrollmentId` | Dar de baja |
| GET | `/api/academy/enrollments/:enrollmentId/payments` | Pagos del enrollment |
| POST | `/api/academy/enrollments/:enrollmentId/pay` | Procesar pago mensualidad |
| GET | `/api/students/me/academy-enrollments` | Mis inscripciones (alumno) |

### 6.3 Sesiones y Asistencia

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/academy/groups/:groupId/sessions` | Sesiones del grupo (filtro por fechas) |
| POST | `/api/academy/sessions` | Crear sesión (manual o generación automática) |
| PATCH | `/api/academy/sessions/:sessionId/attendance` | Registrar asistencia |
| POST | `/api/academy/sessions/:sessionId/cancel` | Cancelar sesión (lluvia, etc.) |
| POST | `/api/academy/sessions/:sessionId/makeup` | Crear sesión de recuperación |
| GET | `/api/professors/me/academy-sessions` | Mis sesiones de academia (profesor) |

### 6.4 Consultas Públicas / Catálogo

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/tenant/:tenantId/academy-catalog` | Catálogo: programas y grupos con cupos |

---

## 7. Diagrama de Flujo: Proceso de Inscripción

```
                    ┌──────────────────────┐
                    │   Alumno explora     │
                    │   catálogo de        │
                    │   academias          │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Selecciona grupo     │
                    │ con cupos            │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ ¿Requiere aprobación │
                    │ del centro?          │
                    └──────────┬───────────┘
                         │     │
                    Sí   │     │  No
                         ▼     ▼
              ┌─────────────┐  ┌─────────────────────┐
              │ Enrollment  │  │ Enrollment          │
              │ status:     │  │ status: active      │
              │ pending     │  │ + Pagar 1ra         │
              └──────┬──────┘  │   mensualidad       │
                     │         └──────────┬──────────┘
                     │                    │
                     ▼                    │
              ┌──────────────┐            │
              │ Admin aprueba│            │
              └──────┬───────┘            │
                     │                    │
                     └────────┬───────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │ Crear AcademyBlock   │
                    │ (si no existe)       │
                    │ Bloquear cancha      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Generar AcademySess- │
                    │ ions para el ciclo   │
                    │ (opcional: on-demand)│
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Alumno ve "Mi        │
                    │ Academia" con        │
                    │ próximas clases      │
                    └──────────────────────┘
```

---

## 8. Resumen de Archivos a Crear (Backend)

| Archivo | Descripción |
|---------|-------------|
| `AcademyModel.ts` | Schema Academy |
| `AcademyCycleModel.ts` | Schema AcademyCycle |
| `AcademyProgramModel.ts` | Schema AcademyProgram |
| `AcademyGroupModel.ts` | Schema AcademyGroup |
| `AcademyBlockModel.ts` | Schema AcademyBlock |
| `AcademyEnrollmentModel.ts` | Schema AcademyEnrollment |
| `AcademySessionModel.ts` | Schema AcademySession |
| `AcademyPaymentModel.ts` | Schema AcademyPayment |
| `AcademyWaitlistModel.ts` | Schema AcademyWaitlist (opcional) |
| `AcademyController.ts` | CRUD academias, ciclos, programas, grupos |
| `AcademyEnrollmentController.ts` | Inscripciones |
| `AcademySessionController.ts` | Sesiones y asistencia |
| `AcademyPaymentController.ts` | Pagos de mensualidad |
| `AcademyService.ts` | Lógica de negocio |
| `AcademyBlockConflictService.ts` | Validación Booking vs AcademyBlock (ver sección 10) |
| Extensión `ScheduleValidationService` | Validación contra AcademyBlock |
| Extensión `BookingService` | Usar AcademyBlockConflictService en isCourtAvailable |
| Rutas: `academy.ts` | Montar en `/api/academy` |

---

## 9. Próximos Pasos

1. Validar esquemas con stakeholders y ajustar campos si es necesario.
2. Crear migración para colecciones (o implementar en verde).
3. Implementar modelos y repositorios.
4. Implementar `AcademyBlockConflictService` (ver sección 10).
5. Extender `BookingService` para usar AcademyBlockConflictService en `isCourtAvailable`.
6. Implementar servicios y controladores.
7. Desarrollar pantallas Flutter según flujos descritos (incl. pase de lista con gestos).
8. Integrar pagos con Wompi para mensualidades.
9. Implementar flujo de notificaciones FCM para sesiones canceladas.
10. Pruebas E2E de inscripción, asistencia y conflictos de calendario.

---

## 10. AcademyBlockConflictService (Código de Referencia)

Middleware/Service en Node.js que valida conflictos entre un nuevo `Booking` (reserva de cancha) y los `AcademyBlock` existentes. Se invoca desde `BookingService.isCourtAvailable` antes de permitir una reserva.

**Ubicación:** `src/application/services/AcademyBlockConflictService.ts`

```typescript
import { Types } from 'mongoose';

/**
 * Service to validate conflicts between court rentals (Booking) and Academy blocks.
 * Academy blocks represent recurring weekly slots reserved for academy groups.
 * Used by BookingService before allowing a court_rental booking.
 */

export interface AcademyBlockDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId;
  courtId: Types.ObjectId;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  effectiveFrom: Date;
  effectiveTo: Date;
  status: string;
}

export interface ConflictCheckParams {
  tenantId: Types.ObjectId;
  courtId: Types.ObjectId;
  startTime: Date;
  endTime: Date;
}

function formatTimeToHHMM(date: Date): string {
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}

function timeToMinutes(timeStr: string): number {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

function timesOverlap(
  startA: string,
  endA: string,
  startB: string,
  endB: string
): boolean {
  const aStart = timeToMinutes(startA);
  const aEnd = timeToMinutes(endA);
  const bStart = timeToMinutes(startB);
  const bEnd = timeToMinutes(endB);
  return aStart < bEnd && aEnd > bStart;
}

export class AcademyBlockConflictService {
  /**
   * Checks if a requested booking time slot conflicts with any active AcademyBlock.
   * @returns true if there IS a conflict (court not available for academy)
   */
  async hasConflict(params: ConflictCheckParams): Promise<boolean> {
    const { tenantId, courtId, startTime, endTime } = params;

    const dayOfWeek = startTime.getDay();
    const requestStartStr = formatTimeToHHMM(startTime);
    const requestEndStr = formatTimeToHHMM(endTime);
    const requestDate = new Date(startTime);
    requestDate.setHours(0, 0, 0, 0);

    const AcademyBlockModel = (await import('../../infrastructure/database/models/AcademyBlockModel')).AcademyBlockModel;

    const conflictingBlock = await AcademyBlockModel.findOne(
      {
        tenantId,
        courtId,
        dayOfWeek,
        status: 'active',
        effectiveFrom: { $lte: requestDate },
        effectiveTo: { $gte: requestDate },
        $or: [
          {
            startTime: { $lt: requestEndStr },
            endTime: { $gt: requestStartStr },
          },
        ],
      },
      { _id: 1 }
    ).lean();

    return !!conflictingBlock;
  }

  /**
   * Batch check: returns map of slot index -> hasConflict for multiple slots.
   * Optimized for availability queries (e.g. getCourtAvailableSlots).
   */
  async checkConflictsBatch(
    tenantId: Types.ObjectId,
    slots: Array<{ courtId: Types.ObjectId; startTime: Date; endTime: Date }>
  ): Promise<Map<number, boolean>> {
    const result = new Map<number, boolean>();
    slots.forEach((_, i) => result.set(i, false));

    if (slots.length === 0) return result;

    const courtIds = [...new Set(slots.map((s) => s.courtId.toString()))];
    const minDate = new Date(Math.min(...slots.map((s) => s.startTime.getTime())));
    const maxDate = new Date(Math.max(...slots.map((s) => s.endTime.getTime())));
    minDate.setHours(0, 0, 0, 0);
    maxDate.setHours(23, 59, 59, 999);

    const AcademyBlockModel = (await import('../../infrastructure/database/models/AcademyBlockModel')).AcademyBlockModel;

    const blocks = await AcademyBlockModel.find(
      {
        tenantId,
        courtId: { $in: courtIds.map((id) => new Types.ObjectId(id)) },
        status: 'active',
        effectiveFrom: { $lte: maxDate },
        effectiveTo: { $gte: minDate },
      },
      { courtId: 1, dayOfWeek: 1, startTime: 1, endTime: 1, effectiveFrom: 1, effectiveTo: 1 }
    ).lean();

    slots.forEach((slot, index) => {
      const dayOfWeek = slot.startTime.getDay();
      const startStr = formatTimeToHHMM(slot.startTime);
      const endStr = formatTimeToHHMM(slot.endTime);
      const slotDate = new Date(slot.startTime);
      slotDate.setHours(0, 0, 0, 0);

      const hasConflict = blocks.some((block) => {
        if (block.courtId.toString() !== slot.courtId.toString()) return false;
        if (block.dayOfWeek !== dayOfWeek) return false;
        if (slotDate < block.effectiveFrom || slotDate > block.effectiveTo) return false;
        return timesOverlap(block.startTime, block.endTime, startStr, endStr);
      });

      result.set(index, hasConflict);
    });

    return result;
  }
}
```

**Integración en BookingService.isCourtAvailable:**

```typescript
// Después de verificar Bookings y Schedules, añadir:

const academyBlockService = new AcademyBlockConflictService();
const hasAcademyConflict = await academyBlockService.hasConflict({
  tenantId,
  courtId,
  startTime,
  endTime,
});

if (hasAcademyConflict) {
  logger.info('Court conflict found in AcademyBlock', {
    courtId: courtId.toString(),
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString(),
  });
  return false;
}
```

**Nota:** El modelo `AcademyBlockModel` debe existir. Si aún no se ha creado, el `import` dinámico fallará; en ese caso usar import estático una vez creado el modelo.
