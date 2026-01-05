import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/models/court_model.dart';
import '../../domain/services/booking_service.dart';
import '../../domain/services/court_service.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/providers/tenant_provider.dart';


final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(appHttpClientProvider));
});


final professorsProvider =
    FutureProvider.autoDispose<List<ProfessorBookingModel>>((ref) async {
      // Wait for tenant to be available
      final hasTenant = ref.watch(hasTenantProvider);
      if (!hasTenant) {
        throw Exception('Tenant ID requerido. Selecciona un centro primero.');
      }
      
      final service = ref.watch(bookingServiceProvider);
      return service.getProfessors();
    });


final availableSchedulesProvider = FutureProvider.autoDispose
    .family<List<AvailableScheduleModel>, String>((ref, professorId) async {
      // Wait for tenant to be available
      final hasTenant = ref.watch(hasTenantProvider);
      if (!hasTenant) {
        throw Exception('Tenant ID requerido. Selecciona un centro primero.');
      }
      
      final service = ref.watch(bookingServiceProvider);
      return service.getAvailableSchedules(professorId);
    });

/// Provider for courts list
/// Waits for tenant to be available before making the request
/// Watches currentTenantIdProvider to invalidate when tenant changes
final courtsProvider =
    FutureProvider.autoDispose<List<CourtModel>>((ref) async {
      // Watch currentTenantIdProvider to invalidate when tenant changes
      final tenantId = ref.watch(currentTenantIdProvider);
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant ID requerido. Selecciona un centro primero.');
      }
      
      final service = ref.watch(courtServiceProvider);
      return service.getCourts();
    });

/// Provider for available time slots for a court on a specific date
final courtAvailableSlotsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String courtId, DateTime date})>((ref, params) async {
  // Wait for tenant to be available
  final hasTenant = ref.watch(hasTenantProvider);
  if (!hasTenant) {
    throw Exception('Tenant ID requerido. Selecciona un centro primero.');
  }
  
  final service = ref.watch(courtServiceProvider);
  return service.getAvailableSlots(courtId: params.courtId, date: params.date);
});
