import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/professor_service.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/student_summary_model.dart';
import '../../domain/models/class_schedule_model.dart';
import '../../../../core/providers/tenant_provider.dart';

final professorServiceProvider = Provider<ProfessorService>((ref) {
  return ProfessorService();
});

final professorInfoProvider = FutureProvider.autoDispose<ProfessorModel>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getProfessorInfo();
});

final professorStudentsProvider =
    FutureProvider.autoDispose<List<StudentSummaryModel>>((ref) async {
      final service = ref.read(professorServiceProvider);
      return await service.getStudents();
    });

final todayScheduleProvider =
    FutureProvider.autoDispose<List<ClassScheduleModel>>((ref) async {
      final service = ref.read(professorServiceProvider);
      return await service.getTodaySchedule();
    });

final scheduleByDateProvider = FutureProvider.autoDispose
    .family<List<ClassScheduleModel>, DateTime>((ref, date) async {
      final service = ref.read(professorServiceProvider);
      return await service.getScheduleByDate(date);
    });

final weekScheduleProvider =
    FutureProvider.autoDispose<List<ClassScheduleModel>>((ref) async {
      final service = ref.read(professorServiceProvider);
      return await service.getWeekSchedule();
    });

final earningsStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getEarningsStats();
});

final professorSchedulesProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getMySchedules();
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
      final service = ref.read(professorServiceProvider);
      await service.updateProfile(
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
      final service = ref.read(professorServiceProvider);
      await service.confirmClass(classId);

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
      final service = ref.read(professorServiceProvider);
      await service.cancelClass(classId, reason);

      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      // Get current tenantId if available
      final tenantId = ref.read(currentTenantIdProvider);
      
      await service.createSchedule(
        date: date,
        startTime: startTime,
        endTime: endTime,
        tenantId: tenantId, // Pass tenantId if available, backend will use first active tenant if null
      );

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.deleteSchedule(scheduleId);

      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeClass(String scheduleId, {double? paymentAmount}) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.completeClass(scheduleId, paymentAmount: paymentAmount);

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
      final service = ref.read(professorServiceProvider);
      await service.cancelBooking(
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
