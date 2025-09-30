import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/professor_service.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/student_summary_model.dart';
import '../../domain/models/class_schedule_model.dart';

// Provider para el servicio del profesor
final professorServiceProvider = Provider<ProfessorService>((ref) {
  return ProfessorService();
});

// Provider para la información del profesor
final professorInfoProvider = FutureProvider<ProfessorModel>((ref) async {
  final service = ref.read(professorServiceProvider);
  return await service.getProfessorInfo();
});

// Provider para la lista de estudiantes
final professorStudentsProvider = FutureProvider<List<StudentSummaryModel>>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getStudents();
});

// Provider para el horario de hoy
final todayScheduleProvider = FutureProvider<List<ClassScheduleModel>>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getTodaySchedule();
});

// Provider para el horario de una fecha específica
final scheduleByDateProvider =
    FutureProvider.family<List<ClassScheduleModel>, DateTime>((
      ref,
      date,
    ) async {
      final service = ref.read(professorServiceProvider);
      return await service.getScheduleByDate(date);
    });

// Provider para el horario de la semana
final weekScheduleProvider = FutureProvider<List<ClassScheduleModel>>((
  ref,
) async {
  final service = ref.read(professorServiceProvider);
  return await service.getWeekSchedule();
});

// Provider para las estadísticas de ganancias
final earningsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(professorServiceProvider);
  return await service.getEarningsStats();
});

// Provider para todos los horarios del profesor
final professorSchedulesProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(professorServiceProvider);
  return await service.getMySchedules();
});

// Notifier para manejar acciones del profesor
class ProfessorNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // Actualizar perfil del profesor
  Future<void> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.updateProfile(
        name: name,
        phone: phone,
        specialties: specialties,
        hourlyRate: hourlyRate,
      );

      // Invalidar providers para refrescar datos
      ref.invalidate(professorInfoProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Confirmar clase
  Future<void> confirmClass(String classId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.confirmClass(classId);

      // Invalidar providers para refrescar datos
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Cancelar clase
  Future<void> cancelClass(String classId, String reason) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.cancelClass(classId, reason);

      // Invalidar providers para refrescar datos
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Crear horario disponible
  Future<void> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required String type,
    double? price,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.createSchedule(
        date: date,
        startTime: startTime,
        endTime: endTime,
        type: type,
        price: price,
      );

      // Invalidar providers para refrescar datos
      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Eliminar horario
  Future<void> deleteSchedule(String scheduleId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(professorServiceProvider);
      await service.deleteSchedule(scheduleId);

      // Invalidar providers para refrescar datos
      ref.invalidate(professorSchedulesProvider);
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(weekScheduleProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Refrescar todos los datos
  Future<void> refreshAll() async {
    ref.invalidate(professorInfoProvider);
    ref.invalidate(professorStudentsProvider);
    ref.invalidate(todayScheduleProvider);
    ref.invalidate(weekScheduleProvider);
    ref.invalidate(earningsStatsProvider);
    ref.invalidate(professorSchedulesProvider);
  }
}

// Provider para el notifier del profesor
final professorNotifierProvider =
    NotifierProvider<ProfessorNotifier, AsyncValue<void>>(() {
      return ProfessorNotifier();
    });

// Provider para verificar si el usuario es profesor
final isProfessorProvider = Provider<bool>((ref) {
  final professorInfo = ref.watch(professorInfoProvider);
  return professorInfo.when(
    data: (professor) => true,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});
