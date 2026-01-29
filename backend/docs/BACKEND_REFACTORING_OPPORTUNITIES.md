# Oportunidades de Refactorización - Patrones de Comportamiento (GoF)

**Análisis realizado por:** Arquitecto de Software Senior  
**Fecha:** 2026-01-27  
**Enfoque:** Clean Architecture + Patrones de Comportamiento (GoF)

---

## Resumen Ejecutivo

Este documento identifica oportunidades de refactorización en el backend usando **Patrones de Comportamiento** del Gang of Four (GoF) para mejorar la escalabilidad, mantenibilidad y adherencia a Clean Architecture.

**Archivos analizados:** Controladores, Servicios, Middlewares, Casos de Uso  
**Patrones identificados:** Strategy, State, Chain of Responsibility, Template Method, Observer

---

## 1. STRATEGY PATTERN - Lógica Condicional por Tipo

### 1.1. Cálculo de Rangos de Fechas por Período

**Ubicación:** `src/application/controllers/AnalyticsController.ts:327-349`

**El Problema:**
```typescript
private getDateRange(period: string): { start: Date; end: Date } {
  const now = new Date();
  const start = new Date();
  
  switch (period) {
    case 'week':
      start.setDate(now.getDate() - 7);
      break;
    case 'month':
      start.setMonth(now.getMonth() - 1);
      break;
    case 'quarter':
      start.setMonth(now.getMonth() - 3);
      break;
    case 'year':
      start.setFullYear(now.getFullYear() - 1);
      break;
    default:
      start.setMonth(now.getMonth() - 1);
  }
  
  return { start, end: now };
}
```

**Violación:** Viola el principio **Open/Closed (OCP)** - cada nuevo período requiere modificar el switch. También se repite en `TenantAdminController.ts:1263`.

**Patrón Sugerido:** **Strategy Pattern**

**Refactorización:**

```typescript
// domain/services/analytics/PeriodStrategy.ts
export interface PeriodStrategy {
  calculateRange(now: Date): { start: Date; end: Date };
}

export class WeekPeriodStrategy implements PeriodStrategy {
  calculateRange(now: Date): { start: Date; end: Date } {
    const start = new Date(now);
    start.setDate(now.getDate() - 7);
    return { start, end: now };
  }
}

export class MonthPeriodStrategy implements PeriodStrategy {
  calculateRange(now: Date): { start: Date; end: Date } {
    const start = new Date(now);
    start.setMonth(now.getMonth() - 1);
    return { start, end: now };
  }
}

export class QuarterPeriodStrategy implements PeriodStrategy {
  calculateRange(now: Date): { start: Date; end: Date } {
    const start = new Date(now);
    start.setMonth(now.getMonth() - 3);
    return { start, end: now };
  }
}

export class YearPeriodStrategy implements PeriodStrategy {
  calculateRange(now: Date): { start: Date; end: Date } {
    const start = new Date(now);
    start.setFullYear(now.getFullYear() - 1);
    return { start, end: now };
  }
}

// application/services/analytics/PeriodStrategyFactory.ts
export class PeriodStrategyFactory {
  private static strategies: Map<string, PeriodStrategy> = new Map([
    ['week', new WeekPeriodStrategy()],
    ['month', new MonthPeriodStrategy()],
    ['quarter', new QuarterPeriodStrategy()],
    ['year', new YearPeriodStrategy()],
  ]);

  static getStrategy(period: string): PeriodStrategy {
    return this.strategies.get(period) || this.strategies.get('month')!;
  }
}

// Uso en AnalyticsController
private getDateRange(period: string): { start: Date; end: Date } {
  const strategy = PeriodStrategyFactory.getStrategy(period);
  return strategy.calculateRange(new Date());
}
```

**Beneficios:**
- ✅ Extensible sin modificar código existente (OCP)
- ✅ Testeable de forma aislada
- ✅ Reutilizable en múltiples controladores

---

### 1.2. Mapeo de Tipos de Servicio a Colores/Etiquetas

**Ubicación:** `src/application/controllers/AnalyticsController.ts:617-628, 685-696`

**El Problema:**
```typescript
private getServiceTypeColor(serviceType: string): string {
  switch (serviceType) {
    case 'individual_class':
      return '#2196F3';
    case 'group_class':
      return '#4CAF50';
    case 'court_rental':
      return '#FF9800';
    default:
      return '#9C27B0';
  }
}

private getServiceTypeLabel(type: string): string {
  switch (type) {
    case 'individual_class':
      return 'Individual';
    case 'group_class':
      return 'Grupal';
    case 'court_rental':
      return 'Alquiler';
    default:
      return type;
  }
}
```

**Violación:** Lógica de presentación mezclada con lógica de negocio. Viola **Single Responsibility Principle (SRP)**.

**Patrón Sugerido:** **Strategy Pattern** con Factory

**Refactorización:**

