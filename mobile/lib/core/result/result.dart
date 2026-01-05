import '../exceptions/app_exception.dart';
import '../exceptions/network_exception.dart';

/// Result pattern for functional error handling
/// 
/// Allows explicit error handling without using exceptions
/// Useful for operations that can fail in an expected way
sealed class Result<T> {
  const Result();

  /// Creates a successful Result
  const factory Result.success(T value) = Success<T>;

  /// Creates a Result with error
  const factory Result.failure(AppException error) = Failure<T>;

  /// Checks if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Checks if the result is an error
  bool get isFailure => this is Failure<T>;

  /// Gets the value if successful, null if error
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// Gets the error if failure, null if successful
  AppException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Executes a function if successful
  Result<U> map<U>(U Function(T value) mapper) {
    return switch (this) {
      Success<T>(:final value) => Result.success(mapper(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }

  /// Executes an async function if successful
  Future<Result<U>> mapAsync<U>(Future<U> Function(T value) mapper) async {
    return switch (this) {
      Success<T>(:final value) => Result.success(await mapper(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }

  /// Executes a function if error
  Result<T> mapError(AppException Function(AppException error) mapper) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(:final error) => Result.failure(mapper(error)),
    };
  }

  /// Executes a function if successful, another if error
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }

  /// Executes a function if successful
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success<T>(:final value)) {
      action(value);
    }
    return this;
  }

  /// Executes a function if error
  Result<T> onFailure(void Function(AppException error) action) {
    if (this case Failure<T>(:final error)) {
      action(error);
    }
    return this;
  }

  /// Throws the exception if error, returns the value if successful
  T getOrThrow() {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>(:final error) => throw error,
    };
  }

  /// Returns the value if successful, or a default value if error
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>() => defaultValue,
    };
  }
}

/// Successful Result
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

/// Result with error
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

/// Extension to convert exceptions to Result
extension ResultExtension<T> on Future<T> Function() {
  /// Executes the function and converts exceptions to Result
  Future<Result<T>> toResult() async {
    try {
      final value = await this();
      return Result.success(value);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      // Converts generic exceptions to NetworkException
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

/// Extension to convert Result to exceptions (for compatibility)
extension ResultToException<T> on Result<T> {
  /// Converts the Result to a Future that throws exception if error
  Future<T> toFuture() async {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>(:final error) => throw error,
    };
  }
}

