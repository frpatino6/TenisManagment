# Core Module

Este módulo contiene las funcionalidades centrales de la aplicación.

## Estructura

### Constants
- **`error_messages.dart`**: Mensajes de error centralizados y user-friendly
- **`timeouts.dart`**: Constantes de timeouts para toda la aplicación

### Exceptions
Jerarquía de excepciones personalizadas:
- `AppException` (base)
- `NetworkException` - Errores de red
- `AuthException` - Errores de autenticación
- `ValidationException` - Errores de validación
- `DomainException` - Errores de lógica de negocio
  - `ScheduleException` - Errores de horarios
  - `TenantException` - Errores de centros

### Logging
- **`logger.dart`**: Sistema de logging estructurado
  - Solo muestra logs en desarrollo por defecto
  - Niveles: debug, info, warning, error, fatal
  - Soporte para contexto estructurado

### Result
- **`result.dart`**: Patrón Result<T> para manejo funcional de errores
  - Alternativa a excepciones para operaciones que pueden fallar
  - Type-safe y explícito

## Ejemplos de Uso

### Logger

```dart
import 'package:tennis_management/core/logging/logger.dart';

class MyService {
  final _logger = AppLogger.tag('MyService');
  
  Future<void> doSomething() async {
    _logger.info('Iniciando operación');
    
    try {
      // ... código
      _logger.debug('Operación completada', {'duration': '100ms'});
    } catch (e, stackTrace) {
      _logger.error('Error en operación', 
        error: e, 
        stackTrace: stackTrace,
        context: {'operation': 'doSomething'},
      );
    }
  }
}

// O usando la extensión:
class MyService {
  Future<void> doSomething() async {
    logger.info('Iniciando operación'); // logger es automático
  }
}
```

### Result<T>

```dart
import 'package:tennis_management/core/result/result.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';

// Opción 1: Usar Result directamente
Future<Result<User>> getUser(String id) async {
  try {
    final user = await api.getUser(id);
    return Result.success(user);
  } on AppException catch (e) {
    return Result.failure(e);
  }
}

// Opción 2: Usar la extensión toResult()
Future<Result<User>> getUser(String id) async {
  return (() => api.getUser(id)).toResult();
}

// Uso del Result
final result = await getUser('123');
result.fold(
  onSuccess: (user) => print('Usuario: $user'),
  onFailure: (error) => print('Error: ${error.message}'),
);

// O con pattern matching
switch (result) {
  case Success(:final value):
    print('Usuario: $value');
  case Failure(:final error):
    print('Error: ${error.message}');
}
```

### Error Messages

```dart
import 'package:tennis_management/core/constants/error_messages.dart';

// Usar constantes directamente
throw AuthException(
  ErrorMessages.notAuthenticated,
  code: 'NOT_AUTHENTICATED',
);

// O usar helpers
throw DomainException(
  ErrorMessages.resourceNotFoundWithId('Usuario', userId),
  code: 'NOT_FOUND',
);
```

