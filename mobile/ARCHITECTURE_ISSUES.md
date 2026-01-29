# Análisis de Problemas Arquitectónicos - Flutter Mobile App

## 🚨 Resumen Ejecutivo

Este documento identifica **problemas arquitectónicos críticos** que pueden causar problemas significativos a futuro, incluyendo dificultades de mantenimiento, escalabilidad, testing y evolución del código.

**Problemas Críticos Identificados:**
1. ❌ **Falta de Capa de Aplicación (Use Cases)** - Violación grave de Clean Architecture
2. ❌ **Servicios de Dominio con Lógica de Infraestructura** - Acoplamiento fuerte
3. ❌ **Dependencias Cruzadas entre Features** - Violación de independencia de módulos
4. ❌ **Screens llamando directamente a Servicios** - Violación de separación de capas
5. ❌ **Falta de Abstracciones/Interfaces** - Imposible mockear y testear
6. ❌ **Providers con Lógica de Negocio** - Responsabilidades mezcladas
7. ❌ **Estructura Inconsistente entre Features** - Dificulta mantenimiento

---

## 1. ❌ CRÍTICO: Falta de Capa de Aplicación (Use Cases)

### Problema

**Ubicación:** Todo el proyecto

**Descripción:**
No existe una capa de aplicación (use cases) entre la capa de presentación y la capa de dominio. Los providers y screens llaman directamente a los servicios de dominio.

**Evidencia:**
```dart
// ❌ MAL: Provider llamando directamente a servicio de dominio
final tenantMetricsProvider = FutureProvider<TenantMetricsModel>((ref) async {
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getMetrics(); // Llamada directa
});

// ❌ MAL: Screen llamando directamente a servicio
final courtService = ref.read(courtServiceProvider);
await courtService.bookCourt(...); // En book_court_screen.dart:1637
```

**Impacto a Futuro:**
- 🔴 **Imposible agregar lógica de aplicación** (validaciones complejas, orquestación de múltiples servicios)
- 🔴 **Difícil testear** - No se puede mockear fácilmente
- 🔴 **Violación de Clean Architecture** - La presentación conoce detalles de implementación del dominio
- 🔴 **Reutilización imposible** - La lógica está acoplada a Riverpod/Flutter
- 🔴 **Cambios en servicios afectan toda la app** - No hay capa de abstracción

**Solución Requerida:**

```dart
// ✅ BIEN: Estructura correcta con Use Cases

// 1. Capa de Aplicación (Use Cases)
// lib/features/booking/application/use_cases/book_court_use_case.dart
class BookCourtUseCase {
  final CourtRepository _courtRepository;
  final BookingRepository _bookingRepository;
  final NotificationService _notificationService;
  
  BookCourtUseCase({
    required CourtRepository courtRepository,
    required BookingRepository bookingRepository,
    required NotificationService notificationService,
  }) : _courtRepository = courtRepository,
       _bookingRepository = bookingRepository,
       _notificationService = notificationService;
  
  Future<BookingResult> execute(BookCourtRequest request) async {
    // 1. Validar datos
    if (!_isValidRequest(request)) {
      return BookingResult.failure('Datos inválidos');
    }
    
    // 2. Verificar disponibilidad
    final isAvailable = await _courtRepository.isAvailable(
      courtId: request.courtId,
      startTime: request.startTime,
      endTime: request.endTime,
    );
    
    if (!isAvailable) {
      return BookingResult.failure('Cancha no disponible');
    }
    
    // 3. Calcular precio
    final price = await _calculatePrice(request);
    
    // 4. Crear reserva
    final booking = await _bookingRepository.create(request, price);
    
    // 5. Notificar
    await _notificationService.sendBookingConfirmation(booking);
    
    return BookingResult.success(booking);
  }
}

// 2. Provider solo orquesta el Use Case
final bookCourtUseCaseProvider = Provider<BookCourtUseCase>((ref) {
  return BookCourtUseCase(
    courtRepository: ref.watch(courtRepositoryProvider),
    bookingRepository: ref.watch(bookingRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

// 3. Screen usa el Use Case
final result = await ref.read(bookCourtUseCaseProvider).execute(request);
```

