import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../events/data_change_event.dart';
import '../../features/booking/presentation/providers/booking_provider.dart';
import '../../features/student/presentation/providers/student_provider.dart';
import '../../features/tenant_admin/presentation/providers/tenant_admin_provider.dart';
import '../../features/professor/presentation/providers/professor_provider.dart';

/// Observer that listens to data change events and automatically invalidates
/// related Riverpod providers to trigger reactive updates
class DataChangeObserver {
  final Ref _ref;
  final StreamController<DataChangeEvent> _eventController =
      StreamController<DataChangeEvent>.broadcast();
  StreamSubscription<DataChangeEvent>? _subscription;

  DataChangeObserver(this._ref) {
    _subscription = _eventController.stream.listen(_handleEvent);
  }

  /// Stream of data change events
  Stream<DataChangeEvent> get events => _eventController.stream;

  /// Notify observers about a data change
  void notifyChange(DataChangeEvent event) {
    _eventController.add(event);
  }

  /// Handle incoming events and invalidate related providers
  void _handleEvent(DataChangeEvent event) {
    try {
      _getProvidersForEntity(event.entityType);
    } catch (e) {
      // Provider might not exist or might be a family provider
      // Log error but continue execution
      // In production, you might want to use a logger here
    }
  }

  /// Maps entity types to their related providers
  /// Invalidates providers that should be refreshed when the entity changes
  void _getProvidersForEntity(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'booking':
        _ref.invalidate(tenantBookingsProvider);
        _ref.invalidate(studentBookingsProvider);
        _ref.invalidate(professorBookingsProvider);
        _ref.invalidate(bookingStatsProvider);
        _ref.invalidate(bookingCalendarProvider);
        _ref.invalidate(recentActivitiesProvider);
        _ref.invalidate(studentInfoProvider);
        _ref.invalidate(tenantMetricsProvider);
        break;

      case 'payment':
        _ref.invalidate(tenantPaymentsProvider);
        _ref.invalidate(paymentHistoryProvider);
        _ref.invalidate(studentInfoProvider);
        _ref.invalidate(tenantMetricsProvider);
        _ref.invalidate(debtReportProvider);
        _ref.invalidate(earningsStatsProvider);
        break;

      case 'court':
        _ref.invalidate(courtsProvider);
        _ref.invalidate(courtAvailableSlotsProvider);
        _ref.invalidate(tenantCourtsProvider);
        _ref.invalidate(filteredTenantCourtsProvider);
        _ref.invalidate(filteredTenantCourtsByStatusProvider);
        break;

      case 'schedule':
      case 'class':
        _ref.invalidate(professorSchedulesProvider);
        _ref.invalidate(todayScheduleProvider);
        _ref.invalidate(weekScheduleProvider);
        _ref.invalidate(scheduleByDateProvider);
        _ref.invalidate(availableSchedulesProvider);
        _ref.invalidate(earningsStatsProvider);
        _ref.invalidate(studentBookingsProvider);
        break;

      case 'professor':
        _ref.invalidate(professorsProvider);
        _ref.invalidate(tenantProfessorsProvider);
        _ref.invalidate(filteredTenantProfessorsByStatusProvider);
        _ref.invalidate(professorInfoProvider);
        _ref.invalidate(professorStudentsProvider);
        _ref.invalidate(availableSchedulesProvider);
        break;

      case 'student':
        _ref.invalidate(tenantStudentsProvider);
        _ref.invalidate(studentInfoProvider);
        _ref.invalidate(studentBookingsProvider);
        _ref.invalidate(professorStudentsProvider);
        break;

      case 'tenant':
        _ref.invalidate(tenantInfoProvider);
        _ref.invalidate(tenantMetricsProvider);
        _ref.invalidate(tenantBookingsProvider);
        _ref.invalidate(tenantPaymentsProvider);
        _ref.invalidate(tenantCourtsProvider);
        _ref.invalidate(tenantProfessorsProvider);
        _ref.invalidate(tenantStudentsProvider);
        _ref.invalidate(courtsProvider);
        break;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _eventController.close();
  }
}

/// Global Riverpod provider for DataChangeObserver
/// This observer listens to data change events and automatically invalidates
/// related providers to trigger reactive updates throughout the app
final dataChangeObserverProvider = Provider<DataChangeObserver>((ref) {
  final observer = DataChangeObserver(ref);
  ref.onDispose(() => observer.dispose());
  return observer;
});