```typescript
// domain/services/analytics/ServiceTypeStrategy.ts
export interface ServiceTypeStrategy {
  getColor(): string;
  getLabel(): string;
  getType(): BookingType;
}

export class IndividualClassStrategy implements ServiceTypeStrategy {
  getColor(): string { return '#2196F3'; }
  getLabel(): string { return 'Individual'; }
  getType(): BookingType { return 'individual_class'; }
}

export class GroupClassStrategy implements ServiceTypeStrategy {
  getColor(): string { return '#4CAF50'; }
  getLabel(): string { return 'Grupal'; }
  getType(): BookingType { return 'group_class'; }
}

export class CourtRentalStrategy implements ServiceTypeStrategy {
  getColor(): string { return '#FF9800'; }
  getLabel(): string { return 'Alquiler'; }
  getType(): BookingType { return 'court_rental'; }
}

// application/services/analytics/ServiceTypeStrategyFactory.ts
export class ServiceTypeStrategyFactory {
  private static strategies: Map<BookingType, ServiceTypeStrategy> = new Map([
    ['individual_class', new IndividualClassStrategy()],
    ['group_class', new GroupClassStrategy()],
    ['court_rental', new CourtRentalStrategy()],
  ]);

  static getStrategy(type: BookingType): ServiceTypeStrategy {
    return this.strategies.get(type) || new IndividualClassStrategy();
  }
}

// Uso en AnalyticsController
private getServiceTypeColor(serviceType: string): string {
  const strategy = ServiceTypeStrategyFactory.getStrategy(serviceType as BookingType);
  return strategy.getColor();
}

private getServiceTypeLabel(type: string): string {
  const strategy = ServiceTypeStrategyFactory.getStrategy(type as BookingType);
  return strategy.getLabel();
}
```

---

### 1.3. Operaciones de Balance (Add/Subtract/Set)

**Ubicación:** `src/application/controllers/TenantAdminController.ts:2497-2506`

**El Problema:**
```typescript
let newBalance = relation.balance;
if (type === 'add') {
  newBalance += amount;
} else if (type === 'subtract') {
  newBalance -= amount;
} else if (type === 'set') {
  newBalance = amount;
} else {
  res.status(400).json({ error: 'Tipo de operación inválido (add, subtract, set)' });
  return;
}
```

**Violación:** Lógica condicional que viola OCP. Cada nueva operación requiere modificar el if-else.

**Patrón Sugerido:** **Strategy Pattern**

**Refactorización:**

```typescript
// domain/services/balance/BalanceOperationStrategy.ts
export interface BalanceOperationStrategy {
  calculate(currentBalance: number, amount: number): number;
  validate(amount: number): boolean;
}

export class AddBalanceStrategy implements BalanceOperationStrategy {
  calculate(currentBalance: number, amount: number): number {
    return currentBalance + amount;
  }
  validate(amount: number): boolean { return true; }
}

export class SubtractBalanceStrategy implements BalanceOperationStrategy {
  calculate(currentBalance: number, amount: number): number {
    return currentBalance - amount;
  }
  validate(amount: number): boolean {
    // Podría validar que no quede negativo
    return true;
  }
}

export class SetBalanceStrategy implements BalanceOperationStrategy {
  calculate(currentBalance: number, amount: number): number {
    return amount;
  }
  validate(amount: number): boolean {
    return amount >= 0;
  }
}

// application/services/balance/BalanceOperationFactory.ts
export class BalanceOperationFactory {
  private static strategies: Map<string, BalanceOperationStrategy> = new Map([
    ['add', new AddBalanceStrategy()],
    ['subtract', new SubtractBalanceStrategy()],
    ['set', new SetBalanceStrategy()],
  ]);

  static getStrategy(type: string): BalanceOperationStrategy | null {
    return this.strategies.get(type) || null;
  }
}

// Uso en TenantAdminController
const strategy = BalanceOperationFactory.getStrategy(type);
if (!strategy) {
  res.status(400).json({ error: 'Tipo de operación inválido (add, subtract, set)' });
  return;
}

if (!strategy.validate(amount)) {
  res.status(400).json({ error: 'Monto inválido para esta operación' });
  return;
}

relation.balance = strategy.calculate(relation.balance, amount);
```

---

## 2. STATE PATTERN - Gestión de Estados de Entidades

### 2.1. Estados de Booking (Pending → Confirmed → Completed → Cancelled)

**Ubicación:** Múltiples archivos:
- `src/application/controllers/TenantAdminController.ts:1890-2035`
- `src/application/services/BookingService.ts:208`
- `src/application/controllers/AnalyticsController.ts:400, 439, 559, 742`
- Y muchos más con `booking.status === 'completed'`, `booking.status === 'cancelled'`, etc.

**El Problema:**
```typescript
// Lógica dispersa en múltiples lugares
if (booking.status === 'cancelled') {
  res.status(400).json({ error: 'No se puede cobrar una reserva cancelada' });
  return;
}

if (booking.status === 'completed') {
  res.status(400).json({ error: 'No se puede cancelar una reserva completada' });
  return;
}

booking.status = 'confirmed';
// ... más lógica

if (booking.status === 'completed' && !paidBookingIds.has(booking._id.toString())) {
  totalRevenue += booking.price;
}
```

**Violación:** 
- Lógica de transiciones de estado dispersa
- Validaciones de estado duplicadas
- Viola **Single Responsibility** - cada controlador maneja estados
- No hay encapsulación del comportamiento por estado