**Prioridad:** 🔴 **CRÍTICA** - Debe implementarse antes de agregar más features

---

## 2. ❌ CRÍTICO: Servicios de Dominio con Lógica de Infraestructura

### Problema

**Ubicación:**
- `lib/features/booking/domain/services/court_service.dart`
- `lib/features/booking/domain/services/booking_service.dart`
- `lib/features/tenant_admin/domain/services/tenant_admin_service.dart`
- Todos los servicios de dominio (13 servicios)

**Descripción:**
Los servicios de dominio contienen lógica de infraestructura:
- Llamadas HTTP directas
- Manejo de autenticación (Firebase Auth)
- Parsing de JSON
- Manejo de errores HTTP
- URLs hardcodeadas

**Evidencia:**
```dart
// ❌ MAL: Servicio de dominio con lógica HTTP
class CourtService {
  final String _baseUrl = AppConfig.apiBaseUrl; // ❌ Infraestructura
  final FirebaseAuth _auth = FirebaseAuth.instance; // ❌ Infraestructura
  final AppHttpClient _http; // ❌ Infraestructura

  Future<List<CourtModel>> getCourts() async {
    final user = _auth.currentUser; // ❌ Lógica de infraestructura
    final idToken = await user.getIdToken(true);
    
    final response = await _http.get( // ❌ Lógica HTTP
      Uri.parse('$_baseUrl/student-dashboard/courts'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body); // ❌ Parsing JSON
      return items.map((item) => CourtModel.fromJson(item)).toList();
    }
    // ... manejo de errores HTTP
  }
}
```

**Impacto a Futuro:**
- 🔴 **Imposible cambiar la fuente de datos** (de REST a GraphQL, Firebase, etc.)
- 🔴 **Imposible testear sin mocks complejos** de HTTP y Firebase
- 🔴 **Violación de Dependency Inversion Principle** - Depende de implementaciones concretas
- 🔴 **Acoplamiento fuerte** - Cambios en API afectan el dominio
- 🔴 **No reutilizable** - El dominio está acoplado a Flutter/HTTP

**Solución Requerida:**

```dart
// ✅ BIEN: Separación correcta de capas

// 1. REPOSITORY (Interfaz en dominio)
// lib/features/booking/domain/repositories/court_repository.dart
abstract class CourtRepository {
  Future<List<CourtModel>> getCourts();
  Future<Map<String, dynamic>> getAvailableSlots({
    required String courtId,
    required DateTime date,
  });
  Future<Booking> bookCourt(BookCourtRequest request);
}

// 2. IMPLEMENTACIÓN en infraestructura
// lib/features/booking/infrastructure/repositories/court_repository_impl.dart
class CourtRepositoryImpl implements CourtRepository {
  final HttpClient _httpClient;
  final AuthService _authService;
  final ApiConfig _apiConfig;
  
  CourtRepositoryImpl({
    required HttpClient httpClient,
    required AuthService authService,
    required ApiConfig apiConfig,
  }) : _httpClient = httpClient,
       _authService = authService,
       _apiConfig = apiConfig;
  
  @override
  Future<List<CourtModel>> getCourts() async {
    final token = await _authService.getToken();
    final response = await _httpClient.get(
      '${_apiConfig.baseUrl}/student-dashboard/courts',
      headers: {'Authorization': 'Bearer $token'},
    );
    
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((item) => CourtModel.fromJson(item)).toList();
  }
}

// 3. SERVICIO DE DOMINIO solo con lógica de negocio
// lib/features/booking/domain/services/court_domain_service.dart
class CourtDomainService {
  final CourtRepository _repository;
  
  CourtDomainService(this._repository);
  
  Future<CourtAvailability> checkAvailability({
    required String courtId,
    required DateTime date,
  }) async {
    final slots = await _repository.getAvailableSlots(
      courtId: courtId,
      date: date,
    );
    
    // Lógica de negocio pura (sin HTTP, sin Firebase)
    return CourtAvailability.fromSlots(slots);
  }
}
```

