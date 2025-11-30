import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/services/booking_service.dart';


final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});


final professorsProvider =
    FutureProvider.autoDispose<List<ProfessorBookingModel>>((ref) async {
      final service = ref.watch(bookingServiceProvider);
      return service.getProfessors();
    });


final availableSchedulesProvider = FutureProvider.autoDispose
    .family<List<AvailableScheduleModel>, String>((ref, professorId) async {
      final service = ref.watch(bookingServiceProvider);
      return service.getAvailableSchedules(professorId);
    });
