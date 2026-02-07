import '../models/court_model.dart';
import '../repositories/court_repository.dart';

/// Domain service for managing court bookings
///
/// This service orchestrates business logic related to courts.
/// It delegates data access to the [CourtRepository] and focuses on
/// domain validation and business rules.
class CourtService {
  final CourtRepository _repository;

  CourtService(this._repository);

  /// Retrieves the list of available courts for the active tenant
  ///
  /// Returns a list of [CourtModel] containing court information
  /// such as name, type, price per hour, and features.
  ///
  /// Throws [AppException] subclasses if the operation fails:
  /// - [AuthException.notAuthenticated] if user is not authenticated
  /// - [AuthException.tokenExpired] if authentication token is invalid
  /// - [ValidationException] if tenant configuration is invalid
  /// - [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no courts are available
  Future<List<CourtModel>> getCourts() async {
    return _repository.getCourts();
  }

  /// Retrieves available time slots for a court on a specific date
  ///
  /// [courtId] The ID of the court
  /// [date] The date to check availability for
  ///
  /// Returns a [Map] containing available time slots and booking information
  ///
  /// Throws [AppException] subclasses if the operation fails:
  /// - [AuthException.notAuthenticated] if user is not authenticated
  /// - [AuthException.tokenExpired] if authentication token is invalid
  /// - [ValidationException] if court ID or date is invalid
  /// - [NetworkException] if the API request fails
  Future<Map<String, dynamic>> getAvailableSlots({
    required String courtId,
    required DateTime date,
  }) async {
    return _repository.getAvailableSlots(courtId: courtId, date: date);
  }

  /// Books a court for a specific time period
  ///
  /// [courtId] The ID of the court to book
  /// [startTime] The start time of the booking
  /// [endTime] The end time of the booking
  /// [price] The total price for the booking
  ///
  /// Returns a [Map] containing the booking confirmation data including booking ID
  ///
  /// Throws [AppException] subclasses if the operation fails:
  /// - [AuthException.notAuthenticated] if user is not authenticated
  /// - [AuthException.tokenExpired] if authentication token is invalid
  /// - [ValidationException] if booking data is invalid
  /// - [DomainException.conflict] if the court is already booked for that time
  /// - [NetworkException] if the API request fails
  Future<Map<String, dynamic>> bookCourt({
    required String courtId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
  }) async {
    return _repository.bookCourt(
      courtId: courtId,
      startTime: startTime,
      endTime: endTime,
      price: price,
    );
  }
}
