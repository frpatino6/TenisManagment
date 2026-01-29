# Observer Pattern - Data Change Synchronization

Este módulo implementa el **Observer Pattern** para desacoplar las comunicaciones entre componentes y automatizar la invalidación de providers de Riverpod cuando ocurren cambios en los datos.

## Problema Resuelto

Antes de esta implementación, después de realizar una operación (ej: crear reserva), los Widgets o Comandos invalidaban manualmente múltiples providers específicos:

```dart
// ❌ Antes: Acoplamiento fuerte
ref.invalidate(tenantBookingsProvider);
ref.invalidate(studentBookingsProvider);
ref.invalidate(bookingStatsProvider);
```

Esto generaba:
- **Acoplamiento fuerte**: El widget conoce qué providers invalidar
- **Propenso a errores**: Si olvidamos invalidar algún provider, los datos quedan desactualizados
- **Difícil mantenimiento**: Si se agrega una nueva pantalla, hay que recordar invalidar sus providers

## Solución: Observer Pattern

Ahora, simplemente emitimos un evento y el sistema automáticamente invalida todos los providers relacionados:

```dart
// ✅ Ahora: Desacoplado y automático
final observer = ref.read(dataChangeObserverProvider);
observer.notifyChange(
  DataChangeEvent(
    changeType: DataChangeType.created,
    entityType: 'booking',
    entityId: booking.id,
  ),
);
```

## Arquitectura

### 1. Evento (`DataChangeEvent`)

Representa un cambio en los datos:

```dart
class DataChangeEvent {
  final DataChangeType changeType;  // created, updated, deleted
  final String entityType;          // 'booking', 'court', 'payment', etc.
  final String? entityId;           // ID opcional de la entidad
  final Map<String, dynamic>? metadata;  // Metadatos opcionales
}
```

### 2. Observer (`DataChangeObserver`)

Escucha eventos y automáticamente invalida los providers relacionados:

```dart
final observer = ref.read(dataChangeObserverProvider);
observer.notifyChange(event);
```

El observer tiene un mapeo interno que relaciona cada tipo de entidad con sus providers relacionados:

- **booking** → `tenantBookingsProvider`, `studentBookingsProvider`, `professorBookingsProvider`, etc.
- **payment** → `tenantPaymentsProvider`, `paymentHistoryProvider`, `studentInfoProvider`, etc.
- **court** → `courtsProvider`, `courtAvailableSlotsProvider`, `tenantCourtsProvider`, etc.

## Uso

### En Comandos (Command Pattern)

```dart
class RefreshDataCommand implements BookingCommand {
  final Ref ref;

  RefreshDataCommand(this.ref);

  @override
  Future<void> execute() async {
    final observer = ref.read(dataChangeObserverProvider);

    observer.notifyChange(
      const DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'court',
      ),
    );

    observer.notifyChange(
      const DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'booking',
      ),
    );
  }
}
```

### En Funciones de Utilidad

```dart
Future<void> confirmBookingQuickPayment(
  BuildContext context,
  WidgetRef ref,
  TenantBookingModel booking,
) async {
  // ... lógica de confirmación ...
  
  await ref
      .read(tenantAdminServiceProvider)
      .confirmBooking(booking.id, paymentStatus: 'paid');

  // Emitir evento en lugar de invalidar manualmente
  final observer = ref.read(dataChangeObserverProvider);
  observer.notifyChange(
    DataChangeEvent(
      changeType: DataChangeType.updated,
      entityType: 'booking',
      entityId: booking.id,
    ),
  );
}
```

### En Use Cases

```dart
class BookCourtUseCase {
  final Ref ref;
  final DataChangeObserver observer;

  BookCourtUseCase(this.ref, this.observer);

  Future<void> execute(BookCourtParams params) async {
    final booking = await courtService.bookCourt(...);
    
    // Emitir evento después de crear la reserva
    observer.notifyChange(
      DataChangeEvent(
        changeType: DataChangeType.created,
        entityType: 'booking',
        entityId: booking.id,
      ),
    );
  }
}
```

## Tipos de Entidades Soportadas

El sistema actualmente soporta los siguientes tipos de entidades:

- `booking` - Reservas
- `payment` - Pagos
- `court` - Canchas
- `schedule` / `class` - Horarios/Clases
- `professor` - Profesores
- `student` - Estudiantes
- `tenant` - Tenants/Centros

## Agregar Nuevos Tipos de Entidades

Para agregar soporte para un nuevo tipo de entidad, edita `data_change_observer.dart`:

```dart
void _getProvidersForEntity(String entityType) {
  switch (entityType.toLowerCase()) {
    // ... casos existentes ...
    
    case 'nueva_entidad':
      _ref.invalidate(nuevoProvider1);
      _ref.invalidate(nuevoProvider2);
      break;
  }
}
```

## Beneficios

✅ **Desacoplamiento**: Los componentes no necesitan conocer qué providers invalidar
✅ **Mantenibilidad**: Agregar nuevos providers es solo agregar una línea en el mapeo
✅ **Consistencia**: Todos los cambios de datos siguen el mismo patrón
✅ **Escalabilidad**: Fácil agregar nuevos tipos de entidades y providers
✅ **Testeable**: El observer puede ser mockeado fácilmente en tests

## Ejemplos de Refactorización

### Antes
```dart
await service.createBooking(...);
ref.invalidate(tenantBookingsProvider);
ref.invalidate(studentBookingsProvider);
ref.invalidate(bookingStatsProvider);
ref.invalidate(bookingCalendarProvider);
ref.invalidate(recentActivitiesProvider);
ref.invalidate(studentInfoProvider);
ref.invalidate(tenantMetricsProvider);
```

### Después
```dart
await service.createBooking(...);
final observer = ref.read(dataChangeObserverProvider);
observer.notifyChange(
  DataChangeEvent(
    changeType: DataChangeType.created,
    entityType: 'booking',
  ),
);
```

## Notas de Implementación

- El observer usa un `StreamController.broadcast()` para permitir múltiples listeners
- Los providers se invalidan automáticamente cuando se emite un evento
- El sistema maneja errores silenciosamente si un provider no existe
- El observer se limpia automáticamente cuando el Provider se destruye
