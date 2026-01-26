# Análisis Completo: Payments Duplicados

## Resumen Ejecutivo

Este documento analiza TODOS los escenarios posibles donde se pueden crear payments duplicados en el sistema.

## Flujos de Creación de Payments

### 1. BookingService.createBooking()
**Ubicación**: `backend/src/application/services/BookingService.ts:256`

**Condiciones para crear payment 'wallet'**:
- `wasPaidWithBalance === true` (balance >= price)
- `enableOnlinePayments === true`
- `paymentAlreadyProcessed !== true`
- `!existingPayment` (no existe payment con `bookingId` y `status='paid'`)

**Problema**: Solo verifica si existe un payment con `status='paid'`, pero NO verifica si existe un payment 'card' con `externalReference`.

### 2. PaymentController.wompiWebhook()
**Ubicación**: `backend/src/application/controllers/PaymentController.ts:178`

**Flujos**:
- **Con bookingInfo**: Busca booking existente, elimina wallet si existe, crea card
- **Sin bookingInfo**: Busca booking reciente (últimos 10 min), elimina wallet si existe, crea card

**Problema**: La búsqueda de booking reciente solo busca por `price` y `createdAt`, pero NO verifica que el booking esté relacionado con la transacción.

### 3. PaymentController.getTransactionStatus()
**Ubicación**: `backend/src/application/controllers/PaymentController.ts:480`

**Misma lógica que wompiWebhook**

### 4. StudentDashboardController.bookLesson() / bookCourt()
**Ubicación**: `backend/src/application/controllers/StudentDashboardController.ts:805, 1049`

**Flujo**: Llama a `BookingService.createBooking()` sin `paymentAlreadyProcessed`

**Problema**: Si el estudiante tiene balance suficiente, crea payment 'wallet' automáticamente.

## Escenarios de Duplicación

### ESCENARIO 1: Booking creado ANTES del pago Wompi (con bookingInfo)
**Flujo**:
1. Usuario crea booking desde móvil → `BookingService.createBooking()` → crea payment 'wallet'
2. Usuario paga con Wompi → `initPayment` con `bookingInfo` → crea Transaction
3. Webhook llega → encuentra booking existente → elimina wallet → crea card ✅

**Estado**: CORREGIDO

### ESCENARIO 2: Booking creado ANTES del pago Wompi (SIN bookingInfo)
**Flujo**:
1. Usuario crea booking desde móvil → `BookingService.createBooking()` → crea payment 'wallet'
2. Usuario paga con Wompi → `initPayment` SIN `bookingInfo` → crea Transaction sin bookingInfo
3. Webhook llega → NO tiene bookingInfo → busca booking reciente por `price` y `createdAt` → elimina wallet → crea card ✅

**Estado**: CORREGIDO (pero frágil - depende de matching por precio)

### ESCENARIO 3: Pago Wompi ANTES del booking (con bookingInfo)
**Flujo**:
1. Usuario paga con Wompi → `initPayment` con `bookingInfo` → crea Transaction
2. Webhook llega → NO encuentra booking → crea booking con `paymentAlreadyProcessed=true` → crea card ✅

**Estado**: CORREGIDO

### ESCENARIO 4: Pago Wompi ANTES del booking (SIN bookingInfo)
**Flujo**:
1. Usuario paga con Wompi → `initPayment` SIN `bookingInfo` → crea Transaction sin bookingInfo
2. Webhook llega → NO tiene bookingInfo → busca booking reciente → NO encuentra (booking aún no existe) → crea payment como "Recarga de Saldo" (sin bookingId)
3. Usuario crea booking desde móvil → `BookingService.createBooking()` → busca payment reciente sin bookingId → lo vincula al booking ✅

**Estado**: **CORREGIDO** - BookingService ahora busca y vincula payments recientes sin bookingId

### ESCENARIO 5: Webhook llega DOS veces (duplicado)
**Flujo**:
1. Webhook llega primera vez → crea payment 'card'
2. Webhook llega segunda vez → verifica `existingPayment` por `externalReference` → NO crea duplicado ✅

**Estado**: CORREGIDO

### ESCENARIO 6: getTransactionStatus llamado después del webhook
**Flujo**:
1. Webhook llega → crea payment 'card'
2. Frontend llama `getTransactionStatus` → verifica `existingPayment` por `externalReference` → NO crea duplicado ✅

**Estado**: CORREGIDO

### ESCENARIO 7: Booking creado DESPUÉS del webhook (con bookingInfo pero booking no existe aún)
**Flujo**:
1. Usuario paga con Wompi → `initPayment` con `bookingInfo` → crea Transaction
2. Webhook llega → NO encuentra booking → crea booking con `paymentAlreadyProcessed=true` → crea card ✅
3. Usuario intenta crear booking desde móvil → falla por conflicto o crea duplicado

