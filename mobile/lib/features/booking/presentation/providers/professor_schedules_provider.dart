import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/schedule_model.dart';
import '../../domain/services/schedule_service.dart';

enum TimePeriod {
  morning,
  afternoon,
  evening,
}

class SchedulePeriodGroup {
  final TimePeriod period;
  final List<ScheduleModel> schedules;

  SchedulePeriodGroup({
    required this.period,
    required this.schedules,
  });
}

class SelectedDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime?>(() {
  return SelectedDateNotifier();
});

final professorSchedulesDataProvider =
    FutureProvider.autoDispose.family<ProfessorSchedulesResponse, String>(
  (ref, professorId) async {
    final service = ref.read(scheduleServiceProvider);
    return await service.getProfessorSchedules(professorId);
  },
);

final availableDatesProvider = Provider.autoDispose
    .family<List<DateTime>, ProfessorSchedulesResponse>(
  (ref, schedulesData) {
    final dates = <DateTime>{};
    for (final tenantGroup in schedulesData.schedules) {
      for (final schedule in tenantGroup.schedules) {
        if (schedule.isAvailable) {
          final date = DateTime(
            schedule.startTime.year,
            schedule.startTime.month,
            schedule.startTime.day,
          );
          dates.add(date);
        }
      }
    }
    return dates.toList()..sort();
  },
);

final filteredSchedulesByDateProvider = Provider.autoDispose.family<
    Map<String, List<SchedulePeriodGroup>>,
    ProfessorSchedulesResponse>(
  (ref, schedulesData) {
    final selectedDate = ref.watch(selectedDateProvider);
    if (selectedDate == null) {
      return {};
    }

    final filteredByTenant = <String, List<ScheduleModel>>{};
    for (final tenantGroup in schedulesData.schedules) {
      final tenantSchedules = tenantGroup.schedules.where((schedule) {
        if (!schedule.isAvailable) return false;
        final scheduleDate = DateTime(
          schedule.startTime.year,
          schedule.startTime.month,
          schedule.startTime.day,
        );
        return scheduleDate.year == selectedDate.year &&
            scheduleDate.month == selectedDate.month &&
            scheduleDate.day == selectedDate.day;
      }).toList();

      if (tenantSchedules.isNotEmpty) {
        filteredByTenant[tenantGroup.tenantId] = tenantSchedules;
      }
    }

    final groupedByTenant = <String, List<SchedulePeriodGroup>>{};
    for (final entry in filteredByTenant.entries) {
      final morning = <ScheduleModel>[];
      final afternoon = <ScheduleModel>[];
      final evening = <ScheduleModel>[];

      for (final schedule in entry.value) {
        final hour = schedule.startTime.hour;
        if (hour < 12) {
          morning.add(schedule);
        } else if (hour < 18) {
          afternoon.add(schedule);
        } else {
          evening.add(schedule);
        }
      }

      final periods = <SchedulePeriodGroup>[];
      if (morning.isNotEmpty) {
        periods.add(SchedulePeriodGroup(
          period: TimePeriod.morning,
          schedules: morning..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ));
      }
      if (afternoon.isNotEmpty) {
        periods.add(SchedulePeriodGroup(
          period: TimePeriod.afternoon,
          schedules: afternoon..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ));
      }
      if (evening.isNotEmpty) {
        periods.add(SchedulePeriodGroup(
          period: TimePeriod.evening,
          schedules: evening..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ));
      }

      if (periods.isNotEmpty) {
        groupedByTenant[entry.key] = periods;
      }
    }

    return groupedByTenant;
  },
);

final tenantInfoProvider = Provider.autoDispose
    .family<TenantSchedulesGroup?, ProfessorSchedulesResponse>(
  (ref, schedulesData) {
    final selectedDate = ref.watch(selectedDateProvider);
    if (selectedDate == null || schedulesData.schedules.isEmpty) {
      return null;
    }
    return schedulesData.schedules.first;
  },
);
