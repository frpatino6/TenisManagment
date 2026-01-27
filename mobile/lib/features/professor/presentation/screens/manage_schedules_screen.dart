import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../domain/models/professor_schedule_model.dart';
import '../providers/professor_provider.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../booking/domain/models/court_model.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

enum ScheduleFilter { all, available, blocked, booked }

class ManageSchedulesScreen extends ConsumerStatefulWidget {
  const ManageSchedulesScreen({super.key});

  @override
  ConsumerState<ManageSchedulesScreen> createState() =>
      _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends ConsumerState<ManageSchedulesScreen> {
  ScheduleFilter _selectedFilter = ScheduleFilter.all;
  List<CourtModel> _courts = [];
  bool _isLoadingCourts = false;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    setState(() {
      _isLoadingCourts = true;
    });

    try {
      final courtService = ref.read(courtServiceProvider);
      final courts = await courtService.getCourts();
      if (mounted) {
        setState(() {
          _courts = courts;
          _isLoadingCourts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(professorSchedulesProvider);
    final currentTenant = ref.watch(currentTenantProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AppStrings.mySchedulesTitle,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            currentTenant.when(
              data: (tenant) => tenant != null
                  ? Text(
                      tenant.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: schedulesAsync.when(
        data: (schedulesData) {
          if (schedulesData.isEmpty) {
            return _buildEmptyState(context);
          }

          final schedules = schedulesData;

          final available = schedules
              .where((s) => s.isAvailable && !s.isBlocked)
              .toList();
          final blocked = schedules.where((s) => s.isBlocked).toList();
          final booked = schedules
              .where(
                (s) => !s.isAvailable && !s.isBlocked && s.studentName != null,
              )
              .toList();

          List<ProfessorScheduleModel> filteredSchedules;
          switch (_selectedFilter) {
            case ScheduleFilter.available:
              filteredSchedules = available;
            case ScheduleFilter.blocked:
              filteredSchedules = blocked;
            case ScheduleFilter.booked:
              filteredSchedules = booked;
            case ScheduleFilter.all:
              filteredSchedules = schedules;
          }

          final schedulesByDay = _groupSchedulesByDay(filteredSchedules);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(professorSchedulesProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterButtons(
                    context,
                    available.length,
                    blocked.length,
                    booked.length,
                    schedules.length,
                  ),
                  const Gap(24),

                  if (filteredSchedules.isEmpty)
                    _buildNoResultsState(context)
                  else ...[
                    _buildSectionHeader(
                      context,
                      _getFilterTitle(),
                      _getFilterColor(),
                      filteredSchedules.length,
                    ),
                    const Gap(16),
                    ...schedulesByDay.entries.map((dayEntry) {
                      final dayDate = dayEntry.key;
                      final daySchedules = dayEntry.value;

                      return _buildDayAccordion(
                        context,
                        ref,
                        dayDate,
                        daySchedules,
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildFilterButtons(
    BuildContext context,
    int available,
    int blocked,
    int booked,
    int total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.filterByStatus,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const Gap(12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                context,
                AppStrings.booked,
                booked,
                Colors.blue,
                Icons.event_available,
                ScheduleFilter.booked,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                AppStrings.available,
                available,
                Colors.green,
                Icons.check_circle,
                ScheduleFilter.available,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                AppStrings.blocked,
                blocked,
                Colors.orange,
                Icons.block,
                ScheduleFilter.blocked,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                AppStrings.all,
                total,
                Colors.grey,
                Icons.list,
                ScheduleFilter.all,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
    ScheduleFilter filter,
  ) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const Gap(6),
          Text('$label ($count)'),
        ],
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : color,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  String _getFilterTitle() {
    switch (_selectedFilter) {
      case ScheduleFilter.available:
        return AppStrings.available;
      case ScheduleFilter.blocked:
        return AppStrings.blocked;
      case ScheduleFilter.booked:
        return AppStrings.booked;
      case ScheduleFilter.all:
        return AppStrings.allSchedules;
    }
  }

  Color _getFilterColor() {
    switch (_selectedFilter) {
      case ScheduleFilter.available:
        return Colors.green;
      case ScheduleFilter.blocked:
        return Colors.orange;
      case ScheduleFilter.booked:
        return Colors.blue;
      case ScheduleFilter.all:
        return Colors.grey;
    }
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const Gap(16),
            Text(
              AppStrings.noSchedules,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Gap(8),
            Text(
              AppStrings.noSchedulesWithFilter,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(12),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    WidgetRef ref,
    ProfessorScheduleModel schedule,
    int index,
    String type,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Color cardColor;
    IconData leadingIcon;

    switch (type) {
      case 'blocked':
        cardColor = Colors.orange;
        leadingIcon = Icons.block;
        break;
      case 'booked':
        cardColor = Colors.blue;
        leadingIcon = Icons.person;
        break;
      default:
        cardColor = Colors.green;
        leadingIcon = Icons.check_circle;
    }

    return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cardColor.withValues(alpha: 0.3), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(leadingIcon, color: cardColor),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            schedule.formattedTimeRange,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (schedule.studentName != null) ...[
                            const Gap(4),
                            Text(
                              '${AppStrings.student}: ${schedule.studentName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (schedule.isBlocked &&
                              schedule.blockReason != null) ...[
                            const Gap(4),
                            Text(
                              '🚫 ${schedule.blockReason}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (schedule.price != null)
                          Text(
                            '\$${schedule.price!.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        if (schedule.type != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(schedule.type!),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cardColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Gap(12),
                Row(
                  children: [
                    if (type == 'available') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showBlockDialog(context, ref, schedule),
                          icon: const Icon(Icons.block, size: 16),
                          label: Text(
                            AppStrings.block,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    if (type == 'blocked') ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _unblockSchedule(context, ref, schedule.id),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: Text(
                            'Desbloquear',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    if (type != 'booked') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _deleteSchedule(context, ref, schedule.id),
                          icon: const Icon(Icons.delete, size: 16),
                          label: Text(
                            'Eliminar',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
        .slideX(begin: -0.2, end: 0);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'individual':
        return 'Individual';
      case 'group':
        return 'Grupal';
      case 'court_rental':
        return 'Cancha';
      default:
        return type;
    }
  }

  Future<void> _showBlockDialog(
    BuildContext context,
    WidgetRef ref,
    ProfessorScheduleModel schedule,
  ) async {
    final reasonController = TextEditingController();
    String? selectedCourtId;

    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              AppStrings.blockSchedule,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${schedule.formattedDate}\n${schedule.formattedTimeRange}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(16),
                if (_isLoadingCourts)
                  const Center(child: CircularProgressIndicator())
                else if (_courts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Cancha (opcional)',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      initialValue: selectedCourtId,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'General (Todas)',
                            style: GoogleFonts.inter(),
                          ),
                        ),
                        ..._courts.map(
                          (court) => DropdownMenuItem<String>(
                            value: court.id,
                            child: Text(court.name, style: GoogleFonts.inter()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCourtId = value;
                        });
                      },
                    ),
                  ),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Motivo (opcional)',
                    hintText: 'Ej: Almuerzo, reunión, etc.',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.inter(),
                    hintStyle: GoogleFonts.inter(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text('Cancelar', style: GoogleFonts.inter()),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final service = ref.read(professorServiceProvider);
                          await service.blockSchedule(
                            schedule.id,
                            reasonController.text,
                            courtId: selectedCourtId,
                          );

                          ref.invalidate(professorSchedulesProvider);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Horario bloqueado exitosamente',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString(),
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Bloquear', style: GoogleFonts.inter()),
              ),
            ],
          );
        },
      ),
    );

    reasonController.dispose();
  }

  Future<void> _unblockSchedule(
    BuildContext context,
    WidgetRef ref,
    String scheduleId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Desbloquear Horario',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Quieres hacer este horario disponible nuevamente?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Desbloquear', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(professorServiceProvider);
        await service.unblockSchedule(scheduleId);

        ref.invalidate(professorSchedulesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Horario desbloqueado exitosamente',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: GoogleFonts.inter()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    String scheduleId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Horario',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar este horario?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final notifier = ref.read(professorNotifierProvider.notifier);
        await notifier.deleteSchedule(scheduleId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Horario eliminado exitosamente',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: GoogleFonts.inter()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              'No tienes horarios creados',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              'Usa el botón "Crear Horario" para agregar tu disponibilidad',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const Gap(16),
            Text(
              'Error al cargar horarios',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<ProfessorScheduleModel>> _groupSchedulesByDay(
    List<ProfessorScheduleModel> schedules,
  ) {
    final Map<DateTime, List<ProfessorScheduleModel>> grouped = {};

    for (final schedule in schedules) {
      final dayDate = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
      );

      if (!grouped.containsKey(dayDate)) {
        grouped[dayDate] = [];
      }
      grouped[dayDate]!.add(schedule);
    }

    for (final daySchedules in grouped.values) {
      daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return Map.fromEntries(
      sortedDays.map((day) => MapEntry(day, grouped[day]!)),
    );
  }

  Widget _buildDayAccordion(
    BuildContext context,
    WidgetRef ref,
    DateTime dayDate,
    List<ProfessorScheduleModel> daySchedules,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = dayDate == today;
    final isTomorrow = dayDate == today.add(const Duration(days: 1));

    String dayLabel;
    if (isToday) {
      dayLabel = 'Hoy';
    } else if (isTomorrow) {
      dayLabel = 'Mañana';
    } else {
      dayLabel = DateFormat('EEEE', 'es_ES').format(dayDate);
      dayLabel = dayLabel[0].toUpperCase() + dayLabel.substring(1);
    }

    final dateFormat = DateFormat('d MMM yyyy', 'es_ES');
    final formattedDate = dateFormat.format(dayDate);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: ExpansionTile(
        initiallyExpanded: isToday,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        collapsedBackgroundColor: isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: isToday
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dayLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (isToday) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'HOY',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(2),
                  Text(
                    formattedDate,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isToday
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            )
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (isToday
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.1))
                        .withValues(alpha: isToday ? 1.0 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${daySchedules.length} ${daySchedules.length == 1 ? 'horario' : 'horarios'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isToday ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        children: [
          const Gap(8),
          ...daySchedules.asMap().entries.map((entry) {
            final schedule = entry.value;
            String category = 'available';
            if (schedule.isBlocked) {
              category = 'blocked';
            } else if (!schedule.isAvailable && schedule.studentName != null) {
              category = 'booked';
            }

            return _buildScheduleCard(
              context,
              ref,
              schedule,
              entry.key,
              category,
            );
          }),
        ],
      ),
    );
  }
}
