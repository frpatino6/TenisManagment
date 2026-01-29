import '../models/professor_model.dart';
import '../models/student_summary_model.dart';
import '../models/class_schedule_model.dart';
import '../models/professor_schedule_model.dart';

/// Repository interface for professor-related data operations
/// 
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class ProfessorRepository {
  /// Retrieves professor information and dashboard data
  /// Returns [ProfessorModel] with complete professor details
  Future<ProfessorModel> getProfessorInfo();

  /// Retrieves the list of students associated with the professor
  /// Returns a list of [StudentSummaryModel] containing student information
  Future<List<StudentSummaryModel>> getStudents();

  /// Retrieves today's schedule for the professor
  /// Returns a list of [ClassScheduleModel] representing all classes scheduled for today
  Future<List<ClassScheduleModel>> getTodaySchedule();

  /// Retrieves the schedule for a specific date
  /// [date] The date to retrieve the schedule for
  /// Returns a list of [ClassScheduleModel] representing all classes scheduled for the specified date
  Future<List<ClassScheduleModel>> getScheduleByDate(DateTime date);

  /// Retrieves the schedule for the current week
  /// Returns a list of [ClassScheduleModel] representing all classes scheduled for the current week
  Future<List<ClassScheduleModel>> getWeekSchedule();

  /// Retrieves earnings statistics for the professor
  /// Returns a [Map] containing earnings data
  Future<Map<String, dynamic>> getEarningsStats();

  /// Updates the professor's profile information
  /// Returns the updated [ProfessorModel] with the new information
  Future<ProfessorModel> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
    required int experienceYears,
  });

  /// Confirms a scheduled class
  /// [classId] The ID of the class to confirm
  Future<void> confirmClass(String classId);

  /// Cancels a scheduled class
  /// [classId] The ID of the class to cancel
  /// [reason] The reason for cancellation
  Future<void> cancelClass(String classId, String reason);

  /// Creates a new available schedule slot
  /// Returns a [Map] containing the created schedule data including the schedule ID
  Future<Map<String, dynamic>> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String? tenantId,
    String? courtId,
  });

  /// Creates multiple schedules in batch
  Future<Map<String, dynamic>> createSchedulesBatch({
    required List<Map<String, dynamic>> schedules,
    String? tenantId,
  });

  /// Retrieves all schedules for the professor
  /// Returns a list of [ProfessorScheduleModel] containing all available and booked schedules
  Future<List<ProfessorScheduleModel>> getMySchedules();

  /// Deletes a schedule slot
  /// [scheduleId] The ID of the schedule to delete
  Future<void> deleteSchedule(String scheduleId);

  /// Blocks a schedule
  /// [scheduleId] The ID of the schedule to block
  /// [reason] The reason for blocking
  /// [courtId] Optional court ID
  Future<void> blockSchedule(String scheduleId, String reason, {String? courtId});

  /// Unblocks a schedule
  /// [scheduleId] The ID of the schedule to unblock
  Future<void> unblockSchedule(String scheduleId);

  /// Marks a class as completed and optionally records payment
  /// [scheduleId] The ID of the schedule/class to complete
  /// [paymentAmount] Optional payment amount received for the class
  /// [paymentStatus] Optional payment status
  Future<void> completeClass(String scheduleId, {double? paymentAmount, String? paymentStatus});

  /// Cancels a student's booking for a schedule
  /// [scheduleId] The ID of the schedule/booking to cancel
  /// [reason] Optional reason for cancellation
  /// [penaltyAmount] Optional penalty amount to apply
  Future<void> cancelBooking(String scheduleId, {String? reason, double? penaltyAmount});

  /// Joins a tenant (center) as a professor
  /// [tenantId] The ID of the tenant to join
  Future<void> joinTenant(String tenantId);
}