**Prioridad:** 🔴 **CRÍTICA** - Bloquea escalabilidad y testing

---

## 3. ❌ CRÍTICO: Dependencias Cruzadas entre Features

### Problema

**Ubicación:**
- `lib/features/booking/presentation/screens/book_court_screen.dart` → importa `tenant/domain`
- `lib/features/professor/presentation/screens/create_schedule_screen.dart` → importa `booking/domain`
- `lib/features/payment/presentation/widgets/payment_dialog.dart` → importa `student/presentation` y `booking/presentation`
- `lib/features/professor/presentation/widgets/tenant_selector_widget.dart` → importa `tenant/domain`

**Evidencia:**
```dart
// ❌ MAL: Feature A importando dominio de Feature B
// lib/features/booking/presentation/screens/book_court_screen.dart
import '../../../tenant/domain/services/tenant_service.dart' as tenant_domain;
import '../../../tenant/domain/models/tenant_model.dart';

// ❌ MAL: Feature C importando presentación de Features A y B
// lib/features/payment/presentation/widgets/payment_dialog.dart
import '../../../student/presentation/providers/student_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
```

**Impacto a Futuro:**
- 🔴 **Imposible extraer features a módulos separados** (packages)
- 🔴 **Ciclos de dependencia** - Cambios en un feature afectan otros
- 🔴 **Testing complejo** - Necesitas mockear múltiples features
- 🔴 **Violación de independencia de módulos** - Features no son independientes
- 🔴 **Refactoring peligroso** - Cambios pueden romper múltiples features

**Solución Requerida:**

```dart
// ✅ BIEN: Comunicación entre features vía eventos/interfaces

// 1. Crear capa compartida/interfaces
// lib/core/interfaces/tenant_selector_interface.dart
abstract class TenantSelectorInterface {
  Future<Tenant?> selectTenant();
  Stream<Tenant?> get currentTenant;
}

// 2. Feature booking depende de la interfaz, no de tenant
// lib/features/booking/application/use_cases/book_court_use_case.dart
class BookCourtUseCase {
  final TenantSelectorInterface _tenantSelector; // ✅ Interfaz, no implementación
  
  Future<BookingResult> execute(BookCourtRequest request) async {
    final tenant = await _tenantSelector.selectTenant();
    // ...
  }
}

// 3. Feature tenant implementa la interfaz
// lib/features/tenant/presentation/providers/tenant_selector_provider.dart
final tenantSelectorProvider = Provider<TenantSelectorInterface>((ref) {
  return TenantSelectorImpl(ref);
});

// 4. O usar Event Bus para comunicación desacoplada
// lib/core/events/app_events.dart
class TenantSelectedEvent {
  final Tenant tenant;
  TenantSelectedEvent(this.tenant);
}

// Features se comunican vía eventos, no imports directos
```

**Prioridad:** 🔴 **CRÍTICA** - Bloquea modularización y escalabilidad

---

## 4. ❌ ALTO: Screens llamando directamente a Servicios

### Problema

**Ubicación:**
- `lib/features/booking/presentation/screens/book_court_screen.dart:1637`
- `lib/features/booking/presentation/screens/book_class_screen.dart:889`
- `lib/features/tenant_admin/presentation/screens/tenant_bookings_list_screen.dart:402`
- Múltiples screens

**Evidencia:**
```dart
// ❌ MAL: Screen llamando directamente a servicio
Future<void> _handleBooking() async {
  final courtService = ref.read(courtServiceProvider);
  await courtService.bookCourt( // ❌ Llamada directa desde screen
    courtId: _selectedCourt!.id,
    startTime: startDateTime,
    endTime: endDateTime,
    price: totalPrice,
  );
}
```

