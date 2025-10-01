import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/professor_provider.dart';

class ScheduleWidget extends ConsumerStatefulWidget {
  const ScheduleWidget({super.key});

  @override
  ConsumerState<ScheduleWidget> createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends ConsumerState<ScheduleWidget> {
  late DateTime _selectedDate;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con la fecha de hoy (sin hora)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousDay() {
    setState(() {
      final newDate = _selectedDate.subtract(const Duration(days: 1));
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      _showAll = false; // Reset when changing date
    });
  }

  void _nextDay() {
    setState(() {
      final newDate = _selectedDate.add(const Duration(days: 1));
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      _showAll = false; // Reset when changing date
    });
  }

  void _toggleShowAll() {
    setState(() {
      _showAll = !_showAll;
    });
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return 'Hoy';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return DateFormat('EEE d MMM').format(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use scheduleByDateProvider to filter schedules by selected date
    final scheduleAsync = ref.watch(scheduleByDateProvider(_selectedDate));

    return scheduleAsync.when(
      data: (todayClasses) {
        if (todayClasses.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horarios',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _previousDay,
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  color: colorScheme.primary,
                                ),
                                const Gap(8),
                                Text(
                                  _getDateLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const Gap(8),
                                IconButton(
                                  onPressed: _nextDay,
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '0 clases',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido vacío
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const Gap(16),
                      Text(
                        'No tienes clases programadas para hoy',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horarios',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _previousDay,
                                icon: const Icon(Icons.chevron_left, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                                color: colorScheme.primary,
                              ),
                              const Gap(8),
                              Text(
                                _getDateLabel(),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const Gap(8),
                              IconButton(
                                onPressed: _nextDay,
                                icon: const Icon(Icons.chevron_right, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${todayClasses.length} clases',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de clases (mostrar 3 o todas según _showAll)
              ...(_showAll ? todayClasses : todayClasses.take(3).toList())
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final classData = entry.value;
                    final isLast = _showAll
                        ? index == todayClasses.length - 1
                        : index == 2 || index == todayClasses.length - 1;

                    return _buildClassItem(context, classData, isLast: isLast)
                        .animate()
                        .slideX(
                          duration: 600.ms,
                          curve: Curves.easeOut,
                          delay: (index * 100).ms,
                        )
                        .fadeIn(duration: 400.ms, delay: (index * 100).ms);
                  }),

              // Botón "Ver más/menos" si hay más de 3 clases
              if (todayClasses.length > 3)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: _toggleShowAll,
                    icon: Icon(
                      _showAll ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      _showAll
                          ? 'Ver menos'
                          : 'Ver ${todayClasses.length - 3} más',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error al cargar horarios: $error',
              style: GoogleFonts.inter(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassItem(
    BuildContext context,
    classData, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Indicador de tiempo
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),

          // Información de la clase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      classData.formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Confirmada',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  classData.studentName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Gap(2),
                Text(
                  '${classData.type} • ${classData.formattedDuration}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón completar
              IconButton(
                onPressed: () => _showCompleteDialog(context, classData),
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Completar clase',
              ),
              // Botón cancelar
              IconButton(
                onPressed: () => _showCancelDialog(context, classData),
                icon: const Icon(Icons.cancel, color: Colors.orange),
                tooltip: 'Cancelar reserva',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCompleteDialog(BuildContext context, classData) async {
    // Pre-fill with booking price if available
    final paymentController = TextEditingController(
      text: classData.price > 0 ? classData.price.toStringAsFixed(0) : '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Completar Clase',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiante: ${classData.studentName}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            if (classData.type != null) ...[
              const Gap(4),
              Text(
                'Servicio: ${classData.type}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Gap(16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto pagado',
                hintText: 'Ej: 50000',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.inter(),
                hintStyle: GoogleFonts.inter(),
                helperText: 'Valor sugerido según el servicio reservado',
                helperStyle: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Completar', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final notifier = ref.read(professorNotifierProvider.notifier);
        final paymentAmount = paymentController.text.isNotEmpty
            ? double.tryParse(paymentController.text)
            : null;

        await notifier.completeClass(
          classData.id,
          paymentAmount: paymentAmount,
        );

        // Force refresh of the schedule for the current date
        ref.invalidate(scheduleByDateProvider(_selectedDate));
        // Refresh earnings if payment was recorded
        if (paymentAmount != null && paymentAmount > 0) {
          ref.invalidate(earningsStatsProvider);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                paymentAmount != null
                    ? 'Clase completada y pago de \$${paymentAmount.toStringAsFixed(0)} registrado'
                    : 'Clase marcada como completada',
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

    paymentController.dispose();
  }

  Future<void> _showCancelDialog(BuildContext context, classData) async {
    final reasonController = TextEditingController();
    final paymentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancelar Reserva',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiante: ${classData.studentName}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            const Gap(16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Enfermedad, emergencia, etc.',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.inter(),
                hintStyle: GoogleFonts.inter(),
              ),
              maxLines: 2,
            ),
            const Gap(16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto de penalización (opcional)',
                hintText: 'Ej: 25000',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                labelStyle: GoogleFonts.inter(),
                hintStyle: GoogleFonts.inter(),
                helperText: 'Si aplica cargo por cancelación tardía',
                helperStyle: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Volver', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Cancelar Reserva', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final notifier = ref.read(professorNotifierProvider.notifier);
        final penaltyAmount = paymentController.text.isNotEmpty
            ? double.tryParse(paymentController.text)
            : null;

        await notifier.cancelBooking(
          classData.id,
          reason: reasonController.text,
          penaltyAmount: penaltyAmount,
        );

        // Force refresh of the schedule for the current date
        ref.invalidate(scheduleByDateProvider(_selectedDate));
        // Refresh earnings if penalty was charged
        if (penaltyAmount != null && penaltyAmount > 0) {
          ref.invalidate(earningsStatsProvider);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                penaltyAmount != null
                    ? 'Reserva cancelada. Penalización de \$${penaltyAmount.toStringAsFixed(0)} registrada.'
                    : 'Reserva cancelada. El horario queda disponible nuevamente.',
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
    paymentController.dispose();
  }
}
