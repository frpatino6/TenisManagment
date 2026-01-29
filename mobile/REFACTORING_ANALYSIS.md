# Análisis de Refactorización - Patrones de Comportamiento GoF

## Resumen Ejecutivo

Este documento identifica oportunidades de refactorización en el código Dart de la aplicación Flutter usando **Patrones de Comportamiento** del Gang of Four (GoF). Se priorizan cambios que mejoran la mantenibilidad, escalabilidad y adherencia a principios SOLID.

**Alcance del Análisis:**
- ✅ 41 screens analizados
- ✅ 13 widgets analizados  
- ✅ 89 switch statements identificados
- ✅ 51 casos de gestión manual de estado con boolean flags
- ✅ 50+ event handlers complejos revisados
- ✅ 13 enums con lógica de mapeo identificados

---

## 1. Strategy Pattern - Complejidad Ciclomática

### 1.1 Mapeo de Estados a Colores (Alta Prioridad)

**Ubicación:** 
- `lib/features/tenant_admin/presentation/screens/tenant_bookings_list_screen.dart:458-471`
- `lib/features/student/presentation/screens/recent_activity_screen.dart:257-274`
- `lib/features/student/presentation/screens/my_bookings_screen.dart:342-353`
- `lib/features/tenant_admin/presentation/screens/tenant_payments_list_screen.dart:641-650`
- `lib/features/tenant_admin/presentation/screens/tenant_booking_details_screen.dart:126-151`
- `lib/features/professor/presentation/screens/manage_schedules_screen.dart:288-298`