**Estado**: PARCIALMENTE CORREGIDO - El webhook crea el booking, pero si el móvil intenta crear otro, puede haber conflicto

### ESCENARIO 8: Múltiples bookings con mismo precio en ventana de 10 minutos
**Flujo**:
1. Usuario crea booking A (50k) → crea payment 'wallet'
2. Usuario crea booking B (50k) → crea payment 'wallet'
3. Usuario paga 50k con Wompi SIN bookingInfo
4. Webhook busca booking reciente por `price=50k` → encuentra booking A o B (aleatorio) → elimina wallet → crea card ❌

**Estado**: **NO CORREGIDO** - Puede vincular el pago al booking incorrecto

## Problemas Identificados

### PROBLEMA CRÍTICO 1: BookingService no verifica externalReference
**Ubicación**: `BookingService.ts:251`

```typescript
const existingPayment = await PaymentModel.findOne({
    bookingId: booking._id,
    status: 'paid'
});
```

**Problema**: Solo verifica si existe un payment con `status='paid'`, pero NO verifica si existe un payment 'card' con `externalReference` que pueda estar relacionado con una transacción Wompi.

**Solución**: Verificar también por `externalReference` o por `method='card'` y `isOnline=true`.

### PROBLEMA CRÍTICO 2: Búsqueda de booking reciente es imprecisa
**Ubicación**: `PaymentController.ts:328`

```typescript
const recentBooking = await BookingModel.findOne({
    tenantId: transaction.tenantId,
    studentId: transaction.studentId,
    price: result.amount,
    status: { $in: ['pending', 'confirmed'] },
    createdAt: { $gte: new Date(Date.now() - 10 * 60 * 1000) }
}).sort({ createdAt: -1 });
```

**Problemas**:
1. Solo busca por `price` - puede haber múltiples bookings con mismo precio
2. Ventana de 10 minutos puede ser demasiado corta o demasiado larga
3. No verifica que el booking NO tenga ya un payment 'card'

**Solución**: 
- Verificar que el booking NO tenga payment 'card' con `externalReference`
- Usar ventana más corta (5 minutos) o mejor aún, buscar bookings SIN payment 'card'

### PROBLEMA CRÍTICO 3: Móvil no envía bookingInfo cuando paga después de crear booking
**Ubicación**: `mobile/lib/features/booking/presentation/screens/book_court_screen.dart:1508`

**Problema**: Cuando el usuario tiene balance insuficiente y hace clic en "Recargar y Reservar", el flujo es:
1. Muestra `PaymentDialog` con `bookingData` (debería tener bookingInfo)
2. Pero el booking aún NO se ha creado
3. Si el usuario paga primero, el webhook no tiene bookingInfo
4. Luego el usuario crea el booking, y se crea payment 'wallet'

**Solución**: El móvil debería crear el booking PRIMERO, luego iniciar el pago con `bookingInfo`.

## Soluciones Propuestas

### SOLUCIÓN 1: Mejorar verificación en BookingService
```typescript
// Verificar si existe payment 'card' con externalReference (Wompi)
const existingCardPayment = await PaymentModel.findOne({
    bookingId: booking._id,
    method: 'card',
    isOnline: true,
    status: 'paid'
});

if (existingCardPayment) {
    logger.info('Skipping wallet payment - card payment already exists');
    return;
}
```

### SOLUCIÓN 2: Mejorar búsqueda de booking reciente
```typescript
// Buscar bookings SIN payment 'card' (más preciso)
const recentBooking = await BookingModel.findOne({
    tenantId: transaction.tenantId,
    studentId: transaction.studentId,
    price: result.amount,
    status: { $in: ['pending', 'confirmed'] },
    createdAt: { $gte: new Date(Date.now() - 5 * 60 * 1000) },
    // Verificar que NO tenga payment 'card'
    _id: {
        $nin: await PaymentModel.distinct('bookingId', {
            method: 'card',
            isOnline: true,
            status: 'paid',
            externalReference: { $exists: true }
        })
    }
}).sort({ createdAt: -1 });
```

### SOLUCIÓN 3: Cambiar flujo del móvil
El móvil debería:
1. Crear booking PRIMERO (con `status='pending'` si no hay balance)
2. Luego iniciar pago con `bookingInfo` completo
3. Si el pago falla, cancelar el booking

## Recomendación Final

**Implementar las 3 soluciones en este orden**:
1. SOLUCIÓN 1 (BookingService) - Previene duplicados cuando booking se crea después del webhook
2. SOLUCIÓN 2 (PaymentController) - Mejora matching de bookings recientes
3. SOLUCIÓN 3 (Móvil) - Cambia el flujo para siempre enviar bookingInfo
