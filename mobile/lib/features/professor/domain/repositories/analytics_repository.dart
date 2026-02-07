import '../models/analytics_overview.dart';
import '../models/analytics_chart_data.dart';

/// Repository interface for analytics-related data operations
///
/// This is a domain contract that defines the operations needed by the business logic.
/// Implementations should be in the infrastructure layer.
abstract class AnalyticsRepository {
  /// Retrieves the complete analytics overview from the professor's endpoint
  /// Returns [AnalyticsOverview] with metrics and charts
  Future<AnalyticsOverview> getOverview({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves revenue analytics data
  /// Returns [AnalyticsChartData] with revenue information
  Future<AnalyticsChartData> getRevenueData({String period = 'month'});

  /// Retrieves bookings analytics data
  /// Returns [AnalyticsChartData] with booking information
  Future<AnalyticsChartData> getBookingsData({String period = 'month'});

  /// Retrieves students analytics data
  /// Returns [AnalyticsChartData] with student information
  Future<AnalyticsChartData> getStudentsData({String period = 'month'});

  /// Retrieves revenue breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getRevenueBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves bookings breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getBookingsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves revenue trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getRevenueTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves bookings trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getBookingsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves students breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getStudentsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves students trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getStudentsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  });

  /// Retrieves occupancy details data
  /// Returns real occupancy data from database with time slots and trends
  Future<Map<String, dynamic>> getOccupancyDetails({String period = 'month'});
}
