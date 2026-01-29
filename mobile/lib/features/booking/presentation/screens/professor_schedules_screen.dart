import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/schedule_model.dart';
import '../providers/professor_schedules_provider.dart';

class ProfessorSchedulesScreen extends ConsumerStatefulWidget {
  final String professorId;
  final String professorName;

  const ProfessorSchedulesScreen({
    super.key,
    required this.professorId,
    required this.professorName,
  });

  @override
  ConsumerState<ProfessorSchedulesScreen> createState() =>
      _ProfessorSchedulesScreenState();
}

class _ProfessorSchedulesScreenState
    extends ConsumerState<ProfessorSchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schedulesAsync = ref.read(
        professorSchedulesDataProvider(widget.professorId),
      );
      schedulesAsync.whenData((data) {
        final availableDates = ref.read(
          availableDatesProvider(data),
        );
        if (availableDates.isNotEmpty) {
          ref.read(selectedDateProvider.notifier).setDate(availableDates.first);
        }
      });
    });
  }

  void _selectSchedule(
    ScheduleModel schedule,
    TenantSchedulesGroup tenantGroup,
  ) {
    context.push(
      '/confirm-booking',
      extra: {
        'schedule': schedule,
        'professorId': widget.professorId,
        'professorName': widget.professorName,
        'tenantId': tenantGroup.tenantId,
        'tenantName': tenantGroup.tenantName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(
      professorSchedulesDataProvider(widget.professorId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Horarios de ${widget.professorName}'),
      ),
      body: schedulesAsync.when(
        data: (schedulesData) {
          if (schedulesData.schedules.isEmpty) {
            return _buildEmptyState(context);
          }

          final availableDates = ref.watch(availableDatesProvider(schedulesData));
          final selectedDate = ref.watch(selectedDateProvider);
          final filteredSchedules = ref.watch(
            filteredSchedulesByDateProvider(schedulesData),
          );

          if (availableDates.isEmpty) {
            return _buildEmptyState(context);
          }

          if (selectedDate == null && availableDates.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedDateProvider.notifier).setDate(availableDates.first);
            });
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildCalendarStrip(
                context,
                availableDates,
                selectedDate ?? availableDates.first,
              ),
              Expanded(
                child: filteredSchedules.isEmpty
                    ? _buildEmptyDayState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(
                            professorSchedulesDataProvider(widget.professorId),
                          );
                        },
                        child: _buildSchedulesContent(
                          context,
                          schedulesData,
                          filteredSchedules,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildCalendarStrip(
    BuildContext context,
    List<DateTime> availableDates,
    DateTime selectedDate,
  ) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = selectedDate.year == date.year &&
              selectedDate.month == date.month &&
              selectedDate.day == date.day;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildDateCard(context, date, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    DateTime date,
    bool isSelected,
  ) {
    final dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final dayName = dayNames[date.weekday % 7];

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).setDate(date);
      },
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesContent(
    BuildContext context,
    ProfessorSchedulesResponse schedulesData,
    Map<String, List<SchedulePeriodGroup>> filteredSchedules,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedulesData.schedules.length,
      itemBuilder: (context, index) {
        final tenantGroup = schedulesData.schedules[index];
        final tenantPeriods = filteredSchedules[tenantGroup.tenantId];

        if (tenantPeriods == null || tenantPeriods.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildTenantSection(
          context,
          tenantGroup,
          tenantPeriods,
        );
      },
    );
  }

  Widget _buildTenantSection(
    BuildContext context,
    TenantSchedulesGroup tenantGroup,
    List<SchedulePeriodGroup> periods,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (tenantGroup.tenantLogo != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(tenantGroup.tenantLogo!),
                    radius: 20,
                  )
                else
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 20,
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tenantGroup.tenantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: periods.map((periodGroup) {
                return _buildPeriodSection(
                  context,
                  tenantGroup,
                  periodGroup,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(
    BuildContext context,
    TenantSchedulesGroup tenantGroup,
    SchedulePeriodGroup periodGroup,
  ) {
    String periodTitle;
    IconData periodIcon;

    switch (periodGroup.period) {
      case TimePeriod.morning:
        periodTitle = 'Mañana';
        periodIcon = Icons.wb_sunny;
        break;
      case TimePeriod.afternoon:
        periodTitle = 'Tarde';
        periodIcon = Icons.wb_twilight;
        break;
      case TimePeriod.evening:
        periodTitle = 'Noche';
        periodIcon = Icons.nightlight;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              periodIcon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              periodTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: periodGroup.schedules.map((schedule) {
            return _buildTimeSlotChip(
              context,
              schedule,
              tenantGroup,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeSlotChip(
    BuildContext context,
    ScheduleModel schedule,
    TenantSchedulesGroup tenantGroup,
  ) {
    final startHour = schedule.startTime.hour.toString().padLeft(2, '0');
    final startMinute = schedule.startTime.minute.toString().padLeft(2, '0');
    final timeLabel = '$startHour:$startMinute';

    return ActionChip(
      label: Text(timeLabel),
      onPressed: () => _selectSchedule(schedule, tenantGroup),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay horarios disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Este profesor no tiene horarios disponibles en este momento',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'El profe descansa este día',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No hay horarios disponibles para la fecha seleccionada',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar horarios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(
                professorSchedulesDataProvider(widget.professorId),
              );
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

