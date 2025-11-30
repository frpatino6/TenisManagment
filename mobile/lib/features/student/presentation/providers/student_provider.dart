import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/recent_activity_model.dart';
import '../../domain/models/booking_model.dart';
import '../../domain/services/student_service.dart';


final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});


final recentActivitiesProvider = FutureProvider<List<RecentActivityModel>>((
  ref,
) async {
  final service = ref.watch(studentServiceProvider);
  return service.getRecentActivities();
});


final studentInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  return service.getStudentInfo();
});


final studentBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  return service.getBookings();
});