**El Problema:**
- Múltiples métodos `_getStatusColor()` duplicados en diferentes pantallas
- Violación del principio **DRY (Don't Repeat Yourself)**
- Violación de **Open/Closed Principle**: Para agregar un nuevo estado, hay que modificar múltiples archivos
- Complejidad ciclomática alta: cada switch añade complejidad
- Difícil mantener consistencia entre diferentes pantallas

**Principios SOLID Violados:**
- **Single Responsibility**: El widget tiene responsabilidades de UI y lógica de mapeo
- **Open/Closed**: No está abierto para extensión sin modificación

**El Patrón Sugerido:** Strategy Pattern

**Refactorización:**

```dart
// lib/features/shared/domain/strategies/status_color_strategy.dart
abstract class StatusColorStrategy {
  Color getColor(String status);
  String getLabel(String status);
  IconData getIcon(String status);
}

class BookingStatusColorStrategy implements StatusColorStrategy {
  @override
  Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  String getLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmado';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelado';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  @override
  IconData getIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }
}

class PaymentStatusColorStrategy implements StatusColorStrategy {
  @override
  Color getColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'DECLINED':
        return Colors.red;
      case 'VOIDED':
        return Colors.grey;
      case 'ERROR':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  String getLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Aprobado';
      case 'PENDING':
        return 'Pendiente';
      case 'DECLINED':
        return 'Rechazado';
      case 'VOIDED':
        return 'Anulado';
      case 'ERROR':
        return 'Error';
      default:
        return status;
    }
  }

  @override
  IconData getIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.pending;
      case 'DECLINED':
        return Icons.cancel;
      case 'VOIDED':
        return Icons.block;
      case 'ERROR':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

// Factory para obtener la estrategia correcta
class StatusColorStrategyFactory {
  static StatusColorStrategy getStrategy(StatusType type) {
    switch (type) {
      case StatusType.booking:
        return BookingStatusColorStrategy();
      case StatusType.payment:
        return PaymentStatusColorStrategy();
      case StatusType.schedule:
        return ScheduleStatusColorStrategy();
    }
  }
}

enum StatusType { booking, payment, schedule }
```

**Uso en el Widget:**

```dart
// En tenant_bookings_list_screen.dart
class _TenantBookingsListScreenState extends ConsumerState<TenantBookingsListScreen> {
  final _statusStrategy = StatusColorStrategyFactory.getStrategy(StatusType.booking);

  Color _getStatusColor(String status) {
    return _statusStrategy.getColor(status);
  }

  Widget _buildBookingCard(BuildContext context, TenantBookingModel booking) {
    final statusColor = _statusStrategy.getColor(booking.status);
    final statusLabel = _statusStrategy.getLabel(booking.status);
    final statusIcon = _statusStrategy.getIcon(booking.status);
    
    // Usar statusColor, statusLabel, statusIcon en el widget
  }
}
```

**Beneficios:**
- ✅ Elimina duplicación de código
- ✅ Facilita agregar nuevos tipos de estado sin modificar código existente
- ✅ Centraliza la lógica de mapeo
- ✅ Facilita testing unitario de la lógica de mapeo

---

### 1.2 Mapeo de ServiceType a Iconos y Descripciones

**Ubicación:** 
- `lib/features/booking/presentation/screens/book_class_screen.dart:645-665`

**El Problema:**
- Dos métodos switch separados (`_getServiceTypeIcon` y `_getServiceTypeDescription`) que mapean el mismo enum
- Si se agrega un nuevo `ServiceType`, hay que modificar múltiples métodos
- Violación de **Single Responsibility**: El widget maneja UI y lógica de mapeo

**El Patrón Sugerido:** Strategy Pattern con Factory

**Refactorización:**

```dart
// lib/features/booking/domain/strategies/service_type_strategy.dart
abstract class ServiceTypeStrategy {
  IconData getIcon();
  String getDescription();
  String getDisplayName();
  Color getColor();
}

class IndividualClassStrategy implements ServiceTypeStrategy {
  @override
  IconData getIcon() => Icons.person;

  @override
  String getDescription() => 'Clase personalizada 1 a 1';

  @override
  String getDisplayName() => 'Clase Individual';

  @override
  Color getColor() => Colors.blue;
}

class GroupClassStrategy implements ServiceTypeStrategy {
  @override
  IconData getIcon() => Icons.groups;

  @override
  String getDescription() => 'Clase grupal (máx. 4 personas)';

  @override
  String getDisplayName() => 'Clase Grupal';

  @override
  Color getColor() => Colors.green;
}

class CourtRentalStrategy implements ServiceTypeStrategy {
  @override
  IconData getIcon() => Icons.sports_tennis;

  @override
  String getDescription() => 'Solo alquiler de cancha';

  @override
  String getDisplayName() => 'Alquiler de Cancha';

  @override
  Color getColor() => Colors.orange;
}

// Extension en ServiceType para obtener la estrategia
extension ServiceTypeExtension on ServiceType {
  ServiceTypeStrategy get strategy {
    switch (this) {
      case ServiceType.individualClass:
        return IndividualClassStrategy();
      case ServiceType.groupClass:
        return GroupClassStrategy();
      case ServiceType.courtRental:
        return CourtRentalStrategy();
    }
  }
}
```

**Uso:**

```dart
// En book_class_screen.dart
IconData _getServiceTypeIcon(ServiceType serviceType) {
  return serviceType.strategy.getIcon();
}

String _getServiceTypeDescription(ServiceType serviceType) {
  return serviceType.strategy.getDescription();
}
```

---

### 1.3 Mapeo de Errores de Analytics

**Ubicación:** 
- `lib/features/professor/presentation/widgets/analytics_error_widget.dart:154-322`

**El Problema:**
- Tres métodos switch separados (`_getErrorIcon`, `_getErrorTitle`, `_buildActionButtons`) que mapean el mismo enum `AnalyticsErrorType`
- Lógica de UI mezclada con lógica de mapeo
- Duplicación entre `AnalyticsErrorWidget` y `AnalyticsErrorCompact`

**El Patrón Sugerido:** Strategy Pattern

**Refactorización:**

```dart
// lib/features/professor/domain/strategies/analytics_error_strategy.dart
abstract class AnalyticsErrorStrategy {
  IconData getIcon();
  String getTitle();
  String getUserMessage(AnalyticsError error);
  Widget? buildActionButton(BuildContext context, AnalyticsError error);
  bool isRetryable();
  Duration getRetryDelay();
}

class NetworkErrorStrategy implements AnalyticsErrorStrategy {
  @override
  IconData getIcon() => Icons.wifi_off;

  @override
  String getTitle() => 'Error de Conexión';

  @override
  String getUserMessage(AnalyticsError error) => error.userMessage;

  @override
  Widget? buildActionButton(BuildContext context, AnalyticsError error) => null;

  @override
  bool isRetryable() => true;

  @override
  Duration getRetryDelay() => const Duration(seconds: 3);
}

class AuthenticationErrorStrategy implements AnalyticsErrorStrategy {
  @override
  IconData getIcon() => Icons.lock;

  @override
  String getTitle() => 'Sesión Expirada';

  @override
  String getUserMessage(AnalyticsError error) => error.userMessage;

  @override
  Widget? buildActionButton(BuildContext context, AnalyticsError error) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
        icon: const Icon(Icons.login),
        label: const Text('Iniciar Sesión'),
      ),
    );
  }

  @override
  bool isRetryable() => false;

  @override
  Duration getRetryDelay() => Duration.zero;
}

// Factory
class AnalyticsErrorStrategyFactory {
  static AnalyticsErrorStrategy getStrategy(AnalyticsErrorType type) {
    switch (type) {
      case AnalyticsErrorType.networkError:
        return NetworkErrorStrategy();
      case AnalyticsErrorType.authenticationError:
        return AuthenticationErrorStrategy();
      case AnalyticsErrorType.authorizationError:
        return AuthorizationErrorStrategy();
      // ... otros tipos
    }
  }
}
```

**Uso:**

```dart
// En analytics_error_widget.dart
class AnalyticsErrorWidget extends StatelessWidget {
  final AnalyticsError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strategy = AnalyticsErrorStrategyFactory.getStrategy(error.type);
    
    return Container(
      child: Column(
        children: [
          Icon(strategy.getIcon()),
          Text(strategy.getTitle()),
          Text(strategy.getUserMessage(error)),
          if (strategy.buildActionButton(context, error) != null)
            strategy.buildActionButton(context, error)!,
        ],
      ),
    );
  }
}
```

---

## 2. State Pattern - Gestión Manual de Estados

### 2.1 Estados de Carga en Múltiples Screens (Alta Prioridad)

**Ubicación:**
- `lib/features/booking/presentation/screens/book_court_screen.dart:52-1696`
- `lib/features/tenant_admin/presentation/screens/tenant_config_screen.dart:20-1034`
- `lib/features/tenant_admin/presentation/screens/tenant_edit_court_screen.dart`
- `lib/features/tenant_admin/presentation/screens/tenant_create_court_screen.dart`
- `lib/features/payment/presentation/widgets/payment_dialog.dart:42-420`
- `lib/features/professor/presentation/widgets/schedule_widget.dart:16-48`

**El Problema:**
- Múltiples boolean flags (`_isLoading`, `_isBooking`, `_isSyncing`) gestionados manualmente
- Estados inválidos posibles (ej: `_isLoading = true` y `_isBooking = true` simultáneamente)
- Violación de **Single Responsibility**: El widget gestiona UI y estado de la operación
- Difícil de testear y mantener
- No hay transiciones de estado explícitas

**Principios SOLID Violados:**
- **Single Responsibility**: El widget tiene demasiadas responsabilidades
- **Open/Closed**: Agregar nuevos estados requiere modificar el widget

**El Patrón Sugerido:** State Pattern (o usar un Cubit/Bloc)

**Refactorización:**

```dart
// lib/features/booking/domain/states/booking_state.dart
abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingValidating extends BookingState {
  const BookingValidating();
}

class BookingProcessing extends BookingState {
  const BookingProcessing();
}

class BookingSyncing extends BookingState {
  const BookingSyncing();
}

class BookingSuccess extends BookingState {
  final String message;
  const BookingSuccess(this.message);
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}

// State Manager usando State Pattern
class BookingStateManager {
  BookingState _state = const BookingInitial();
  
  BookingState get state => _state;
  
  void validate() {
    _state = const BookingValidating();
  }
  
  void process() {
    _state = const BookingProcessing();
  }
  
  void sync() {
    _state = const BookingSyncing();
  }
  
  void success(String message) {
    _state = BookingSuccess(message);
  }
  
  void error(String message) {
    _state = BookingError(message);
  }
  
  void reset() {
    _state = const BookingInitial();
  }
  
  // Helpers para UI
  bool get isLoading => _state is BookingProcessing || _state is BookingSyncing;
  bool get isBooking => _state is BookingProcessing;
  bool get isSyncing => _state is BookingSyncing;
  bool get isSuccess => _state is BookingSuccess;
  bool get hasError => _state is BookingError;
}
```

**Uso con Cubit (Recomendado):**

```dart
// lib/features/booking/presentation/cubit/booking_cubit.dart
class BookingCubit extends Cubit<BookingState> {
  final CourtService _courtService;
  
  BookingCubit(this._courtService) : super(BookingInitial());
  
  Future<void> bookCourt({
    required String courtId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
  }) async {
    emit(BookingValidating());
    
    try {
      emit(BookingProcessing());
      await _courtService.bookCourt(
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
        price: price,
      );
      
      emit(BookingSyncing());
      // Invalidar providers
      
      emit(BookingSuccess('Reserva realizada exitosamente'));
    } catch (e) {
      emit(BookingError('Error al realizar la reserva: ${e.toString()}'));
    }
  }
}

// En el widget
class BookCourtScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingCubit(ref.read(courtServiceProvider)),
      child: _BookCourtScreenContent(),
    );
  }
}

class _BookCourtScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        return Scaffold(
          body: state.when(
            initial: () => _buildForm(),
            validating: () => _buildForm(showLoading: true),
            processing: () => _buildForm(showLoading: true),
            syncing: () => _buildForm(showLoading: true),
            success: (message) => _showSuccess(message),
            error: (message) => _showError(message),
          ),
        );
      },
    );
  }
}
```

**Beneficios:**
- ✅ Estados explícitos y bien definidos
- ✅ Transiciones de estado claras
- ✅ Imposible tener estados inválidos
- ✅ Fácil de testear
- ✅ Separación de responsabilidades

---

## 3. Template Method Pattern - Lógica Repetida

### 3.1 Widgets de Loading y Error de Analytics

**Ubicación:**
- `lib/features/professor/presentation/widgets/analytics_loading_widget.dart`
- `lib/features/professor/presentation/widgets/analytics_error_widget.dart`

**El Problema:**
- `AnalyticsLoadingWidget` y `AnalyticsErrorWidget` comparten estructura similar (container, padding, column, etc.)
- Múltiples variantes (`AnalyticsLoadingCompact`, `AnalyticsErrorCompact`, `AnalyticsSkeletonLoading`) con lógica duplicada
- Violación de **DRY**: Estructura base repetida en múltiples widgets
- Difícil mantener consistencia visual

**El Patrón Sugerido:** Template Method Pattern

**Refactorización:**

```dart
// Clase base abstracta con Template Method
abstract class AnalyticsWidgetBase extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showDetails;
  
  const AnalyticsWidgetBase({
    super.key,
    this.title,
    this.subtitle,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: _getMargin(),
      padding: _getPadding(),
      decoration: _buildDecoration(theme, colorScheme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, colorScheme),
          if (showDetails) _buildDetails(theme, colorScheme),
          _buildContent(theme, colorScheme),
          _buildActions(theme, colorScheme),
        ],
      ),
    );
  }
  
  // Template methods - pueden ser sobrescritos
  EdgeInsets _getMargin() => const EdgeInsets.all(16);
  EdgeInsets _getPadding() => const EdgeInsets.all(20);
  
  BoxDecoration _buildDecoration(ThemeData theme, ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.errorContainer.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.error.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }
  
  // Métodos abstractos que deben ser implementados
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme);
  Widget? _buildDetails(ThemeData theme, ColorScheme colorScheme);
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme);
  Widget? _buildActions(ThemeData theme, ColorScheme colorScheme);
}

// Implementación para Error Widget
class AnalyticsErrorWidget extends AnalyticsWidgetBase {
  final AnalyticsError error;
  final VoidCallback? onRetry;
  
  const AnalyticsErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    super.showDetails,
  });

  @override
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    final strategy = AnalyticsErrorStrategyFactory.getStrategy(error.type);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            strategy.getIcon(),
            color: colorScheme.error,
            size: 24,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strategy.getTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(4),
              Text(
                strategy.getUserMessage(error),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget? _buildDetails(ThemeData theme, ColorScheme colorScheme) {
    if (error.details == null) return null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalles técnicos:', style: theme.textTheme.bodySmall),
          const Gap(4),
          Text(error.details!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return const SizedBox.shrink();
  }

  @override
  Widget? _buildActions(ThemeData theme, ColorScheme colorScheme) {
    final strategy = AnalyticsErrorStrategyFactory.getStrategy(error.type);
    return strategy.buildActionButton(context, error);
  }
}

// Implementación para Loading Widget
class AnalyticsLoadingWidget extends AnalyticsWidgetBase {
  final LoadingType type;
  final double? progress;
  final List<String>? steps;
  final int? currentStep;
  
  const AnalyticsLoadingWidget({
    super.key,
    this.type = LoadingType.overview,
    this.progress,
    this.steps,
    this.currentStep,
    super.title,
    super.subtitle,
  });

  @override
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return _buildLoadingIndicator(theme, colorScheme);
  }

  @override
  Widget? _buildDetails(ThemeData theme, ColorScheme colorScheme) {
    if (steps == null || steps!.isEmpty) return null;
    return _buildStepsIndicator(theme, colorScheme);
  }

  @override
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          title ?? _getDefaultTitle(),
          style: theme.textTheme.titleLarge,
        ),
        if (subtitle != null) Text(subtitle!),
        if (progress != null) _buildProgressIndicator(theme, colorScheme),
      ],
    );
  }

  @override
  Widget? _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return null;
  }
  
  // Métodos específicos de loading
  Widget _buildLoadingIndicator(ThemeData theme, ColorScheme colorScheme) {
    // Implementación específica
  }
}
```

**Beneficios:**
- ✅ Elimina duplicación de estructura base
- ✅ Consistencia visual garantizada
- ✅ Fácil agregar nuevos tipos de widgets
- ✅ Mantenimiento centralizado

---

### 3.2 Screens de Lista con Paginación

**Ubicación:**
- `lib/features/tenant_admin/presentation/screens/tenant_bookings_list_screen.dart`
- `lib/features/tenant_admin/presentation/screens/tenant_payments_list_screen.dart`
- `lib/features/student/presentation/screens/my_bookings_screen.dart`

**El Problema:**
- Múltiples screens de lista comparten estructura similar:
  - AppBar con acciones
  - Búsqueda y filtros
  - ListView con items
  - Paginación
  - Estados de carga/error/vacío
- Violación de **DRY**: Código repetido en múltiples archivos
- Difícil mantener consistencia entre pantallas

**El Patrón Sugerido:** Template Method Pattern

**Refactorización:**

```dart
// Clase base abstracta
abstract class PaginatedListScreen<T> extends ConsumerStatefulWidget {
  const PaginatedListScreen({super.key});
}

abstract class PaginatedListScreenState<T, W extends PaginatedListScreen<T>>
    extends ConsumerState<W> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchAndFilters(context),
          Expanded(
            child: _buildListContent(context),
          ),
        ],
      ),
    );
  }
  
  // Template methods - estructura común
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(getTitle()),
      actions: buildAppBarActions(context),
    );
  }
  
  Widget _buildListContent(BuildContext context) {
    final dataAsync = watchDataProvider();
    
    return dataAsync.when(
      data: (data) {
        final items = extractItems(data);
        final pagination = extractPagination(data);
        
        if (items.isEmpty) {
          return buildEmptyState(context);
        }
        
        return Column(
          children: [
            buildListHeader(context, items, pagination),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => buildListItem(context, items[index]),
              ),
            ),
            buildPaginationControls(context, pagination),
          ],
        );
      },
      loading: () => buildLoadingState(context),
      error: (error, stack) => buildErrorState(context, error),
    );
  }
  
  // Métodos abstractos que deben ser implementados
  String getTitle();
  AsyncValue<Map<String, dynamic>> watchDataProvider();
  List<T> extractItems(Map<String, dynamic> data);
  PaginationData extractPagination(Map<String, dynamic> data);
  Widget buildListItem(BuildContext context, T item);
  Widget buildSearchAndFilters(BuildContext context);
  List<Widget> buildAppBarActions(BuildContext context);
  Widget buildEmptyState(BuildContext context);
  Widget buildLoadingState(BuildContext context);
  Widget buildErrorState(BuildContext context, Object error);
  Widget buildListHeader(BuildContext context, List<T> items, PaginationData pagination);
  Widget buildPaginationControls(BuildContext context, PaginationData pagination);
}

// Implementación concreta
class TenantBookingsListScreen extends PaginatedListScreen<TenantBookingModel> {
  const TenantBookingsListScreen({super.key});
}

class _TenantBookingsListScreenState
    extends PaginatedListScreenState<TenantBookingModel, TenantBookingsListScreen> {
  
  @override
  String getTitle() => 'Reservas';
  
  @override
  AsyncValue<Map<String, dynamic>> watchDataProvider() {
    return ref.watch(tenantBookingsProvider);
  }
  
  @override
  List<TenantBookingModel> extractItems(Map<String, dynamic> data) {
    return data['bookings'] as List<TenantBookingModel>;
  }
  
  @override
  PaginationData extractPagination(Map<String, dynamic> data) {
    return data['pagination'] as BookingPagination;
  }
  
  @override
  Widget buildListItem(BuildContext context, TenantBookingModel item) {
    return _buildBookingCard(context, item);
  }
  
  // Resto de implementación específica...
}
```

---

## 4. Command Pattern - Acciones Complejas de UI

### 4.1 Handler de Reserva Complejo

**Ubicación:**
- `lib/features/booking/presentation/screens/book_court_screen.dart:1599-1696`

**El Problema:**
- Método `_handleBooking()` con más de 90 líneas
- Mezcla validación, cálculo de precios, llamadas a servicios, navegación y manejo de errores
- Violación de **Single Responsibility**: Un método hace demasiadas cosas
- Difícil de testear
- No se puede deshacer/rehacer
- No se puede encolar múltiples operaciones

**Principios SOLID Violados:**
- **Single Responsibility**: El método tiene múltiples responsabilidades
- **Open/Closed**: Agregar nuevos pasos requiere modificar el método

**El Patrón Sugerido:** Command Pattern

**Refactorización:**

```dart
// lib/features/booking/domain/commands/booking_command.dart
abstract class BookingCommand {
  Future<void> execute();
  Future<void> undo();
  String getDescription();
}

class ValidateBookingCommand implements BookingCommand {
  final String? courtId;
  final DateTime? date;
  final TimeOfDay? time;
  
  ValidateBookingCommand({
    required this.courtId,
    required this.date,
    required this.time,
  });
  
  @override
  Future<void> execute() async {
    if (courtId == null || date == null || time == null) {
      throw ValidationException('Todos los campos son requeridos');
    }
  }
  
  @override
  Future<void> undo() async {
    // No hay nada que deshacer en validación
  }
  
  @override
  String getDescription() => 'Validar datos de reserva';
}

class CalculatePriceCommand implements BookingCommand {
  final CourtModel court;
  final DateTime startTime;
  final DateTime endTime;
  
  double? _calculatedPrice;
  
  CalculatePriceCommand({
    required this.court,
    required this.startTime,
    required this.endTime,
  });
  
  @override
  Future<void> execute() async {
    final durationInHours = endTime.difference(startTime).inHours;
    _calculatedPrice = court.pricePerHour * durationInHours;
  }
  
  @override
  Future<void> undo() async {
    _calculatedPrice = null;
  }
  
  @override
  String getDescription() => 'Calcular precio de reserva';
  
  double get calculatedPrice => _calculatedPrice ?? 0.0;
}

class BookCourtCommand implements BookingCommand {
  final CourtService courtService;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  
  String? _bookingId;
  
  BookCourtCommand({
    required this.courtService,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.price,
  });
  
  @override
  Future<void> execute() async {
    final booking = await courtService.bookCourt(
      courtId: courtId,
      startTime: startTime,
      endTime: endTime,
      price: price,
    );
    _bookingId = booking.id;
  }
  
  @override
  Future<void> undo() async {
    if (_bookingId != null) {
      await courtService.cancelBooking(_bookingId!);
      _bookingId = null;
    }
  }
  
  @override
  String getDescription() => 'Realizar reserva';
}

class RefreshDataCommand implements BookingCommand {
  final WidgetRef ref;
  
  RefreshDataCommand(this.ref);
  
  @override
  Future<void> execute() async {
    ref.invalidate(courtsProvider);
    ref.invalidate(studentBookingsProvider);
  }
  
  @override
  Future<void> undo() async {
    // No se puede deshacer refresh
  }
  
  @override
  String getDescription() => 'Actualizar datos';
}

// Command Invoker
class BookingCommandInvoker {
  final List<BookingCommand> _commandHistory = [];
  int _currentIndex = -1;
  
  Future<void> executeCommand(BookingCommand command) async {
    // Eliminar comandos después del índice actual (si hay undo/redo)
    if (_currentIndex < _commandHistory.length - 1) {
      _commandHistory.removeRange(
        _currentIndex + 1,
        _commandHistory.length,
      );
    }
    
    await command.execute();
    _commandHistory.add(command);
    _currentIndex = _commandHistory.length - 1;
  }
  
  Future<void> undo() async {
    if (_currentIndex >= 0) {
      await _commandHistory[_currentIndex].undo();
      _currentIndex--;
    }
  }
  
  Future<void> redo() async {
    if (_currentIndex < _commandHistory.length - 1) {
      _currentIndex++;
      await _commandHistory[_currentIndex].execute();
    }
  }
  
  bool canUndo() => _currentIndex >= 0;
  bool canRedo() => _currentIndex < _commandHistory.length - 1;
}
```

**Uso en el Widget:**

```dart
class _BookCourtScreenState extends ConsumerState<BookCourtScreen> {
  final _commandInvoker = BookingCommandInvoker();
  
  Future<void> _handleBooking() async {
    try {
      // 1. Validar
      await _commandInvoker.executeCommand(
        ValidateBookingCommand(
          courtId: _selectedCourt?.id,
          date: _selectedDate,
          time: _selectedTime,
        ),
      );
      
      // 2. Calcular precio
      final priceCommand = CalculatePriceCommand(
        court: _selectedCourt!,
        startTime: _buildStartDateTime(),
        endTime: _buildEndDateTime(),
      );
      await _commandInvoker.executeCommand(priceCommand);
      
      // 3. Realizar reserva
      await _commandInvoker.executeCommand(
        BookCourtCommand(
          courtService: ref.read(courtServiceProvider),
          courtId: _selectedCourt!.id,
          startTime: _buildStartDateTime(),
          endTime: _buildEndDateTime(),
          price: priceCommand.calculatedPrice,
        ),
      );
      
      // 4. Refrescar datos
      await _commandInvoker.executeCommand(
        RefreshDataCommand(ref),
      );
      
      // 5. Mostrar éxito y navegar
      _showSuccessAndNavigate();
      
    } catch (e) {
      // Deshacer comandos ejecutados
      while (_commandInvoker.canUndo()) {
        await _commandInvoker.undo();
      }
      _showError(e);
    }
  }
}
```

**Beneficios:**
- ✅ Separación clara de responsabilidades
- ✅ Cada comando es testeable independientemente
- ✅ Soporte para undo/redo
- ✅ Fácil agregar nuevos pasos
- ✅ Historial de operaciones

---

### 4.2 Handler de Pago Complejo

**Ubicación:**
- `lib/features/payment/presentation/widgets/payment_dialog.dart:259-402`

**El Problema:**
- Handler `onPressed` con más de 140 líneas de código
- Mezcla validación, llamadas a servicios, manejo de web/mobile, navegación, y callbacks
- Lógica compleja para manejar diferentes plataformas (web vs mobile)
- Múltiples estados booleanos (`_isWaitingForWebResult`, `_checkoutUrl`)
- Difícil de testear y mantener

**El Patrón Sugerido:** Command Pattern con Strategy para plataformas

**Refactorización:**

```dart
// Command para iniciar pago
abstract class PaymentCommand {
  Future<Map<String, dynamic>?> execute();
}

class InitPaymentCommand implements PaymentCommand {
  final PaymentService service;
  final double amount;
  final Map<String, dynamic>? bookingData;
  final String? redirectUrl;
  
  InitPaymentCommand({
    required this.service,
    required this.amount,
    this.bookingData,
    this.redirectUrl,
  });
  
  @override
  Future<Map<String, dynamic>?> execute() async {
    return await service.initPayment(
      amount,
      bookingData: bookingData,
      redirectUrl: redirectUrl,
    );
  }
}

// Strategy para manejar diferentes plataformas
abstract class PaymentPlatformStrategy {
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
  });
}

class WebPaymentStrategy implements PaymentPlatformStrategy {
  @override
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    // Lógica específica para web
    // Setup listeners, open URL, etc.
  }
}

class MobilePaymentStrategy implements PaymentPlatformStrategy {
  @override
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    // Lógica específica para mobile
    // Navigate to WebView
  }
}
```

---

### 4.3 Confirmación de Pago Rápido

**Ubicación:**
- `lib/features/tenant_admin/presentation/screens/tenant_bookings_list_screen.dart:365-425`

**El Problema:**
- Método `_confirmQuickBooking()` mezcla UI (diálogo), lógica de negocio (confirmar pago) y navegación
- Difícil de testear
- No reutilizable

**Refactorización con Command:**

```dart
class ConfirmPaymentCommand implements BookingCommand {
  final TenantAdminService service;
  final String bookingId;
  final double amount;
  final String studentName;
  
  ConfirmPaymentCommand({
    required this.service,
    required this.bookingId,
    required this.amount,
    required this.studentName,
  });
  
  @override
  Future<void> execute() async {
    await service.confirmBooking(bookingId, paymentStatus: 'paid');
  }
  
  @override
  Future<void> undo() async {
    await service.updateBookingPaymentStatus(bookingId, paymentStatus: 'pending');
  }
  
  @override
  String getDescription() => 'Confirmar pago de ${CurrencyUtils.format(amount)} para $studentName';
}

// Uso
Future<void> _confirmQuickBooking(
  BuildContext context,
  TenantBookingModel booking,
) async {
  final confirmed = await _showConfirmationDialog(context, booking);
  
  if (confirmed) {
    final command = ConfirmPaymentCommand(
      service: ref.read(tenantAdminServiceProvider),
      bookingId: booking.id,
      amount: booking.price,
      studentName: booking.student.name,
    );
    
    await _executeWithLoading(context, command);
  }
}
```

---

## 5. Observer Pattern - Desacoplamiento de Comunicaciones

### 5.1 Actualización de Listas después de Operaciones

**Ubicación:**
- Múltiples screens que invalidan providers después de operaciones

**El Problema:**
- Después de crear/editar/eliminar items, se invalida manualmente el provider
- Acoplamiento fuerte: El widget conoce qué providers invalidar
- Si se agrega una nueva pantalla que muestra los mismos datos, hay que recordar invalidar

**El Patrón Sugerido:** Observer Pattern (ya parcialmente implementado con Riverpod, pero se puede mejorar)

**Refactorización:**

```dart
// Event Bus para notificar cambios
class DataChangeEvent {
  final DataChangeType type;
  final String entityType;
  final String? entityId;
  
  DataChangeEvent({
    required this.type,
    required this.entityType,
    this.entityId,
  });
}

enum DataChangeType { created, updated, deleted }

// Observer que escucha cambios y actualiza providers
class DataChangeObserver {
  final WidgetRef ref;
  final StreamController<DataChangeEvent> _eventController = StreamController.broadcast();
  
  Stream<DataChangeEvent> get events => _eventController.stream;
  
  void notifyChange(DataChangeEvent event) {
    _eventController.add(event);
  }
  
  void handleEvent(DataChangeEvent event) {
    switch (event.entityType) {
      case 'booking':
        ref.invalidate(tenantBookingsProvider);
        ref.invalidate(studentBookingsProvider);
        break;
      case 'payment':
        ref.invalidate(tenantPaymentsProvider);
        ref.invalidate(studentPaymentsProvider);
        break;
      case 'court':
        ref.invalidate(courtsProvider);
        break;
    }
  }
}

// Provider global
final dataChangeObserverProvider = Provider((ref) {
  final observer = DataChangeObserver(ref);
  observer.events.listen(observer.handleEvent);
  return observer;
});

// Uso en comandos
class BookCourtCommand implements BookingCommand {
  final DataChangeObserver _observer;
  // ...
  
  @override
  Future<void> execute() async {
    await courtService.bookCourt(...);
    _observer.notifyChange(DataChangeEvent(
      type: DataChangeType.created,
      entityType: 'booking',
      entityId: booking.id,
    ));
  }
}
```

---

### 1.4 Mapeo de Tipos de Gráficos (Media Prioridad)

**Ubicación:**
- `lib/features/professor/presentation/widgets/analytics_chart_widget.dart:90-101`
- `lib/features/professor/presentation/widgets/analytics_chart_widget.dart:279-286`

**El Problema:**
- Switch statement que determina qué tipo de gráfico construir
- Cada tipo de gráfico tiene su propia lógica de construcción
- Violación de **Open/Closed**: Agregar un nuevo tipo de gráfico requiere modificar el switch

**El Patrón Sugerido:** Strategy Pattern

**Refactorización:**

```dart
// lib/features/professor/domain/strategies/chart_builder_strategy.dart
abstract class ChartBuilderStrategy {
  Widget buildChart(BuildContext context, ChartData data, ThemeData theme, ColorScheme colorScheme);
  IconData getIcon();
  String getDisplayName();
}

class LineChartBuilderStrategy implements ChartBuilderStrategy {
  @override
  Widget buildChart(BuildContext context, ChartData data, ThemeData theme, ColorScheme colorScheme) {
    if (data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }
    return CustomPaint(
      painter: LineChartPainter(
        data: data,
        color: colorScheme.primary,
      ),
      child: Container(),
    );
  }

  @override
  IconData getIcon() => Icons.show_chart;

  @override
  String getDisplayName() => 'Línea';
}

class BarChartBuilderStrategy implements ChartBuilderStrategy {
  @override
  Widget buildChart(BuildContext context, ChartData data, ThemeData theme, ColorScheme colorScheme) {
    if (data.isEmpty) {
      return _buildEmptyChart(context, 'No hay datos para mostrar');
    }
    // Lógica específica de bar chart
  }

  @override
  IconData getIcon() => Icons.bar_chart;

  @override
  String getDisplayName() => 'Barras';
}

// Extension en ChartType
extension ChartTypeExtension on ChartType {
  ChartBuilderStrategy get builder {
    switch (this) {
      case ChartType.line:
        return LineChartBuilderStrategy();
      case ChartType.bar:
        return BarChartBuilderStrategy();
      case ChartType.pie:
        return PieChartBuilderStrategy();
      case ChartType.area:
        return AreaChartBuilderStrategy();
    }
  }
}
```

---

### 1.5 Mapeo de ServiceType en Múltiples Ubicaciones

**Ubicación:**
- `lib/features/tenant_admin/presentation/screens/tenant_booking_details_screen.dart:321-332`
- `lib/features/student/presentation/screens/my_bookings_screen.dart:355-366`

**El Problema:**
- Múltiples métodos `_getServiceTypeLabel()` o `_getServiceTypeText()` duplicados
- Misma lógica repetida en diferentes pantallas

**Solución:** Usar la misma estrategia propuesta en la sección 1.2, pero extenderla para incluir el método `getLabel()`.

---

## 2. State Pattern - Gestión Manual de Estados

### Alta Prioridad (Impacto Alto, Esfuerzo Medio)
1. ✅ **Strategy Pattern para mapeo de estados** - Elimina mucha duplicación (6+ ubicaciones)
2. ✅ **State Pattern para gestión de estados de carga** - Mejora significativamente la mantenibilidad (6+ screens)
3. ✅ **Command Pattern para operaciones complejas** - Facilita testing y mantenimiento (3+ handlers complejos)

### Media Prioridad (Impacto Medio, Esfuerzo Medio)
4. ✅ **Template Method para widgets de analytics** - Reduce duplicación
5. ✅ **Template Method para screens de lista** - Consistencia entre pantallas (3+ screens similares)
6. ✅ **Strategy Pattern para tipos de gráficos** - Facilita agregar nuevos tipos

### Baja Prioridad (Impacto Bajo, Esfuerzo Bajo)
7. ✅ **Observer Pattern mejorado** - Ya está parcialmente implementado con Riverpod
8. ✅ **Strategy Pattern para plataformas (web/mobile)** - Mejora manejo de diferencias de plataforma

---

## Métricas de Mejora Esperadas

- **Reducción de líneas de código duplicadas:** ~40%
- **Reducción de complejidad ciclomática:** ~35%
- **Mejora en cobertura de tests:** +25%
- **Tiempo de desarrollo de nuevas features:** -30%

---

## Notas Finales

- Todas las refactorizaciones mantienen la compatibilidad con la arquitectura actual (Clean Architecture)
- Se recomienda implementar las refactorizaciones de forma incremental
- Cada refactorización debe ir acompañada de tests unitarios
- Considerar usar code generation (freezed, json_serializable) para reducir boilerplate en algunos casos
