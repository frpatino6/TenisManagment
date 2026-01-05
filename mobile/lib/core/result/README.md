# Result<T> Pattern - Guía de Uso

## ¿Qué es Result<T>?

`Result<T>` es un patrón funcional para manejar errores de forma explícita y type-safe, sin usar excepciones.

## Beneficios

### 1. **Errores Explícitos en la Firma**
```dart
// ❌ Con excepciones: No sabes que puede fallar
Future<User> getUser(String id);

// ✅ Con Result: Es explícito que puede fallar
Future<Result<User>> getUser(String id);
```

### 2. **Type Safety**
El compilador te obliga a manejar ambos casos (éxito y error):
```dart
final result = await getUser('123');
// Debes manejar ambos casos explícitamente
result.fold(
  onSuccess: (user) => print('Usuario: $user'),
  onFailure: (error) => print('Error: ${error.message}'),
);
```

### 3. **Composición Funcional**
Puedes encadenar operaciones de forma segura:
```dart
final result = await getUser('123')
  .map((user) => user.email)
  .mapAsync((email) => sendEmail(email))
  .onFailure((error) => logger.error('Error', error: error));
```

### 4. **No Rompe el Flujo de Control**
Las excepciones "saltan" el código, Result permite manejo explícito:
```dart
// Con excepciones: Si falla, salta todo el código siguiente
try {
  final user = await getUser('123');
  processUser(user); // Nunca se ejecuta si getUser falla
} catch (e) {
  handleError(e);
}

// Con Result: Tú controlas el flujo
final result = await getUser('123');
if (result.isSuccess) {
  processUser(result.valueOrNull!);
} else {
  handleError(result.errorOrNull!);
}
```

### 5. **Mejor para Errores Esperados**
Las excepciones son para casos excepcionales, Result es para errores esperados:
```dart
// ❌ Excepción: Para casos realmente excepcionales
if (user == null) {
  throw AuthException.notAuthenticated(); // Caso excepcional
}

// ✅ Result: Para errores esperados (validación, búsquedas, etc.)
Future<Result<User?>> findUser(String email) async {
  final user = await db.findUser(email);
  if (user == null) {
    return Result.failure(UserNotFoundException());
  }
  return Result.success(user);
}
```

## ¿Cuándo Usar Result<T>?

### ✅ **USAR Result<T> cuando:**

1. **Errores Esperados y Comunes**
   - Validación de datos
   - Búsquedas que pueden no encontrar resultados
   - Operaciones que fallan frecuentemente
   - Validación de formularios

2. **Operaciones que Retornan Opcionales**
   ```dart
   // Mejor que retornar null
   Future<Result<User?>> findUser(String email);
   ```

3. **Cuando Necesitas Composición**
   ```dart
   // Encadenar múltiples operaciones
   final result = await validateInput(input)
     .mapAsync((valid) => processData(valid))
     .mapAsync((processed) => saveData(processed));
   ```

4. **APIs Públicas o Librerías**
   - Más claro para el consumidor
   - Documenta explícitamente los errores posibles

### ❌ **NO USAR Result<T> cuando:**

1. **Errores Realmente Excepcionales**
   ```dart
   // ✅ Usar excepción: Caso excepcional
   if (user == null) {
     throw AuthException.notAuthenticated();
   }
   ```

2. **Errores de Programación (Bugs)**
   ```dart
   // ✅ Usar excepción: Error de programación
   if (list.isEmpty) {
     throw StateError('Lista no puede estar vacía');
   }
   ```

3. **Cuando el Código Actual Funciona Bien**
   - Si ya usas excepciones y funciona, no es necesario cambiar
   - Result es una alternativa, no un reemplazo obligatorio

## Ejemplos Prácticos

### Ejemplo 1: Validación de Formulario
```dart
// ✅ BUENO: Usar Result para validación
Future<Result<FormData>> validateForm(Map<String, dynamic> data) async {
  final errors = <String, String>{};
  
  if (data['email'] == null || data['email'].isEmpty) {
    errors['email'] = 'Email requerido';
  } else if (!isValidEmail(data['email'])) {
    errors['email'] = 'Email inválido';
  }
  
  if (errors.isNotEmpty) {
    return Result.failure(ValidationException(
      'Errores de validación',
      fieldErrors: errors,
    ));
  }
  
  return Result.success(FormData.fromMap(data));
}

// Uso:
final result = await validateForm(formData);
result.fold(
  onSuccess: (data) => submitForm(data),
  onFailure: (error) => showErrors(error),
);
```

### Ejemplo 2: Búsqueda que Puede Fallar
```dart
// ✅ BUENO: Búsqueda que puede no encontrar
Future<Result<Student>> findStudent(String id) async {
  try {
    final student = await db.findStudent(id);
    if (student == null) {
      return Result.failure(
        DomainException.notFound(resource: 'Estudiante', id: id),
      );
    }
    return Result.success(student);
  } on AppException catch (e) {
    return Result.failure(e);
  }
}

// Uso:
final result = await findStudent('123');
switch (result) {
  case Success(:final value):
    showStudentProfile(value);
  case Failure(:final error):
    showError(error.message);
}
```

### Ejemplo 3: Operaciones que Pueden Fallar
```dart
// ✅ BUENO: Operación que puede fallar frecuentemente
Future<Result<Booking>> createBooking(BookingData data) async {
  // Validar disponibilidad
  final available = await checkAvailability(data);
  if (!available) {
    return Result.failure(
      ScheduleException.conflict(message: 'Horario no disponible'),
    );
  }
  
  // Crear reserva
  try {
    final booking = await db.createBooking(data);
    return Result.success(booking);
  } on AppException catch (e) {
    return Result.failure(e);
  }
}

// Uso:
final result = await createBooking(bookingData);
result
  .onSuccess((booking) => showSuccess('Reserva creada'))
  .onFailure((error) => showError(error.message));
```

## Comparación: Excepciones vs Result<T>

### Con Excepciones (Actual)
```dart
Future<User> getUser(String id) async {
  final user = await api.getUser(id);
  if (user == null) {
    throw DomainException.notFound(resource: 'Usuario', id: id);
  }
  return user;
}

// Uso:
try {
  final user = await getUser('123');
  processUser(user);
} catch (e) {
  handleError(e);
}
```

### Con Result<T>
```dart
Future<Result<User>> getUser(String id) async {
  final user = await api.getUser(id);
  if (user == null) {
    return Result.failure(
      DomainException.notFound(resource: 'Usuario', id: id),
    );
  }
  return Result.success(user);
}

// Uso:
final result = await getUser('123');
result.fold(
  onSuccess: (user) => processUser(user),
  onFailure: (error) => handleError(error),
);
```

## Recomendación para este Proyecto

### Mantener Excepciones Para:
- ✅ Autenticación (casos excepcionales)
- ✅ Errores de red críticos
- ✅ Errores de programación
- ✅ Código existente que funciona bien

### Considerar Result<T> Para:
- ✅ Validación de formularios
- ✅ Búsquedas opcionales
- ✅ Operaciones de negocio que pueden fallar frecuentemente
- ✅ Nuevas features donde quieras ser más explícito

## Conclusión

**Result<T> es una herramienta adicional, no un reemplazo obligatorio.**

- **Usa excepciones** para casos excepcionales y errores críticos
- **Usa Result<T>** para errores esperados y cuando necesites composición funcional
- **Ambos pueden coexistir** en el mismo proyecto

El código actual con excepciones funciona bien. Result<T> está disponible si quieres usarlo en casos específicos donde aporte más claridad.

