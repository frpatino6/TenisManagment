import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tenant_metrics_model.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/models/tenant_court_model.dart';
import '../../domain/services/tenant_admin_service.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../domain/models/tenant_student_model.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../../domain/models/booking_stats_model.dart';
import '../../domain/models/tenant_payment_model.dart';

import '../../../../core/services/http_client.dart';

/// Provider for TenantAdminService
final tenantAdminServiceProvider = Provider<TenantAdminService>((ref) {
  final httpClient = ref.watch(appHttpClientProvider);
  return TenantAdminService(httpClient: httpClient);
});

/// Provider for tenant metrics
final tenantMetricsProvider = FutureProvider<TenantMetricsModel>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getMetrics();
});

/// Provider for tenant configuration/info
final tenantInfoProvider = FutureProvider<TenantConfigModel>((ref) async {
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getTenantInfo();
});

/// Provider for list of professors
final tenantProfessorsProvider = FutureProvider<List<TenantProfessorModel>>((
  ref,
) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido');
  }
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getProfessors();
});

/// Provider for list of courts
final tenantCourtsProvider = FutureProvider<List<TenantCourtModel>>((
  ref,
) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido');
  }
  final service = ref.read(tenantAdminServiceProvider);
  return await service.getCourts();
});

/// Provider for filtering professors by status (active/inactive)
final filteredTenantProfessorsByStatusProvider =
    Provider.family<List<TenantProfessorModel>, String>((ref, statusFilter) {
      final professorsAsync = ref.watch(tenantProfessorsProvider);

      return professorsAsync.when(
        data: (professors) {
          if (statusFilter == 'all') {
            return professors;
          }
          final bool isActive = statusFilter == 'active';
          return professors
              .where((professor) => professor.isActive == isActive)
              .toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });

/// Provider for filtering courts by status (active/inactive)
final filteredTenantCourtsByStatusProvider =
    Provider.family<List<TenantCourtModel>, String>((ref, statusFilter) {
      final courtsAsync = ref.watch(tenantCourtsProvider);

      return courtsAsync.when(
        data: (courts) {
          if (statusFilter == 'all') {
            return courts;
          }
          final bool isActive = statusFilter == 'active';
          return courts.where((court) => court.isActive == isActive).toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });

/// Provider for searching courts by name, type or description
final filteredTenantCourtsProvider =
    Provider.family<List<TenantCourtModel>, String>((ref, query) {
      final courtsAsync = ref.watch(tenantCourtsProvider);

      return courtsAsync.when(
        data: (courts) {
          if (query.isEmpty) {
            return courts;
          }
          final lowercaseQuery = query.toLowerCase();
          return courts.where((court) {
            return court.name.toLowerCase().contains(lowercaseQuery) ||
                court.type.toLowerCase().contains(lowercaseQuery) ||
                (court.description?.toLowerCase().contains(lowercaseQuery) ??
                    false);
          }).toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });

// ============================================================================
// BOOKING PROVIDERS
// ============================================================================

/// Provider for booking pagination
class BookingPageNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void setPage(int page) => state = page;
}

final bookingPageProvider = NotifierProvider<BookingPageNotifier, int>(
  BookingPageNotifier.new,
);

/// Providers for filters
class BookingStatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final bookingStatusFilterProvider =
    NotifierProvider<BookingStatusFilterNotifier, String?>(
      BookingStatusFilterNotifier.new,
    );

class BookingCourtFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final bookingCourtFilterProvider =
    NotifierProvider<BookingCourtFilterNotifier, String?>(
      BookingCourtFilterNotifier.new,
    );

class BookingProfessorFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final bookingProfessorFilterProvider =
    NotifierProvider<BookingProfessorFilterNotifier, String?>(
      BookingProfessorFilterNotifier.new,
    );

class BookingStudentSearchNotifier extends Notifier<String> {
  @override
  String build() => "";
  void set(String value) => state = value;
}

final bookingStudentSearchProvider =
    NotifierProvider<BookingStudentSearchNotifier, String>(
      BookingStudentSearchNotifier.new,
    );

/// Provider for fetching bookings with advanced filters
final tenantBookingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final tenantId = ref.watch(currentTenantIdProvider);
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Tenant ID requerido');
    }

    final service = ref.read(tenantAdminServiceProvider);
    final page = ref.watch(bookingPageProvider);

    // Watch filters
    final status = ref.watch(bookingStatusFilterProvider);
    final courtId = ref.watch(bookingCourtFilterProvider);
    final professorId = ref.watch(bookingProfessorFilterProvider);
    final studentSearch = ref.watch(bookingStudentSearchProvider);

    return await service.getBookings(
      page: page,
      limit: 20,
      status: status,
      courtId: courtId,
      professorId: professorId,
      search: studentSearch.isEmpty ? null : studentSearch,
    );
  },
);

/// Provider for booking statistics
final bookingStatsProvider = FutureProvider.autoDispose<BookingStatsModel>((
  ref,
) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido');
  }
  final service = ref.read(tenantAdminServiceProvider);
  final dateRange = ref.watch(bookingStatsDateRangeProvider);
  return await service.getBookingStats(
    from: dateRange?.start,
    to: dateRange?.end,
  );
});

class BookingStatsDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void setRange(DateTimeRange? range) => state = range;
}

final bookingStatsDateRangeProvider =
    NotifierProvider<BookingStatsDateRangeNotifier, DateTimeRange?>(
      BookingStatsDateRangeNotifier.new,
    );

// ============================================================================
// PAYMENTS PROVIDERS
// ============================================================================

class PaymentsPageNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void setPage(int page) => state = page;
}

final paymentsPageProvider = NotifierProvider<PaymentsPageNotifier, int>(
  PaymentsPageNotifier.new,
);

class PaymentsDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void setRange(DateTimeRange? range) => state = range;
}

final paymentsDateRangeProvider =
    NotifierProvider<PaymentsDateRangeNotifier, DateTimeRange?>(
      PaymentsDateRangeNotifier.new,
    );

final tenantPaymentsProvider =
    FutureProvider.autoDispose<TenantPaymentsResponse>((ref) async {
      final tenantId = ref.watch(currentTenantIdProvider);
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID requerido');
      }
      final service = ref.read(tenantAdminServiceProvider);
      final page = ref.watch(paymentsPageProvider);
      final dateRange = ref.watch(paymentsDateRangeProvider);

      return await service.getPayments(
        page: page,
        limit: 20,
        from: dateRange?.start,
        to: dateRange?.end,
        gateway: 'WOMPI',
      );
});

/// Provider for booking calendar
final bookingCalendarProvider = FutureProvider.autoDispose
    .family<Map<String, List<dynamic>>, ({DateTime from, DateTime to})>((
      ref,
      range,
    ) async {
      final tenantId = ref.watch(currentTenantIdProvider);
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID requerido');
      }
      final service = ref.read(tenantAdminServiceProvider);
      return await service.getBookingCalendar(from: range.from, to: range.to);
    });

// ============================================================================
// STUDENT PROVIDERS
// ============================================================================

class StudentSearchNotifier extends Notifier<String> {
  @override
  String build() => "";
  void set(String value) => state = value;
}

final studentSearchProvider = NotifierProvider<StudentSearchNotifier, String>(
  StudentSearchNotifier.new,
);

class StudentPageNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void setPage(int page) => state = page;
}

final studentPageProvider = NotifierProvider<StudentPageNotifier, int>(
  StudentPageNotifier.new,
);

/// Provider for fetching students with search and pagination
final tenantStudentsProvider =
    FutureProvider.autoDispose<TenantStudentsResponse>((ref) async {
      final tenantId = ref.watch(currentTenantIdProvider);
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID requerido');
      }

      final service = ref.read(tenantAdminServiceProvider);
      final page = ref.watch(studentPageProvider);
      final search = ref.watch(studentSearchProvider);

      return await service.getStudents(
        page: page,
        search: search.isEmpty ? null : search,
      );
    });

// ============================================================================
// PROFESSOR BOOKINGS PROVIDER
// ============================================================================

/// Provider for fetching bookings for a specific professor
final professorBookingsProvider = FutureProvider.autoDispose
    .family<List<TenantBookingModel>, String>((ref, professorId) async {
      final tenantId = ref.watch(currentTenantIdProvider);
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID requerido');
      }

      final service = ref.read(tenantAdminServiceProvider);

      // Fetch bookings for this professor (upcoming and recent)
      final result = await service.getBookings(
        professorId: professorId,
        page: 1,
        limit: 50,
      );

      return (result['bookings'] as List<TenantBookingModel>);
    });
