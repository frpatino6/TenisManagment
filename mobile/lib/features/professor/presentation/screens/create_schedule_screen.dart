import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/professor_provider.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() =>
      _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  bool _isCreating = false;
  bool _generateMultipleSlots = false;
  int _slotDuration = 60; // Duración en minutos

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crear Horario Disponible',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      child: Icon(
                        Icons.event_available,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'Define tu disponibilidad',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Los estudiantes podrán reservar en estos horarios',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Gap(32),

              Text(
                'Fecha',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(12),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: colorScheme.primary),
                      const Gap(12),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora inicio',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(12),
                        InkWell(
                          onTap: () => _selectTime(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                ),
                                const Gap(8),
                                Text(
                                  _startTime.format(context),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora fin',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(12),
                        InkWell(
                          onTap: () => _selectTime(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                ),
                                const Gap(8),
                                Text(
                                  _endTime.format(context),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(24),

              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Generar horarios automáticos',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _generateMultipleSlots,
                            onChanged: (value) {
                              setState(() {
                                _generateMultipleSlots = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_generateMultipleSlots) ...[
                        const Gap(16),
                        Text(
                          'Duración de cada slot',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Gap(8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildDurationChip(60, '1 hora'),
                            _buildDurationChip(90, '1.5 horas'),
                            _buildDurationChip(120, '2 horas'),
                            _buildDurationChip(180, '3 horas'),
                          ],
                        ),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  _getSlotGenerationInfo(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Gap(24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'Los estudiantes podrán elegir el tipo de servicio (clase individual, grupal o alquiler de cancha) al reservar este horario.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isCreating ? null : _handleCreate,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle),
                            const Gap(8),
                            Text(
                              'Crear Horario',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _slotDuration == minutes;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _slotDuration = minutes;
          });
        }
      },
      selectedColor: colorScheme.primary,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
    );
  }

  String _getSlotGenerationInfo() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      return 'Ajusta las horas de inicio y fin';
    }

    final totalMinutes = endDateTime.difference(startDateTime).inMinutes;
    final numberOfSlots = (totalMinutes / _slotDuration).floor();

    if (numberOfSlots == 0) {
      return 'El rango es muy corto para generar slots';
    }

    return 'Se generarán $numberOfSlots horarios de ${_slotDuration ~/ 60}h ${_slotDuration % 60 > 0 ? '${_slotDuration % 60}min' : ''}';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        
        final selectedDateOnly = DateTime(picked.year, picked.month, picked.day);
        final isToday = selectedDateOnly == today;
        
        if (isToday) {
          final currentTime = TimeOfDay.fromDateTime(now);
          if (_startTime.hour < currentTime.hour ||
              (_startTime.hour == currentTime.hour &&
                  _startTime.minute < currentTime.minute)) {
            _startTime = TimeOfDay(
              hour: currentTime.hour,
              minute: currentTime.minute,
            );
          }
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour &&
                  _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour,
              minute: _startTime.minute + 30,
            );
          }
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final isToday = selectedDateOnly == today;
    
    TimeOfDay? minTime;
    if (isStartTime && isToday) {
      final currentTime = TimeOfDay.fromDateTime(now);
      minTime = TimeOfDay(
        hour: currentTime.hour,
        minute: currentTime.minute,
      );
    } else if (!isStartTime && isToday) {
      final currentTime = TimeOfDay.fromDateTime(now);
      final minEndTime = TimeOfDay(
        hour: _startTime.hour,
        minute: _startTime.minute + 1,
      );
      
      if (minEndTime.hour < currentTime.hour ||
          (minEndTime.hour == currentTime.hour &&
              minEndTime.minute < currentTime.minute)) {
        minTime = TimeOfDay(
          hour: currentTime.hour,
          minute: currentTime.minute + 1,
        );
      } else {
        minTime = minEndTime;
      }
    } else if (!isStartTime) {
      minTime = TimeOfDay(
        hour: _startTime.hour,
        minute: _startTime.minute + 1,
      );
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      helpText: isToday && isStartTime
          ? 'No puedes seleccionar horas pasadas'
          : null,
    );

    if (picked != null) {
      if (minTime != null) {
        final pickedMinutes = picked.hour * 60 + picked.minute;
        final minMinutes = minTime.hour * 60 + minTime.minute;
        
        if (pickedMinutes < minMinutes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isToday
                    ? 'No puedes seleccionar horas pasadas'
                    : 'La hora debe ser después de la hora de inicio',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_endTime.hour < picked.hour ||
              (_endTime.hour == picked.hour &&
                  _endTime.minute <= picked.minute)) {
            _endTime = TimeOfDay(
              hour: picked.hour,
              minute: picked.minute + 30,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDateOnly.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes crear horarios en fechas pasadas',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startDateTime = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final nowUtc = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    if (selectedDateOnly == today && startDateTime.isBefore(nowUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes crear horarios en horas pasadas',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La hora de fin debe ser después de la hora de inicio',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final notifier = ref.read(professorNotifierProvider.notifier);

      if (_generateMultipleSlots) {
        final slots = _generateTimeSlots(startDateTime, endDateTime);

        if (slots.isEmpty) {
          throw Exception(
            'No se pudieron generar slots con la configuración actual',
          );
        }

        final nowUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        );

        for (final slot in slots) {
          if (selectedDateOnly == today &&
              slot['start']!.isBefore(nowUtc)) {
            continue;
          }

          final utcDate = DateTime.utc(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );
          await notifier.createSchedule(
            date: utcDate,
            startTime: slot['start']!,
            endTime: slot['end']!,
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡${slots.length} horarios creados exitosamente!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create UTC date at midnight for the selected date
        final utcDate = DateTime.utc(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        await notifier.createSchedule(
          date: utcDate,
          startTime: startDateTime,
          endTime: endDateTime,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Horario creado exitosamente!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, DateTime>> _generateTimeSlots(DateTime start, DateTime end) {
    final slots = <Map<String, DateTime>>[];
    DateTime currentStart = start;

    while (currentStart.isBefore(end)) {
      final currentEnd = currentStart.add(Duration(minutes: _slotDuration));

      if (currentEnd.isAfter(end)) {
        break;
      }

      slots.add({'start': currentStart, 'end': currentEnd});

      currentStart = currentEnd;
    }

    return slots;
  }
}
