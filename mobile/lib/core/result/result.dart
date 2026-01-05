import '../exceptions/app_exception.dart';
import '../exceptions/network_exception.dart';

/// Result pattern para manejo funcional de errores
/// 
/// Permite manejar errores de forma explícita sin usar excepciones
/// Útil para operaciones que pueden fallar de forma esperada
sealed class Result<T> {
  const Result();

  /// Crea un Result exitoso
  const factory Result.success(T value) = Success<T>;

  /// Crea un Result con error
  const factory Result.failure(AppException error) = Failure<T>;

  /// Verifica si el resultado es exitoso
  bool get isSuccess => this is Success<T>;

  /// Verifica si el resultado es un error
  bool get isFailure => this is Failure<T>;

  /// Obtiene el valor si es exitoso, null si es error
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// Obtiene el error si es fallo, null si es exitoso
  AppException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Ejecuta una función si es exitoso
  Result<U> map<U>(U Function(T value) mapper) {
    return switch (this) {
      Success<T>(:final value) => Result.success(mapper(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }

  /// Ejecuta una función asíncrona si es exitoso
  Future<Result<U>> mapAsync<U>(Future<U> Function(T value) mapper) async {
    return switch (this) {
      Success<T>(:final value) => Result.success(await mapper(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }

  /// Ejecuta una función si es error
  Result<T> mapError(AppException Function(AppException error) mapper) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(:final error) => Result.failure(mapper(error)),
    };
  }

  /// Ejecuta una función si es exitoso, otra si es error
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }

  /// Ejecuta una función si es exitoso
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success<T>(:final value)) {
      action(value);
    }
    return this;
  }

  /// Ejecuta una función si es error
  Result<T> onFailure(void Function(AppException error) action) {
    if (this case Failure<T>(:final error)) {
      action(error);
    }
    return this;
  }

  /// Lanza la excepción si es error, retorna el valor si es exitoso
  T getOrThrow() {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>(:final error) => throw error,
    };
  }

  /// Retorna el valor si es exitoso, o un valor por defecto si es error
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>() => defaultValue,
    };
  }
}

/// Result exitoso
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Result con error
final class Failure<T> extends Result<T> {
  final AppException error;

  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Extension para convertir excepciones a Result
extension ResultExtension<T> on Future<T> Function() {
  /// Ejecuta la función y convierte excepciones a Result
  Future<Result<T>> toResult() async {
    try {
      final value = await this();
      return Result.success(value);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      // Convierte excepciones genéricas a NetworkException
      return Result.failure(
        NetworkException(
          e.toString(),
          code: 'UNKNOWN_ERROR',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Extension para convertir Result a excepciones (para compatibilidad)
extension ResultToException<T> on Result<T> {
  /// Convierte el Result a un Future que lanza excepción si es error
  Future<T> toFuture() async {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>(:final error) => throw error,
    };
  }
}