**Patrón Sugerido:** **State Pattern**

**Refactorización:**

```typescript
// domain/entities/booking/BookingState.ts
export interface BookingState {
  confirm(booking: Booking, context: BookingStateContext): Promise<void>;
  cancel(booking: Booking, context: BookingStateContext, reason?: string): Promise<void>;
  complete(booking: Booking, context: BookingStateContext): Promise<void>;
  canTransitionTo(newState: BookingStatus): boolean;
  getStatus(): BookingStatus;
}

export interface BookingStateContext {
  updateSchedule?: (scheduleId: string, status: string) => Promise<void>;
  createPayment?: (paymentData: any) => Promise<any>;
  syncBalance?: (studentId: string, tenantId: string) => Promise<void>;
}

// domain/entities/booking/states/PendingBookingState.ts
export class PendingBookingState implements BookingState {
  getStatus(): BookingStatus { return 'pending'; }

  canTransitionTo(newState: BookingStatus): boolean {
    return ['confirmed', 'cancelled'].includes(newState);
  }

  async confirm(booking: Booking, context: BookingStateContext): Promise<void> {
    if (!this.canTransitionTo('confirmed')) {
      throw new Error('No se puede confirmar una reserva desde estado pending');
    }
    booking.status = 'confirmed';
    if (booking.scheduleId && context.updateSchedule) {
      await context.updateSchedule(booking.scheduleId.toString(), 'confirmed');
    }
  }

  async cancel(booking: Booking, context: BookingStateContext, reason?: string): Promise<void> {
    if (!this.canTransitionTo('cancelled')) {
      throw new Error('No se puede cancelar desde este estado');
    }
    booking.status = 'cancelled';
    if (reason) {
      booking.notes = booking.notes 
        ? `${booking.notes}\n\nCancelada: ${reason}`
        : `Cancelada: ${reason}`;
    }
    if (booking.scheduleId && context.updateSchedule) {
      await context.updateSchedule(booking.scheduleId.toString(), 'cancelled');
    }
  }

  async complete(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('No se puede completar una reserva pendiente sin confirmar');
  }
}

// domain/entities/booking/states/ConfirmedBookingState.ts
export class ConfirmedBookingState implements BookingState {
  getStatus(): BookingStatus { return 'confirmed'; }

  canTransitionTo(newState: BookingStatus): boolean {
    return ['completed', 'cancelled'].includes(newState);
  }

  async confirm(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('La reserva ya está confirmada');
  }

  async cancel(booking: Booking, context: BookingStateContext, reason?: string): Promise<void> {
    if (!this.canTransitionTo('cancelled')) {
      throw new Error('No se puede cancelar desde este estado');
    }
    booking.status = 'cancelled';
    // Lógica específica de cancelación desde confirmed
    if (booking.scheduleId && context.updateSchedule) {
      await context.updateSchedule(booking.scheduleId.toString(), 'cancelled');
    }
  }

  async complete(booking: Booking, context: BookingStateContext): Promise<void> {
    if (!this.canTransitionTo('completed')) {
      throw new Error('No se puede completar desde este estado');
    }
    booking.status = 'completed';
    // Lógica específica de completado
  }
}

// domain/entities/booking/states/CompletedBookingState.ts
export class CompletedBookingState implements BookingState {
  getStatus(): BookingStatus { return 'completed'; }

  canTransitionTo(newState: BookingStatus): boolean {
    return false; // Estado final
  }

  async confirm(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('No se puede confirmar una reserva completada');
  }

  async cancel(booking: Booking, context: BookingStateContext, reason?: string): Promise<void> {
    throw new Error('No se puede cancelar una reserva completada');
  }

  async complete(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('La reserva ya está completada');
  }
}

// domain/entities/booking/states/CancelledBookingState.ts
export class CancelledBookingState implements BookingState {
  getStatus(): BookingStatus { return 'cancelled'; }

  canTransitionTo(newState: BookingStatus): boolean {
    return false; // Estado final
  }

  async confirm(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('No se puede confirmar una reserva cancelada');
  }

  async cancel(booking: Booking, context: BookingStateContext, reason?: string): Promise<void> {
    throw new Error('La reserva ya está cancelada');
  }

  async complete(booking: Booking, context: BookingStateContext): Promise<void> {
    throw new Error('No se puede completar una reserva cancelada');
  }
}

// domain/entities/booking/BookingStateFactory.ts
export class BookingStateFactory {
  private static states: Map<BookingStatus, BookingState> = new Map([
    ['pending', new PendingBookingState()],
    ['confirmed', new ConfirmedBookingState()],
    ['completed', new CompletedBookingState()],
    ['cancelled', new CancelledBookingState()],
  ]);

  static getState(status: BookingStatus): BookingState {
    return this.states.get(status) || this.states.get('pending')!;
  }
}

// Uso en TenantAdminController
confirmBooking = async (req: Request, res: Response): Promise<void> => {
  // ...
  const booking = await BookingModel.findOne({ /* ... */ });
  
  const currentState = BookingStateFactory.getState(booking.status as BookingStatus);
  const context: BookingStateContext = {
    updateSchedule: async (scheduleId, status) => {
      await ScheduleModel.findByIdAndUpdate(scheduleId, { status });
    },
    syncBalance: async (studentId, tenantId) => {
      await this.balanceService.syncBalance(studentId, tenantId);
    }
  };

  try {
    await currentState.confirm(booking, context);
    await booking.save();
    // ... lógica de pago
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
    return;
  }
  
  res.json({ status: booking.status, message: 'Reserva confirmada exitosamente' });
};
```

