import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_client.dart';
import '../../domain/models/recent_activity_model.dart';
import '../../domain/models/booking_model.dart';
import '../../domain/models/student_payment_model.dart';
import '../../domain/repositories/student_repository.dart';
import '../../infrastructure/repositories/student_repository_impl.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final httpClient = ref.watch(appHttpClientProvider);
  return StudentRepositoryImpl(httpClient: httpClient);
});

final recentActivitiesProvider =
    FutureProvider.autoDispose<List<RecentActivityModel>>((ref) async {
      final repository = ref.watch(studentRepositoryProvider);
      return repository.getRecentActivities();
    });

final studentInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentInfo();
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
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getBookings();
});

final paymentHistoryProvider = FutureProvider.autoDispose
    .family<
      List<StudentPaymentModel>,
      ({DateTime? from, DateTime? to, String? status})
    >((ref, params) async {
      final repository = ref.watch(studentRepositoryProvider);
        return repository.getPaymentHistory(
        from: params.from,
        to: params.to,
        status: params.status,
      );
    });
