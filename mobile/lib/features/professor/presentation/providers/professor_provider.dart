import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/professor_repository.dart';
import '../../infrastructure/repositories/professor_repository_impl.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/student_summary_model.dart';
import '../../domain/models/class_schedule_model.dart';
import '../../domain/models/professor_schedule_model.dart';
import '../../../../core/providers/tenant_provider.dart';

final professorRepositoryProvider = Provider<ProfessorRepository>((ref) {
  return ProfessorRepositoryImpl();
});

final professorInfoProvider = FutureProvider.autoDispose<ProfessorModel>((
  ref,
) async {
  final repository = ref.read(professorRepositoryProvider);
  return await repository.getProfessorInfo();
});

final professorStudentsProvider =
    FutureProvider.autoDispose<List<StudentSummaryModel>>((ref) async {
      final repository = ref.read(professorRepositoryProvider);
      return await repository.getStudents();
    });

final todayScheduleProvider =
    FutureProvider.autoDispose<List<ClassScheduleModel>>((ref) async {
      final repository = ref.read(professorRepositoryProvider);
      return await repository.getTodaySchedule();
    });

final scheduleByDateProvider = FutureProvider.autoDispose
    .family<List<ClassScheduleModel>, DateTime>((ref, date) async {
      final repository = ref.read(professorRepositoryProvider);
      return await repository.getScheduleByDate(date);
    });

final weekScheduleProvider =
    FutureProvider.autoDispose<List<ClassScheduleModel>>((ref) async {
      final repository = ref.read(professorRepositoryProvider);
      return await repository.getWeekSchedule();
    });

final earningsStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.read(professorRepositoryProvider);
  return await repository.getEarningsStats();
});

final professorSchedulesProvider =
    FutureProvider.autoDispose<List<ProfessorScheduleModel>>((ref) async {
      ref.watch(currentTenantIdProvider);
      final repository = ref.read(professorRepositoryProvider);
      return await repository.getMySchedules();
    });

class ProfessorNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
    required int experienceYears,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.updateProfile(
        name: name,
        phone: phone,
        specialties: specialties,
        hourlyRate: hourlyRate,
        experienceYears: experienceYears,
      );

      ref.invalidate(professorInfoProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> confirmClass(String classId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.confirmClass(classId);

      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelClass(String classId, String reason) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.cancelClass(classId, reason);

      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Map<String, dynamic>?> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String? courtId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      final tenantId = ref.read(currentTenantIdProvider);

      final result = await repository.createSchedule(
        date: date,
        startTime: startTime,
        endTime: endTime,
        tenantId:
            tenantId, // Pass tenantId if available, backend will use first active tenant
        courtId: courtId,
      );

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createSchedulesBatch({
    required List<Map<String, dynamic>> schedules,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      final tenantId = ref.read(currentTenantIdProvider);

      final result = await repository.createSchedulesBatch(
        schedules: schedules,
        tenantId: tenantId,
      );

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.deleteSchedule(scheduleId);

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeClass(
    String scheduleId, {
    double? paymentAmount,
    String? paymentStatus,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.completeClass(
        scheduleId,
        paymentAmount: paymentAmount,
        paymentStatus: paymentStatus,
      );

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(scheduleByDateProvider);
      ref.invalidate(earningsStatsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelBooking(
    String scheduleId, {
    String? reason,
    double? penaltyAmount,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(professorRepositoryProvider);
      await repository.cancelBooking(
        scheduleId,
        reason: reason,
        penaltyAmount: penaltyAmount,
      );

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(scheduleByDateProvider);
      ref.invalidate(earningsStatsProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshAll() async {
    ref.invalidate(professorInfoProvider);
    ref.invalidate(professorStudentsProvider);
    ref.invalidate(todayScheduleProvider);
    ref.invalidate(weekScheduleProvider);
    ref.invalidate(earningsStatsProvider);
    ref.invalidate(professorSchedulesProvider);
  }
}

final professorNotifierProvider =
    NotifierProvider<ProfessorNotifier, AsyncValue<void>>(() {
      return ProfessorNotifier();
    });

final isProfessorProvider = Provider<bool>((ref) {
  final professorInfo = ref.watch(professorInfoProvider);
  return professorInfo.when(
    data: (professor) => true,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});