**Beneficios:**
- ✅ Encapsula comportamiento por estado
- ✅ Transiciones de estado validadas centralmente
- ✅ Elimina lógica condicional dispersa
- ✅ Fácil agregar nuevos estados (OCP)

---

### 2.2. Estados de Payment (Pending → Paid → Cancelled)

**Ubicación:** `src/application/controllers/TenantAdminController.ts:279-283, 366-368, 427`

**El Problema:**
```typescript
if (status === 'APPROVED') manualFilter.status = 'paid';
else if (status === 'PENDING') manualFilter.status = 'pending';
else if (status === 'VOIDED') manualFilter.status = 'cancelled';
else if (status === 'pending') manualFilter.status = 'pending';
else if (status === 'paid') manualFilter.status = 'paid';

status: payment.status === 'paid' ? 'APPROVED' :
  payment.status === 'pending' ? 'PENDING' :
    payment.status === 'cancelled' ? 'VOIDED' : payment.status.toUpperCase(),
```

**Violación:** Mapeo de estados duplicado y lógica condicional.

**Patrón Sugerido:** **State Pattern** con Adapter para estados externos (Wompi)

**Refactorización:**

```typescript
// domain/entities/payment/PaymentState.ts
export interface PaymentState {
  getInternalStatus(): PaymentStatus;
  getExternalStatus(): string; // Para Wompi
  canTransitionTo(newStatus: PaymentStatus): boolean;
}

export class PaidPaymentState implements PaymentState {
  getInternalStatus(): PaymentStatus { return 'paid'; }
  getExternalStatus(): string { return 'APPROVED'; }
  canTransitionTo(newStatus: PaymentStatus): boolean {
    return false; // Estado final
  }
}

export class PendingPaymentState implements PaymentState {
  getInternalStatus(): PaymentStatus { return 'pending'; }
  getExternalStatus(): string { return 'PENDING'; }
  canTransitionTo(newStatus: PaymentStatus): boolean {
    return ['paid', 'cancelled'].includes(newStatus);
  }
}

export class CancelledPaymentState implements PaymentState {
  getInternalStatus(): PaymentStatus { return 'cancelled'; }
  getExternalStatus(): string { return 'VOIDED'; }
  canTransitionTo(newStatus: PaymentStatus): boolean {
    return false; // Estado final
  }
}

// application/services/payment/PaymentStateAdapter.ts
export class PaymentStateAdapter {
  static fromExternal(externalStatus: string): PaymentState {
    const mapping: Record<string, PaymentState> = {
      'APPROVED': new PaidPaymentState(),
      'PENDING': new PendingPaymentState(),
      'VOIDED': new CancelledPaymentState(),
    };
    return mapping[externalStatus] || new PendingPaymentState();
  }

  static fromInternal(internalStatus: PaymentStatus): PaymentState {
    const mapping: Record<PaymentStatus, PaymentState> = {
      'paid': new PaidPaymentState(),
      'pending': new PendingPaymentState(),
      'cancelled': new CancelledPaymentState(),
    };
    return mapping[internalStatus];
  }
}
```

---

## 3. CHAIN OF RESPONSIBILITY - Validaciones Secuenciales

### 3.1. Middleware de Validación de Analytics

**Ubicación:** `src/application/middleware/analyticsValidation.ts`

**El Problema:**
El archivo tiene múltiples middlewares independientes (`validatePeriod`, `validateServiceType`, `validateBookingStatus`, etc.) que se aplican secuencialmente. Aunque funcionan, no hay un patrón claro de encadenamiento y cada uno maneja su propia respuesta HTTP.

**Violación:** No viola principios directamente, pero podría ser más flexible y extensible.

**Patrón Sugerido:** **Chain of Responsibility**

**Refactorización:**

