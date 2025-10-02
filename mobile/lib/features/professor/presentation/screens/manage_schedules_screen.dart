import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/professor_schedule_model.dart';
import '../providers/professor_provider.dart';

enum ScheduleFilter { all, available, blocked, booked }

class ManageSchedulesScreen extends ConsumerStatefulWidget {
  const ManageSchedulesScreen({super.key});

  @override
  ConsumerState<ManageSchedulesScreen> createState() =>
      _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends ConsumerState<ManageSchedulesScreen> {
  ScheduleFilter _selectedFilter = ScheduleFilter.booked;

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(professorSchedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Horarios',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: schedulesAsync.when(
        data: (schedulesData) {
          if (schedulesData.isEmpty) {
            return _buildEmptyState(context);
          }

          // Convert to ProfessorScheduleModel
          final schedules = schedulesData
              .map(
                (data) => ProfessorScheduleModel.fromJson(
                  data as Map<String, dynamic>,
                ),
              )
              .toList();

          // Separar por estado
          final available = schedules
              .where((s) => s.isAvailable && !s.isBlocked)
              .toList();
          final blocked = schedules.where((s) => s.isBlocked).toList();
          final booked = schedules
              .where(
                (s) => !s.isAvailable && !s.isBlocked && s.studentName != null,
              )
              .toList();

          // Filtrar según selección
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(professorSchedulesProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter buttons
                  _buildFilterButtons(
                    context,
                    available.length,
                    blocked.length,
                    booked.length,
                    schedules.length,
                  ),
                  const Gap(24),

                  // Filtered schedules
                  if (filteredSchedules.isEmpty)
                    _buildNoResultsState(context)
                  else ...[
                    _buildSectionHeader(
                      context,
                      _getFilterTitle(),
                      _getFilterColor(),
                      filteredSchedules.length,
                    ),
                    const Gap(12),
                    ...filteredSchedules.asMap().entries.map((entry) {
                      final schedule = entry.value;
                      String category = 'available';
                      if (schedule.isBlocked) {
                        category = 'blocked';
                      } else if (!schedule.isAvailable &&
                          schedule.studentName != null) {
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
          'Filtrar por estado',
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
                'Reservados',
                booked,
                Colors.blue,
                Icons.event_available,
                ScheduleFilter.booked,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                'Disponibles',
                available,
                Colors.green,
                Icons.check_circle,
                ScheduleFilter.available,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                'Bloqueados',
                blocked,
                Colors.orange,
                Icons.block,
                ScheduleFilter.blocked,
              ),
              const Gap(8),
              _buildFilterChip(
                context,
                'Todos',
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
        return 'Disponibles';
      case ScheduleFilter.blocked:
        return 'Bloqueados';
      case ScheduleFilter.booked:
        return 'Reservados';
      case ScheduleFilter.all:
        return 'Todos los Horarios';
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
              'No hay horarios',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Gap(8),
            Text(
              'No se encontraron horarios con este filtro',
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
                              'Estudiante: ${schedule.studentName}',
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
                            'Bloquear',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bloquear Horario',
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Bloquear', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(professorServiceProvider);
        await service.blockSchedule(schedule.id, reasonController.text);

        ref.invalidate(professorSchedulesProvider);

        if (context.mounted) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: GoogleFonts.inter()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

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
}