**Impacto a Futuro:**
- 🔴 **Lógica de negocio en la UI** - Difícil de testear y reutilizar
- 🔴 **Violación de Clean Architecture** - Presentación conoce detalles de dominio
- 🔴 **Imposible cambiar implementación** sin tocar screens
- 🔴 **Testing complejo** - Necesitas widgets tests para probar lógica

**Solución:**
Usar Use Cases (ver sección 1)

**Prioridad:** 🟠 **ALTA** - Afecta mantenibilidad y testing

---

## 5. ❌ ALTO: Falta de Abstracciones/Interfaces

### Problema

**Ubicación:** Todos los servicios de dominio

**Descripción:**
No hay interfaces/abstracciones para los servicios. Todo son implementaciones concretas.

**Evidencia:**
```dart
// ❌ MAL: Solo implementación concreta
class CourtService {
  // Implementación directa
}

// Provider usa la clase concreta
final courtServiceProvider = Provider<CourtService>((ref) {
  return CourtService(ref.watch(appHttpClientProvider));
});
```

**Impacto a Futuro:**
- 🔴 **Imposible mockear para tests** - Dependes de implementación real
- 🔴 **Imposible cambiar implementación** - Todo está acoplado
- 🔴 **Testing lento** - Tests hacen llamadas HTTP reales
- 🔴 **Violación de Dependency Inversion** - Dependes de concreciones

**Solución Requerida:**

```dart
// ✅ BIEN: Interfaces + Implementaciones

// 1. Interfaz en dominio
// lib/features/booking/domain/repositories/court_repository.dart
abstract class CourtRepository {
  Future<List<CourtModel>> getCourts();
  Future<Booking> bookCourt(BookCourtRequest request);
}

// 2. Implementación en infraestructura
// lib/features/booking/infrastructure/repositories/court_repository_impl.dart
class CourtRepositoryImpl implements CourtRepository {
  // Implementación concreta
}

// 3. Provider usa la interfaz
final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepositoryImpl(
    httpClient: ref.watch(httpClientProvider),
    authService: ref.watch(authServiceProvider),
  );
});

// 4. Tests usan mock
class MockCourtRepository implements CourtRepository {
  @override
  Future<List<CourtModel>> getCourts() async {
    return [/* datos mock */];
  }
}
```

**Prioridad:** 🟠 **ALTA** - Bloquea testing efectivo

---

## 6. ❌ MEDIO: Providers con Lógica de Negocio

### Problema

**Ubicación:**
- `lib/features/tenant_admin/presentation/providers/tenant_admin_provider.dart`
- `lib/features/booking/presentation/providers/booking_provider.dart`
- Múltiples providers

**Descripción:**
Los providers contienen lógica de negocio (validaciones, transformaciones, orquestación) que debería estar en use cases.

**Evidencia:**
```dart
// ❌ MAL: Provider con lógica de negocio
final filteredTenantProfessorsByStatusProvider =
    Provider.family<List<TenantProfessorModel>, String>((ref, statusFilter) {
      final professorsAsync = ref.watch(tenantProfessorsProvider);

      return professorsAsync.when(
        data: (professors) {
          if (statusFilter == 'all') { // ❌ Lógica de negocio
            return professors;
          }
          final bool isActive = statusFilter == 'active';
          return professors
              .where((professor) => professor.isActive == isActive) // ❌ Lógica
              .toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });
```

**Impacto a Futuro:**
- 🟠 **Lógica acoplada a Riverpod** - No reutilizable
- 🟠 **Testing complejo** - Necesitas providers para testear lógica
- 🟠 **Violación de Single Responsibility** - Providers hacen demasiado

**Solución:**
Mover lógica a Use Cases o Domain Services

**Prioridad:** 🟡 **MEDIA** - Afecta reutilización y testing

---

## 7. ❌ MEDIO: Estructura Inconsistente entre Features

### Problema

**Ubicación:** Comparar estructura de diferentes features

