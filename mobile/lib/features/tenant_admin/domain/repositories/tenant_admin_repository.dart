import '../models/tenant_metrics_model.dart';
import '../models/tenant_config_model.dart';
import '../models/tenant_professor_model.dart';
import '../models/tenant_court_model.dart';
import '../models/tenant_booking_model.dart';
import '../models/booking_stats_model.dart';
import '../models/tenant_student_model.dart';
import '../models/tenant_payment_model.dart';
import '../models/tenant_debt_report_model.dart';

/// Repository interface for tenant admin data operations
/// 
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class TenantAdminRepository {
  /// Get debt report for the tenant
  Future<TenantDebtReportModel> getDebtReport({String? search});

  /// Get metrics for the tenant
  Future<TenantMetricsModel> getMetrics();

  /// Get tenant information
  Future<TenantConfigModel> getTenantInfo();

  /// List tenant payment transactions
  Future<TenantPaymentsResponse> getPayments({
    int page = 1,
    int limit = 20,
    DateTime? from,
    DateTime? to,
    String? status,
    String? gateway,
    String? paymentMethodType,
    String? channel,
    String? search,
  });

  /// Update tenant configuration
  Future<TenantConfigModel> updateTenantConfig({
    String? name,
    String? slug,
    String? domain,
    TenantConfigData? config,
  });

  /// Update operating hours
  Future<TenantConfigModel> updateOperatingHours({
    required List<Map<String, dynamic>> schedule,
  });

  /// Get list of professors for the tenant
  Future<List<TenantProfessorModel>> getProfessors();

  /// Invite a professor to the tenant
  Future<void> inviteProfessor({
    required String email,
    Map<String, dynamic>? pricing,
  });

  /// Activate a professor in the tenant
  Future<void> activateProfessor(String professorId);

  /// Deactivate a professor in the tenant
  Future<void> deactivateProfessor(String professorId);

  /// Update professor details
  Future<TenantProfessorModel> updateProfessor({
    required String professorId,
    String? name,
    String? phone,
    double? hourlyRate,
    List<String>? specialties,
    Map<String, dynamic>? pricing,
  });

  /// Get list of courts for the tenant
  Future<List<TenantCourtModel>> getCourts();

  /// Create a new court
  Future<TenantCourtModel> createCourt({
    required String name,
    required String type,
    required double price,
    String? description,
    List<String>? features,
  });

  /// Update a court
  Future<TenantCourtModel> updateCourt({
    required String courtId,
    String? name,
    String? type,
    double? price,
    String? description,
    List<String>? features,
    bool? isActive,
  });

  /// Delete a court
  Future<void> deleteCourt(String courtId);

  /// Get list of bookings with filters
  Future<Map<String, dynamic>> getBookings({
    String? status,
    DateTime? from,
    DateTime? to,
    String? courtId,
    String? professorId,
    String? studentId,
    String? search,
    String? serviceType,
    int page = 1,
    int limit = 20,
  });

  /// Get calendar view of bookings
  Future<Map<String, List<Map<String, dynamic>>>> getBookingCalendar({
    required DateTime from,
    required DateTime to,
    String? courtId,
  });

  /// Get booking details
  Future<TenantBookingModel> getBookingDetails(String bookingId);

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? reason});

  /// Confirm a booking and register manual payment
  Future<void> confirmBooking(String bookingId, {String? paymentStatus});

  /// Get booking statistics
  Future<BookingStatsModel> getBookingStats({
    DateTime? from,
    DateTime? to,
  });

  /// Get list of students with filters and pagination
  Future<TenantStudentsResponse> getStudents({
    String? search,
    int page = 1,
    int limit = 20,
  });

  /// Get detailed information of a student
  Future<TenantStudentDetailsModel> getStudentDetails(String studentId);

  /// Update student balance
  Future<double> updateStudentBalance(
    String studentId, {
    required double amount,
    required String type,
    String? reason,
  });

  /// Confirm a manual payment
  Future<void> confirmPayment(String paymentId);
}