```typescript
// application/middleware/analytics/ValidationHandler.ts
export interface ValidationHandler {
  setNext(handler: ValidationHandler): ValidationHandler;
  handle(req: Request, res: Response, next: NextFunction): Promise<void>;
}

export abstract class BaseValidationHandler implements ValidationHandler {
  private nextHandler?: ValidationHandler;

  setNext(handler: ValidationHandler): ValidationHandler {
    this.nextHandler = handler;
    return handler;
  }

  async handle(req: Request, res: Response, next: NextFunction): Promise<void> {
    const error = await this.validate(req);
    if (error) {
      return res.status(400).json(error);
    }
    
    if (this.nextHandler) {
      return this.nextHandler.handle(req, res, next);
    }
    
    next();
  }

  protected abstract validate(req: Request): Promise<ValidationError | null>;
}

export interface ValidationError {
  error: string;
  message: string;
  [key: string]: any;
}

// application/middleware/analytics/PeriodValidationHandler.ts
export class PeriodValidationHandler extends BaseValidationHandler {
  private static VALID_PERIODS = ['week', 'month', 'quarter', 'year'];

  protected async validate(req: Request): Promise<ValidationError | null> {
    const { period } = req.query;
    if (period && typeof period === 'string') {
      if (!PeriodValidationHandler.VALID_PERIODS.includes(period)) {
        return {
          error: 'Período inválido',
          message: `El período debe ser uno de: ${PeriodValidationHandler.VALID_PERIODS.join(', ')}`,
          validPeriods: PeriodValidationHandler.VALID_PERIODS,
          received: period,
        };
      }
    }
    return null;
  }
}

// application/middleware/analytics/ServiceTypeValidationHandler.ts
export class ServiceTypeValidationHandler extends BaseValidationHandler {
  private static VALID_SERVICE_TYPES = ['individual_class', 'group_class', 'court_rental'];

  protected async validate(req: Request): Promise<ValidationError | null> {
    const { serviceType } = req.query;
    if (serviceType && typeof serviceType === 'string') {
      if (!ServiceTypeValidationHandler.VALID_SERVICE_TYPES.includes(serviceType)) {
        return {
          error: 'Tipo de servicio inválido',
          message: `El tipo de servicio debe ser uno de: ${ServiceTypeValidationHandler.VALID_SERVICE_TYPES.join(', ')}`,
          validServiceTypes: ServiceTypeValidationHandler.VALID_SERVICE_TYPES,
          received: serviceType,
        };
      }
    }
    return null;
  }
}

// application/middleware/analytics/DateRangeValidationHandler.ts
export class DateRangeValidationHandler extends BaseValidationHandler {
  protected async validate(req: Request): Promise<ValidationError | null> {
    const { startDate, endDate } = req.query;
    
    if (startDate && typeof startDate === 'string') {
      const start = new Date(startDate);
      if (isNaN(start.getTime())) {
        return {
          error: 'Fecha de inicio inválida',
          message: 'La fecha de inicio debe estar en formato ISO 8601 (YYYY-MM-DD)',
          received: startDate,
        };
      }
    }
    
    if (endDate && typeof endDate === 'string') {
      const end = new Date(endDate);
      if (isNaN(end.getTime())) {
        return {
          error: 'Fecha de fin inválida',
          message: 'La fecha de fin debe estar en formato ISO 8601 (YYYY-MM-DD)',
          received: endDate,
        };
      }
    }
    
    if (startDate && endDate && typeof startDate === 'string' && typeof endDate === 'string') {
      const start = new Date(startDate);
      const end = new Date(endDate);
      if (start >= end) {
        return {
          error: 'Rango de fechas inválido',
          message: 'La fecha de inicio debe ser anterior a la fecha de fin',
          startDate,
          endDate,
        };
      }
    }
    
    return null;
  }
}

// Uso en routes/analytics.ts
import { PeriodValidationHandler } from '../middleware/analytics/PeriodValidationHandler';
import { ServiceTypeValidationHandler } from '../middleware/analytics/ServiceTypeValidationHandler';
import { DateRangeValidationHandler } from '../middleware/analytics/DateRangeValidationHandler';

const analyticsValidationChain = new PeriodValidationHandler()
  .setNext(new ServiceTypeValidationHandler())
  .setNext(new DateRangeValidationHandler());

router.get('/overview', analyticsValidationChain.handle.bind(analyticsValidationChain), controller.getOverview);
```

**Beneficios:**
- ✅ Encadenamiento flexible y dinámico
- ✅ Fácil agregar/quitar validadores
- ✅ Cada validador tiene responsabilidad única (SRP)
- ✅ Testeable de forma aislada

---

## 4. TEMPLATE METHOD - Algoritmos con Pasos Comunes

### 4.1. Procesamiento de Pagos Wompi (Webhook vs Status Query)

**Ubicación:** `src/application/controllers/PaymentController.ts:143-421, 430-738`

**El Problema:**
Los métodos `wompiWebhook` y `getTransactionStatus` tienen lógica **casi idéntica** para procesar pagos aprobados:
1. Validar transacción
2. Buscar payment existente
3. Verificar si tiene bookingInfo
4. Si tiene booking: buscar/crear booking y crear payment
5. Si no tiene booking: buscar booking reciente o crear como recarga
6. Sincronizar balance

