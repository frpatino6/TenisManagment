import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/models/court_model.dart';
import '../../domain/services/booking_service.dart';
import '../../domain/services/court_service.dart';
import '../../../../core/services/http_client.dart';


final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(appHttpClientProvider));
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

/// Provider for courts list
final courtsProvider =
    FutureProvider.autoDispose<List<CourtModel>>((ref) async {
      final service = ref.watch(courtServiceProvider);
      return service.getCourts();
    });
