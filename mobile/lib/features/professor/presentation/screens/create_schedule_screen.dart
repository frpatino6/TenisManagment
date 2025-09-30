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
  String _selectedType = 'individual';
  final _priceController = TextEditingController();

  bool _isCreating = false;
  bool _generateMultipleSlots = false;
  int _slotDuration = 60; // Duración en minutos

  @override
  void dispose() {
    _priceController.dispose();
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
              // Icono y descripción
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

              // Fecha
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

              // Hora de inicio y fin
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

              // Opción de generar múltiples slots
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

              // Tipo de clase
              Text(
                'Tipo de clase',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTypeChip('individual', 'Individual', Icons.person),
                  _buildTypeChip('group', 'Grupal', Icons.group),
                  _buildTypeChip(
                    'court_rental',
                    'Alquiler cancha',
                    Icons.sports_tennis,
                  ),
                ],
              ),

              const Gap(24),

              // Precio (opcional)
              Text(
                'Precio (opcional)',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                'Dejar vacío para usar tu tarifa por hora',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Precio personalizado',
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 16),
              ),

              const Gap(32),

              // Botón crear
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

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedType == value;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          const Gap(8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = value;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que la hora de fin sea después de la hora de inicio
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
      final price = _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text)
          : null;

      if (_generateMultipleSlots) {
        // Generar múltiples slots
        final slots = _generateTimeSlots(startDateTime, endDateTime);

        if (slots.isEmpty) {
          throw Exception(
            'No se pudieron generar slots con la configuración actual',
          );
        }

        // Crear cada slot
        for (final slot in slots) {
          await notifier.createSchedule(
            date: _selectedDate,
            startTime: slot['start']!,
            endTime: slot['end']!,
            type: _selectedType,
            price: price,
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
        // Crear un solo horario
        await notifier.createSchedule(
          date: _selectedDate,
          startTime: startDateTime,
          endTime: endDateTime,
          type: _selectedType,
          price: price,
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

      // No crear slot si excede el tiempo final
      if (currentEnd.isAfter(end)) {
        break;
      }

      slots.add({'start': currentStart, 'end': currentEnd});

      currentStart = currentEnd;
    }

    return slots;
  }
}
