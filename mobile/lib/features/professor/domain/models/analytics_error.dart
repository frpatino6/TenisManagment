import 'package:equatable/equatable.dart';

/// Enum representing different types of analytics errors
enum AnalyticsErrorType {
  networkError,
  authenticationError,
  authorizationError,
  dataNotFound,
  dataValidationError,
  serverError,
  timeoutError,
  unknownError,
}

/// Class representing analytics-specific errors with detailed information
class AnalyticsError extends Equatable {
  final AnalyticsErrorType type;
  final String message;
  final String? details;
  final int? statusCode;
  final String? endpoint;
  final DateTime timestamp;

  const AnalyticsError({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
    this.endpoint,
    required this.timestamp,
  });

  /// Create an error from HTTP response
  factory AnalyticsError.fromHttpResponse({
    required int statusCode,
    required String endpoint,
    String? responseBody,
  }) {
    AnalyticsErrorType type;
    String message;
    String? details;

    switch (statusCode) {
      case 401:
        type = AnalyticsErrorType.authenticationError;
        message = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
        details = 'Token de autenticación inválido o expirado';
        break;
      case 403:
        type = AnalyticsErrorType.authorizationError;
        message = 'No tienes permisos para acceder a esta información.';
        details = 'Usuario no autorizado para ver analytics';
        break;
      case 404:
        type = AnalyticsErrorType.dataNotFound;
        message = 'No se encontraron datos para el período seleccionado.';
        details =
            'El profesor no tiene datos en el rango de fechas especificado';
        break;
      case 422:
        type = AnalyticsErrorType.dataValidationError;
        message = 'Los parámetros de filtro son inválidos.';
        details = 'Verifica que los filtros seleccionados sean correctos';
        break;
      case 500:
        type = AnalyticsErrorType.serverError;
        message = 'Error interno del servidor. Intenta nuevamente.';
        details = 'Error en el procesamiento de datos en el servidor';
        break;
      case 503:
        type = AnalyticsErrorType.serverError;
        message = 'Servicio temporalmente no disponible.';
        details = 'El servidor está en mantenimiento';
        break;
      default:
        if (statusCode >= 400 && statusCode < 500) {
          type = AnalyticsErrorType.dataValidationError;
          message = 'Error en la solicitud. Verifica los parámetros.';
        } else if (statusCode >= 500) {
          type = AnalyticsErrorType.serverError;
          message = 'Error del servidor. Intenta más tarde.';
        } else {
          type = AnalyticsErrorType.unknownError;
          message = 'Error inesperado.';
        }
        details = responseBody;
    }

    return AnalyticsError(
      type: type,
      message: message,
      details: details,
      statusCode: statusCode,
      endpoint: endpoint,
      timestamp: DateTime.now(),
    );
  }

  /// Create a network error
  factory AnalyticsError.networkError({
    required String endpoint,
    String? details,
  }) {
    return AnalyticsError(
      type: AnalyticsErrorType.networkError,
      message: 'Error de conexión. Verifica tu internet.',
      details: details ?? 'No se pudo conectar con el servidor',
      endpoint: endpoint,
      timestamp: DateTime.now(),
    );
  }

  /// Create a timeout error
  factory AnalyticsError.timeoutError({required String endpoint}) {
    return AnalyticsError(
      type: AnalyticsErrorType.timeoutError,
      message: 'La solicitud tardó demasiado. Intenta nuevamente.',
      details: 'Timeout al conectar con el servidor',
      endpoint: endpoint,
      timestamp: DateTime.now(),
    );
  }

  /// Create an authentication error
  factory AnalyticsError.authenticationError({required String endpoint}) {
    return AnalyticsError(
      type: AnalyticsErrorType.authenticationError,
      message: 'Sesión expirada. Por favor, inicia sesión nuevamente.',
      details: 'Token de autenticación inválido',
      endpoint: endpoint,
      timestamp: DateTime.now(),
    );
  }

  /// Create a data not found error
  factory AnalyticsError.dataNotFound({
    required String endpoint,
    String? details,
  }) {
    return AnalyticsError(
      type: AnalyticsErrorType.dataNotFound,
      message: 'No se encontraron datos para mostrar.',
      details:
          details ?? 'No hay datos disponibles para el período seleccionado',
      endpoint: endpoint,
      timestamp: DateTime.now(),
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case AnalyticsErrorType.networkError:
        return 'Verifica tu conexión a internet e intenta nuevamente.';
      case AnalyticsErrorType.authenticationError:
        return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      case AnalyticsErrorType.authorizationError:
        return 'No tienes permisos para ver esta información.';
      case AnalyticsErrorType.dataNotFound:
        return 'No hay datos disponibles para el período seleccionado.';
      case AnalyticsErrorType.dataValidationError:
        return 'Los filtros seleccionados no son válidos.';
      case AnalyticsErrorType.serverError:
        return 'Error del servidor. Intenta más tarde.';
      case AnalyticsErrorType.timeoutError:
        return 'La solicitud tardó demasiado. Intenta nuevamente.';
      case AnalyticsErrorType.unknownError:
        return 'Error inesperado. Intenta nuevamente.';
    }
  }

  /// Get error icon
  String get icon {
    switch (type) {
      case AnalyticsErrorType.networkError:
        return 'wifi_off';
      case AnalyticsErrorType.authenticationError:
        return 'lock';
      case AnalyticsErrorType.authorizationError:
        return 'block';
      case AnalyticsErrorType.dataNotFound:
        return 'search_off';
      case AnalyticsErrorType.dataValidationError:
        return 'error';
      case AnalyticsErrorType.serverError:
        return 'cloud_off';
      case AnalyticsErrorType.timeoutError:
        return 'schedule';
      case AnalyticsErrorType.unknownError:
        return 'help';
    }
  }

  /// Get error color
  String get color {
    switch (type) {
      case AnalyticsErrorType.networkError:
        return '#FF9800'; // Orange
      case AnalyticsErrorType.authenticationError:
        return '#F44336'; // Red
      case AnalyticsErrorType.authorizationError:
        return '#9C27B0'; // Purple
      case AnalyticsErrorType.dataNotFound:
        return '#2196F3'; // Blue
      case AnalyticsErrorType.dataValidationError:
        return '#FF5722'; // Deep Orange
      case AnalyticsErrorType.serverError:
        return '#F44336'; // Red
      case AnalyticsErrorType.timeoutError:
        return '#FF9800'; // Orange
      case AnalyticsErrorType.unknownError:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case AnalyticsErrorType.networkError:
      case AnalyticsErrorType.timeoutError:
      case AnalyticsErrorType.serverError:
        return true;
      case AnalyticsErrorType.authenticationError:
      case AnalyticsErrorType.authorizationError:
      case AnalyticsErrorType.dataNotFound:
      case AnalyticsErrorType.dataValidationError:
      case AnalyticsErrorType.unknownError:
        return false;
    }
  }

  /// Get retry delay in seconds
  int get retryDelay {
    switch (type) {
      case AnalyticsErrorType.networkError:
        return 2;
      case AnalyticsErrorType.timeoutError:
        return 3;
      case AnalyticsErrorType.serverError:
        return 5;
      default:
        return 0;
    }
  }

  @override
  List<Object?> get props => [
    type,
    message,
    details,
    statusCode,
    endpoint,
    timestamp,
  ];

  @override
  String toString() {
    return 'AnalyticsError(type: $type, message: $message, statusCode: $statusCode, endpoint: $endpoint)';
  }
}
