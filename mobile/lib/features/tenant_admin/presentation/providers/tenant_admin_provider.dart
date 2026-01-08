import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tenant_metrics_model.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/models/tenant_court_model.dart';
import '../../domain/services/tenant_admin_service.dart';
import '../../../../core/providers/tenant_provider.dart';

/// Provider for TenantAdminService
final tenantAdminServiceProvider = Provider<TenantAdminService>((ref) {
  return TenantAdminService(ref: ref);
});

/// Provider for tenant metrics
/// Waits for tenant to be loaded before fetching metrics (requires X-Tenant-ID header)
final tenantMetricsProvider = FutureProvider<TenantMetricsModel>((ref) async {
  // Wait for tenant to be loaded - watch currentTenantIdProvider
  final tenantId = ref.watch(currentTenantIdProvider);

  // If tenant is not loaded yet, throw error to retry later
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
/// Waits for tenant to be loaded before fetching professors (requires X-Tenant-ID header)
final tenantProfessorsProvider = FutureProvider<List<TenantProfessorModel>>((
  ref,
) async {
  // Wait for tenant to be loaded - watch currentTenantIdProvider
  final tenantId = ref.watch(currentTenantIdProvider);

  // If tenant is not loaded yet, throw error to retry later
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }

  final service = ref.read(tenantAdminServiceProvider);
  return await service.getProfessors();
});

/// Provider for filtering professors based on search query and status
final filteredTenantProfessorsProvider =
    Provider.family<List<TenantProfessorModel>, String>((ref, searchQuery) {
      final professorsAsync = ref.watch(tenantProfessorsProvider);

      return professorsAsync.when(
        data: (professors) {
          if (searchQuery.isEmpty) {
            return professors;
          }
          final filtered = professors.where((professor) {
            final query = searchQuery.toLowerCase();
            return professor.name.toLowerCase().contains(query) ||
                professor.email.toLowerCase().contains(query) ||
                (professor.phone?.toLowerCase().contains(query) ?? false);
          }).toList();
          return filtered;
        },
        loading: () => [],
        error: (_, _) => [],
      );
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

/// Provider for listing courts for the current tenant
final tenantCourtsProvider = FutureProvider<List<TenantCourtModel>>((
  ref,
) async {
  // Ensure tenant is loaded before fetching courts
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }

  final service = ref.read(tenantAdminServiceProvider);
  return await service.getCourts();
});

/// Provider for filtering courts based on search query
final filteredTenantCourtsProvider =
    Provider.family<List<TenantCourtModel>, String>((ref, searchQuery) {
      final courtsAsync = ref.watch(tenantCourtsProvider);

      return courtsAsync.when(
        data: (courts) {
          if (searchQuery.isEmpty) {
            return courts;
          }
          final query = searchQuery.toLowerCase();
          return courts.where((court) {
            return court.name.toLowerCase().contains(query) ||
                court.type.toLowerCase().contains(query) ||
                (court.description?.toLowerCase().contains(query) ?? false);
          }).toList();
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

// ============================================================================
// BOOKING PROVIDERS
// ============================================================================

/// Simple provider for booking page (can be overridden in screens)
final bookingPageProvider = Provider<int>((ref) => 1);

/// Provider for fetching bookings
/// Use .family to pass parameters when needed
final tenantBookingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    // Wait for tenant to be loaded
    final tenantId = ref.watch(currentTenantIdProvider);
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Tenant ID requerido. Cargando tenant...');
    }

    final service = ref.read(tenantAdminServiceProvider);
    final page = ref.watch(bookingPageProvider);

    return await service.getBookings(page: page, limit: 20);
  },
);

/// Provider for booking statistics
final bookingStatsProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  // Wait for tenant to be loaded
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null || tenantId.isEmpty) {
    throw Exception('Tenant ID requerido. Cargando tenant...');
  }

  final service = ref.read(tenantAdminServiceProvider);
  return await service.getBookingStats();
});

/// Provider for booking calendar
/// Fetches bookings grouped by date for a given month/range
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
