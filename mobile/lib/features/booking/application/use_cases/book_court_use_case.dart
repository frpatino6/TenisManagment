import '../../domain/services/court_service.dart';
import '../../../../core/exceptions/exceptions.dart';

/// Request model for booking a court
class BookCourtRequest {
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;

  BookCourtRequest({
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  /// Validates the booking request
  /// Throws [ValidationException] if any field is invalid
  void validate() {
    if (courtId.isEmpty) {
      throw ValidationException(
        'El ID de la cancha es requerido',
        code: 'INVALID_COURT_ID',
      );
    }

    if (startTime.isAfter(endTime) || startTime.isAtSameMomentAs(endTime)) {
      throw ValidationException(
        'La hora de inicio debe ser anterior a la hora de fin',
        code: 'INVALID_TIME_RANGE',
      );
    }

    if (price <= 0) {
      throw ValidationException(
        'El precio debe ser mayor a cero',
        code: 'INVALID_PRICE',
      );
    }

    final now = DateTime.now();
    if (startTime.isBefore(now)) {
      throw ValidationException(
        'No se puede reservar una cancha en el pasado',
        code: 'INVALID_START_TIME',
      );
    }
  }
}

/// Result model for booking operation
class BookCourtResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final String? errorCode;

  BookCourtResult.success(this.data)
      : success = true,
        errorMessage = null,
        errorCode = null;

  BookCourtResult.failure(this.errorMessage, {this.errorCode})
      : success = false,
        data = null;
}

/// Use case for booking a court
/// Encapsulates the business logic for court booking operations
class BookCourtUseCase {
  final CourtService _courtService;

  BookCourtUseCase({
    required CourtService courtService,
  }) : _courtService = courtService;

  /// Executes the court booking operation
  ///
  /// [request] The booking request containing court ID, time range, and price
  ///
  /// Returns [BookCourtResult] with success status and booking data or error information
  ///
  /// Throws [ValidationException] if request validation fails
  /// Throws [AuthException] if user is not authenticated
  /// Throws [DomainException] if court is already booked
  /// Throws [NetworkException] if API request fails
  Future<BookCourtResult> execute(BookCourtRequest request) async {
    try {
      request.validate();

      final result = await _courtService.bookCourt(
        courtId: request.courtId,
        startTime: request.startTime,
        endTime: request.endTime,
        price: request.price,
      );

      return BookCourtResult.success(result);
    } on ValidationException catch (e) {
      return BookCourtResult.failure(
        e.message,
        errorCode: e.code,
      );
    } on AuthException catch (e) {
      return BookCourtResult.failure(
        e.message,
        errorCode: 'AUTH_ERROR',
      );
    } on DomainException catch (e) {
      return BookCourtResult.failure(
        e.message,
        errorCode: 'DOMAIN_ERROR',
      );
    } on NetworkException catch (e) {
      return BookCourtResult.failure(
        e.message,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      return BookCourtResult.failure(
        'Error inesperado al realizar la reserva: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }
}