**Violación:** Duplicación masiva de código (~200 líneas duplicadas). Viola **DRY (Don't Repeat Yourself)**.

**Patrón Sugerido:** **Template Method**

**Refactorización:**

```typescript
// application/services/payment/PaymentProcessor.ts
export abstract class PaymentProcessor {
  protected logger = new Logger();
  protected balanceService = new BalanceService();
  protected bookingService = new BookingService();

  async processApprovedPayment(
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void> {
    // Template Method - define el esqueleto del algoritmo
    const existingPayment = await this.findExistingPayment(result.reference);
    
    if (existingPayment) {
      this.logger.info('Payment already exists, skipping', { reference: result.reference });
      return;
    }

    const hasBookingInfo = this.hasBookingInfo(transaction);
    
    if (hasBookingInfo) {
      await this.processBookingPayment(transaction, result, tenant);
    } else {
      await this.processRechargeOrBookingMatch(transaction, result, tenant);
    }
  }

  // Hook methods - pueden ser sobrescritos por subclases
  protected abstract findExistingPayment(reference: string): Promise<PaymentDocument | null>;
  protected abstract hasBookingInfo(transaction: TransactionDocument): boolean;

  // Pasos comunes del algoritmo
  protected async processBookingPayment(
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void> {
    const bInfo = transaction.metadata?.bookingInfo;
    let existingBooking = await this.findExistingBooking(bInfo, transaction);

    if (existingBooking) {
      await this.handleExistingBookingPayment(existingBooking, transaction, result, tenant);
    } else {
      await this.createBookingAndPayment(transaction, result, tenant, bInfo);
    }
  }

  protected async processRechargeOrBookingMatch(
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void> {
    const recentBooking = await this.findRecentBooking(transaction, result);
    
    if (recentBooking) {
      await this.linkPaymentToRecentBooking(recentBooking, transaction, result, tenant);
    } else {
      await this.createRechargePayment(transaction, result, tenant);
    }
  }

  // Métodos auxiliares comunes
  protected async findExistingBooking(
    bInfo: any,
    transaction: TransactionDocument
  ): Promise<BookingDocument | null> {
    if (bInfo.scheduleId) {
      return await BookingModel.findOne({
        scheduleId: new Types.ObjectId(bInfo.scheduleId),
        studentId: transaction.studentId,
        tenantId: transaction.tenantId,
        status: { $in: ['pending', 'confirmed'] }
      });
    } else if (bInfo.courtId && bInfo.startTime) {
      return await BookingModel.findOne({
        courtId: new Types.ObjectId(bInfo.courtId),
        studentId: transaction.studentId,
        tenantId: transaction.tenantId,
        bookingDate: new Date(bInfo.startTime),
        status: { $in: ['pending', 'confirmed'] }
      });
    }
    return null;
  }

  protected async createRechargePayment(
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void> {
    const newPayment = new PaymentModel({
      tenantId: tenant._id,
      studentId: transaction.studentId,
      professorId: null,
      amount: result.amount,
      date: new Date(),
      status: 'paid',
      method: 'card',
      description: `Recarga Wompi Ref: ${result.reference}`,
      concept: 'Recarga de Saldo',
      externalReference: result.reference,
      isOnline: true
    });
    await newPayment.save();
    await this.balanceService.syncBalance(transaction.studentId, tenant._id);
  }

  // Métodos abstractos que deben implementar las subclases
  protected abstract findRecentBooking(
    transaction: TransactionDocument,
    result: PaymentValidationResult
  ): Promise<BookingDocument | null>;

  protected abstract handleExistingBookingPayment(
    booking: BookingDocument,
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void>;

  protected abstract createBookingAndPayment(
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument,
    bInfo: any
  ): Promise<void>;

  protected abstract linkPaymentToRecentBooking(
    booking: BookingDocument,
    transaction: TransactionDocument,
    result: PaymentValidationResult,
    tenant: TenantDocument
  ): Promise<void>;
}

// application/services/payment/WompiWebhookProcessor.ts
export class WompiWebhookProcessor extends PaymentProcessor {
  protected async findExistingPayment(reference: string): Promise<PaymentDocument | null> {
    return await PaymentModel.findOne({
      $or: [
        { externalReference: reference },
        { description: { $regex: reference } }
      ]
    });
  }

  protected hasBookingInfo(transaction: TransactionDocument): boolean {
    return !!transaction.metadata?.bookingInfo;
  }

  protected async findRecentBooking(
    transaction: TransactionDocument,
    result: PaymentValidationResult
  ): Promise<BookingDocument | null> {
    const bookingsWithCardPayments = await PaymentModel.distinct('bookingId', {
      method: 'card',
      isOnline: true,
      status: 'paid',
      externalReference: { $exists: true, $ne: null }
    });

    return await BookingModel.findOne({
      tenantId: transaction.tenantId,
      studentId: transaction.studentId,
      price: result.amount,
      status: { $in: ['pending', 'confirmed'] },
      createdAt: { $gte: new Date(Date.now() - 5 * 60 * 1000) },
      _id: { $nin: bookingsWithCardPayments }
    }).sort({ createdAt: -1 });
  }

  // Implementar métodos abstractos restantes...
  protected async handleExistingBookingPayment(...): Promise<void> { /* ... */ }
  protected async createBookingAndPayment(...): Promise<void> { /* ... */ }
  protected async linkPaymentToRecentBooking(...): Promise<void> { /* ... */ }
}

// application/services/payment/WompiStatusQueryProcessor.ts
export class WompiStatusQueryProcessor extends PaymentProcessor {
  // Similar a WompiWebhookProcessor pero con lógica específica para status queries
  // Puede tener variaciones en cómo busca bookings recientes, etc.
}

// Uso en PaymentController
export class PaymentController {
  private webhookProcessor = new WompiWebhookProcessor();
  private statusQueryProcessor = new WompiStatusQueryProcessor();

  public wompiWebhook = async (req: Request, res: Response) => {
    // ... validación inicial
    if (result.status === 'APPROVED' && !isNaN(result.amount) && result.amount > 0) {
      await this.webhookProcessor.processApprovedPayment(transaction, result, tenant);
    }
    return res.status(200).json({ status: 'ok' });
  };

  public getTransactionStatus = async (req: AuthenticatedRequest, res: Response) => {
    // ... validación inicial
    if (result.status === 'APPROVED' && !isNaN(result.amount) && result.amount > 0) {
      await this.statusQueryProcessor.processApprovedPayment(transaction, result, tenant);
    }
    return res.status(200).json({ /* ... */ });
  };
}
```

**Beneficios:**
- ✅ Elimina ~200 líneas de código duplicado
- ✅ Algoritmo centralizado y mantenible
- ✅ Fácil agregar nuevos tipos de procesadores
- ✅ Testeable de forma aislada

---

### 4.2. Generación de Gráficos de Analytics

**Ubicación:** `src/application/controllers/AnalyticsController.ts:507-660`

**El Problema:**
Los métodos `getRevenueChart`, `getBookingsChart`, `getStudentsChart` tienen estructura similar:
1. Obtener datos filtrados
2. Agrupar/Procesar datos
3. Formatear para respuesta
4. Retornar estructura de gráfico

**Patrón Sugerido:** **Template Method**

**Refactorización:**

```typescript
// application/services/analytics/ChartGenerator.ts
export abstract class ChartGenerator {
  protected abstract fetchData(
    professorId: string,
    dateRange: { start: Date; end: Date },
    filters?: any
  ): Promise<any[]>;

  protected abstract processData(data: any[]): any[];

  protected abstract formatChart(data: any[]): ChartData;

  async generate(
    professorId: string,
    dateRange: { start: Date; end: Date },
    filters?: any
  ): Promise<ChartData> {
    const rawData = await this.fetchData(professorId, dateRange, filters);
    const processedData = this.processData(rawData);
    return this.formatChart(processedData);
  }
}

// application/services/analytics/RevenueChartGenerator.ts
export class RevenueChartGenerator extends ChartGenerator {
  protected async fetchData(...): Promise<any[]> {
    // Lógica específica para obtener payments
  }

  protected processData(payments: any[]): any[] {
    // Agrupar por servicio y mes
  }

  protected formatChart(data: any[]): ChartData {
    return {
      title: 'Ingresos por Mes',
      type: 'line',
      data,
      // ...
    };
  }
}
```

---

## 5. OBSERVER PATTERN - Notificaciones y Eventos

### 5.1. Efectos Secundarios de Creación de Booking

**Ubicación:** `src/application/services/BookingService.ts:122-357`

**El Problema:**
Cuando se crea un booking, se ejecutan múltiples efectos secundarios **hardcodeados**:
1. Descuenta balance del estudiante
2. Crea payment automático (si aplica)
3. Sincroniza balance
4. Actualiza schedule
5. (Futuro) Enviar email de confirmación
6. (Futuro) Notificación push
7. (Futuro) Actualizar estadísticas

**Violación:** El caso de uso principal conoce todos los efectos secundarios. Viola **Single Responsibility** y hace difícil agregar nuevos efectos.

**Patrón Sugerido:** **Observer Pattern** / **Event Emitter**

**Refactorización:**

```typescript
// domain/events/BookingEvents.ts
export interface BookingCreatedEvent {
  bookingId: string;
  studentId: string;
  tenantId: string;
  serviceType: BookingType;
  price: number;
  status: BookingStatus;
  createdAt: Date;
}

export interface BookingConfirmedEvent {
  bookingId: string;
  studentId: string;
  tenantId: string;
  confirmedBy: string;
}

export interface BookingCancelledEvent {
  bookingId: string;
  studentId: string;
  tenantId: string;
  reason?: string;
}

// application/events/EventEmitter.ts
export class EventEmitter {
  private listeners: Map<string, EventListener[]> = new Map();

  on(event: string, listener: EventListener): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(listener);
  }

  async emit(event: string, data: any): Promise<void> {
    const eventListeners = this.listeners.get(event) || [];
    await Promise.all(eventListeners.map(listener => listener(data)));
  }
}

export type EventListener = (data: any) => Promise<void> | void;

// application/events/listeners/BalanceDeductionListener.ts
export class BalanceDeductionListener {
  constructor(
    private studentTenantRepository: StudentTenantRepository,
    private balanceService: BalanceService
  ) {}

  async handle(event: BookingCreatedEvent): Promise<void> {
    const relation = await this.studentTenantRepository.findByStudentAndTenant(
      event.studentId,
      event.tenantId
    );
    
    if (relation) {
      relation.balance -= event.price;
      await relation.save();
    }
  }
}

// application/events/listeners/PaymentCreationListener.ts
export class PaymentCreationListener {
  constructor(
    private paymentRepository: PaymentRepository,
    private tenantService: TenantService
  ) {}

  async handle(event: BookingCreatedEvent): Promise<void> {
    const tenant = await this.tenantService.getTenantById(event.tenantId);
    const enableOnlinePayments = tenant?.config?.payments?.enableOnlinePayments === true;
    
    if (enableOnlinePayments && !event.paymentAlreadyProcessed) {
      // Lógica de creación de payment
      await this.paymentRepository.create({
        // ...
      });
    }
  }
}

// application/events/listeners/BalanceSyncListener.ts
export class BalanceSyncListener {
  constructor(private balanceService: BalanceService) {}

  async handle(event: BookingCreatedEvent): Promise<void> {
    await this.balanceService.syncBalance(
      new Types.ObjectId(event.studentId),
      new Types.ObjectId(event.tenantId)
    );
  }
}

// application/events/listeners/EmailNotificationListener.ts
export class EmailNotificationListener {
  constructor(private emailService: EmailService) {}

  async handle(event: BookingCreatedEvent): Promise<void> {
    // Enviar email de confirmación
    await this.emailService.sendBookingConfirmation(event);
  }
}

// application/services/BookingService.ts (refactorizado)
export class BookingService {
  constructor(
    private eventEmitter: EventEmitter,
    private tenantService: TenantService
  ) {}

  async createBooking(data: CreateBookingData): Promise<BookingDocument> {
    // ... validaciones y lógica de negocio pura
    
    const booking = await BookingModel.create(bookingData);

    // Emitir evento - los listeners se encargan de los efectos secundarios
    await this.eventEmitter.emit('booking:created', {
      bookingId: booking._id.toString(),
      studentId: data.studentId.toString(),
      tenantId: data.tenantId.toString(),
      serviceType: data.serviceType,
      price: data.price,
      status: booking.status,
      createdAt: booking.createdAt || new Date(),
      paymentAlreadyProcessed: data.paymentAlreadyProcessed
    });

    return booking;
  }
}

// infrastructure/di/container.ts (configuración)
export function setupEventListeners(eventEmitter: EventEmitter): void {
  // Registrar listeners
  const balanceDeductionListener = new BalanceDeductionListener(/* ... */);
  const paymentCreationListener = new PaymentCreationListener(/* ... */);
  const balanceSyncListener = new BalanceSyncListener(/* ... */);
  const emailNotificationListener = new EmailNotificationListener(/* ... */);

  eventEmitter.on('booking:created', balanceDeductionListener.handle.bind(balanceDeductionListener));
  eventEmitter.on('booking:created', paymentCreationListener.handle.bind(paymentCreationListener));
  eventEmitter.on('booking:created', balanceSyncListener.handle.bind(balanceSyncListener));
  eventEmitter.on('booking:created', emailNotificationListener.handle.bind(emailNotificationListener));
  
  eventEmitter.on('booking:confirmed', emailNotificationListener.handleConfirmation.bind(emailNotificationListener));
  eventEmitter.on('booking:cancelled', emailNotificationListener.handleCancellation.bind(emailNotificationListener));
}
```

**Beneficios:**
- ✅ Desacopla efectos secundarios del caso de uso principal
- ✅ Fácil agregar nuevos listeners sin modificar BookingService
- ✅ Testeable - se pueden mockear listeners
- ✅ Escalable - se pueden agregar listeners asíncronos, colas, etc.

---

## Priorización de Refactorización

### Alta Prioridad (Impacto Alto, Esfuerzo Medio)
1. **State Pattern para Booking** - Lógica muy dispersa, alto riesgo de bugs
2. **Template Method para Payment Processing** - ~200 líneas duplicadas
3. **Observer Pattern para Booking Events** - Facilita futuras funcionalidades

### Media Prioridad (Impacto Medio, Esfuerzo Bajo)
4. **Strategy Pattern para Period Calculation** - Se usa en múltiples lugares
5. **Strategy Pattern para Service Type** - Mejora mantenibilidad

### Baja Prioridad (Impacto Bajo, Esfuerzo Bajo)
6. **Chain of Responsibility para Validaciones** - Ya funciona, mejora sería incremental
7. **Strategy Pattern para Balance Operations** - Lógica simple, bajo impacto

---

## Consideraciones de Implementación

### Testing
- Cada patrón debe tener tests unitarios para las clases base
- Tests de integración para verificar el flujo completo
- Mocking de dependencias en tests

### Migración
- Implementar patrones gradualmente
- Mantener compatibilidad con código existente
- Usar feature flags si es necesario

### Documentación
- Documentar cada patrón implementado
- Ejemplos de uso en código
- Diagramas de secuencia para flujos complejos

---

## Conclusión

La aplicación de estos patrones mejorará significativamente:
- ✅ **Mantenibilidad**: Código más organizado y fácil de entender
- ✅ **Escalabilidad**: Fácil agregar nuevas funcionalidades
- ✅ **Testabilidad**: Componentes aislados y testeables
- ✅ **Adherencia a SOLID**: Principios aplicados consistentemente
- ✅ **Clean Architecture**: Separación clara de responsabilidades

**Próximos Pasos:**
1. Revisar este documento con el equipo
2. Priorizar refactorizaciones según roadmap
3. Crear issues/tickets para cada refactorización
4. Implementar de forma incremental con tests
