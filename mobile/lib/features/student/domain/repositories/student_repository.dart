import '../models/recent_activity_model.dart';
import '../models/booking_model.dart';
import '../models/student_payment_model.dart';

/// Repository interface for student-related data operations
///
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class StudentRepository {
  /// Retrieves student payment history with optional filters
  Future<List<StudentPaymentModel>> getPaymentHistory({
    DateTime? from,
    DateTime? to,
    String? status,
  });

  /// Retrieves activities for the authenticated student with optional filters
  ///
  /// [fromDate] - Only return activities from this date onwards (inclusive)
  /// [toDate] - Only return activities up to this date (inclusive)
  /// [type] - Filter by activity type: 'booking', 'payment', 'service_request', or null for all
  Future<List<RecentActivityModel>> getRecentActivities({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
  });

  /// Retrieves the student's profile information
  Future<Map<String, dynamic>> getStudentInfo();

  /// Retrieves bookings for the authenticated student with optional filters
  ///
  /// [fromDate] - Only return bookings from this date onwards (inclusive)
  /// [toDate] - Only return bookings up to this date (inclusive)
  /// [serviceType] - Filter by service type: 'individual_class', 'group_class', 'court_rental', or null for all
  Future<List<BookingModel>> getBookings({
    DateTime? fromDate,
    DateTime? toDate,
    String? serviceType,
  });
}