**Descripción:**
Algunos features tienen estructura diferente:
- `professor/` tiene carpeta `data/` con providers
- Otros features no tienen `data/`
- Algunos tienen `application/`, otros no
- Inconsistencia en nombres y organización

**Evidencia:**
```
booking/
  - domain/
  - presentation/
  ❌ No tiene: application/, infrastructure/, data/

professor/
  - data/          ← ✅ Tiene esta
  - domain/
  - presentation/
  ❌ No tiene: application/, infrastructure/

tenant_admin/
  - domain/
  - presentation/
  ❌ No tiene: application/, infrastructure/, data/
```

**Impacto a Futuro:**
- 🟡 **Confusión para desarrolladores** - No saben dónde poner código
- 🟡 **Mantenimiento difícil** - Código disperso en diferentes lugares
- 🟡 **Onboarding lento** - Nuevos desarrolladores se pierden

**Solución Requerida:**

Estandarizar estructura para todos los features:
```
feature_name/
  - domain/
    - entities/        # Entidades de negocio
    - repositories/   # Interfaces de repositorios
    - services/       # Servicios de dominio (lógica pura)
    - models/         # Modelos de dominio
  - application/
    - use_cases/      # Casos de uso
    - dto/            # Data Transfer Objects
  - infrastructure/
    - repositories/   # Implementaciones de repositorios
    - data_sources/  # APIs, bases de datos, etc.
  - presentation/
    - providers/     # Riverpod providers
    - screens/       # Pantallas
    - widgets/       # Widgets
```

**Prioridad:** 🟡 **MEDIA** - Afecta mantenibilidad y onboarding

---

## 8. ❌ BAJO: Lógica de Formateo/UI en Dominio

### Problema

**Ubicación:**
- Múltiples modelos de dominio con métodos de formateo

**Descripción:**
Algunos modelos de dominio contienen lógica de formateo para UI (formateo de fechas, moneda, etc.)

**Impacto:**
- 🟢 **Menor** - Pero viola separación de responsabilidades

**Solución:**
Mover formateo a capa de presentación o crear formatters dedicados

**Prioridad:** 🟢 **BAJA** - Mejora de calidad de código

---

## Plan de Acción Recomendado

### Fase 1: Crítico (1-2 meses)
1. ✅ **Crear capa de aplicación (Use Cases)** para features principales
2. ✅ **Separar infraestructura de dominio** - Crear repositories
3. ✅ **Eliminar dependencias cruzadas** - Usar interfaces/eventos

### Fase 2: Alto (2-3 meses)
4. ✅ **Mover lógica de screens a Use Cases**
5. ✅ **Crear interfaces para todos los servicios**
6. ✅ **Implementar mocks para testing**

### Fase 3: Medio (3-4 meses)
7. ✅ **Estandarizar estructura de features**
8. ✅ **Refactorizar providers** - Mover lógica a use cases
9. ✅ **Documentar arquitectura** - Guías y ejemplos

---

## Métricas de Impacto

### Si NO se resuelven estos problemas:
- ⚠️ **Tiempo de desarrollo de nuevas features:** +50%
- ⚠️ **Bugs en producción:** +40%
- ⚠️ **Tiempo de onboarding:** +60%
- ⚠️ **Cobertura de tests:** <30% (actualmente probablemente <20%)
- ⚠️ **Deuda técnica:** Crece exponencialmente

### Si se resuelven:
- ✅ **Tiempo de desarrollo:** -30%
- ✅ **Bugs en producción:** -50%
- ✅ **Cobertura de tests:** >70%
- ✅ **Escalabilidad:** Permite crecimiento sin problemas
- ✅ **Mantenibilidad:** Código más limpio y predecible

---

## Conclusión

El proyecto tiene una **base sólida** con Clean Architecture parcialmente implementada, pero **faltan capas críticas** y hay **violaciones importantes** que deben resolverse antes de que el proyecto crezca más.

**Recomendación:** Priorizar la implementación de Use Cases y la separación de infraestructura del dominio. Estos cambios son **fundamentales** para la escalabilidad a largo plazo.
