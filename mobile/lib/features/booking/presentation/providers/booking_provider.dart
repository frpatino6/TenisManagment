import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/services/booking_service.dart';

// Service provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// Professors list provider
final professorsProvider = FutureProvider<List<ProfessorBookingModel>>((
  ref,
) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getProfessors();
});

// Available schedules provider for a specific professor
final availableSchedulesProvider =
    FutureProvider.family<List<AvailableScheduleModel>, String>((
      ref,
      professorId,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      return service.getAvailableSchedules(professorId);
    });
