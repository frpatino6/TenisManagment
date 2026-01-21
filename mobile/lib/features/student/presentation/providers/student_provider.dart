import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/recent_activity_model.dart';
import '../../domain/models/booking_model.dart';
import '../../domain/services/student_service.dart';

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});

final recentActivitiesProvider =
    FutureProvider.autoDispose<List<RecentActivityModel>>((ref) async {
      final service = ref.watch(studentServiceProvider);
      return service.getRecentActivities();
    });

final studentInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(studentServiceProvider);
  return service.getStudentInfo();
});

class BalanceSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() {
    state = true;
  }

  void stop() {
    state = false;
  }
}

final balanceSyncProvider =
    NotifierProvider.autoDispose<BalanceSyncNotifier, bool>(
      BalanceSyncNotifier.new,
    );

final studentBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>((
  ref,
) async {
  final service = ref.watch(studentServiceProvider);
  return service.getBookings();
});
