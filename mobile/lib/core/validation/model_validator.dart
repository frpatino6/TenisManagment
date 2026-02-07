import '../exceptions/validation_exception.dart';

/// Helper class for model validation
/// Provides common validation methods for models
class ModelValidator {
  /// Validates that a value is not negative
  /// Throws ValidationException if value is negative
  static double validateNonNegative(
    double value,
    String fieldName, {
    double? min,
    double? max,
  }) {
    assert(value >= 0, '$fieldName must be non-negative, got $value');

    if (value < 0) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'No puede ser negativo',
      );
    }

    if (min != null && value < min) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'Debe ser al menos $min',
      );
    }

    if (max != null && value > max) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'No puede ser mayor que $max',
      );
    }

    return value;
  }

  /// Validates that an integer is not negative
  static int validateNonNegativeInt(
    int value,
    String fieldName, {
    int? min,
    int? max,
  }) {
    assert(value >= 0, '$fieldName must be non-negative, got $value');

    if (value < 0) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'No puede ser negativo',
      );
    }

    if (min != null && value < min) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'Debe ser al menos $min',
      );
    }

    if (max != null && value > max) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'No puede ser mayor que $max',
      );
    }

    return value;
  }

  /// Validates a rating value (0.0 to 5.0)
  static double validateRating(double value, String fieldName) {
    assert(
      value >= 0.0 && value <= 5.0,
      '$fieldName must be between 0.0 and 5.0, got $value',
    );

    if (value < 0.0 || value > 5.0) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'Debe estar entre 0.0 y 5.0',
      );
    }

    return value;
  }

  /// Validates that a string is not empty
  static String validateNonEmpty(String value, String fieldName) {
    assert(value.isNotEmpty, '$fieldName must not be empty');

    if (value.isEmpty) {
      throw ValidationException.missingRequiredField(field: fieldName);
    }

    return value;
  }

  /// Validates email format (basic validation)
  static String validateEmail(String value, String fieldName) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    assert(emailRegex.hasMatch(value), '$fieldName must be a valid email');

    if (!emailRegex.hasMatch(value)) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'Formato de email inválido',
      );
    }

    return value;
  }

  /// Validates that endTime is after startTime
  static void validateTimeRange(
    DateTime startTime,
    DateTime endTime,
    String fieldName,
  ) {
    assert(
      endTime.isAfter(startTime),
      '$fieldName: endTime must be after startTime',
    );

    if (!endTime.isAfter(startTime)) {
      throw ValidationException.invalidField(
        field: fieldName,
        reason: 'La hora de fin debe ser posterior a la hora de inicio',
      );
    }
  }

  /// Validates a price value (non-negative, with optional max)
  static double validatePrice(double value, {double max = 1000000.0}) {
    return validateNonNegative(value, 'price', max: max);
  }

  /// Safely converts a JSON value to double with validation
  static double parseDouble(
    dynamic value,
    String fieldName, {
    double defaultValue = 0.0,
    double? min,
    double? max,
  }) {
    final doubleValue = (value as num?)?.toDouble() ?? defaultValue;
    return validateNonNegative(doubleValue, fieldName, min: min, max: max);
  }

  /// Safely converts a JSON value to int with validation
  static int parseInt(
    dynamic value,
    String fieldName, {
    int defaultValue = 0,
    int? min,
    int? max,
  }) {
    final intValue = (value as num?)?.toInt() ?? defaultValue;
    return validateNonNegativeInt(intValue, fieldName, min: min, max: max);
  }
}
