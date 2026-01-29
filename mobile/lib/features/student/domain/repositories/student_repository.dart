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

  /// Retrieves recent activities for the authenticated student
  Future<List<RecentActivityModel>> getRecentActivities();

  /// Retrieves the student's profile information
  Future<Map<String, dynamic>> getStudentInfo();

  /// Retrieves all bookings for the authenticated student
  Future<List<BookingModel>> getBookings();
}
