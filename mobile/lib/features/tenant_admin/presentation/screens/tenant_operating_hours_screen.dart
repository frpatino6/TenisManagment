import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/services/tenant_admin_service.dart';

class TenantOperatingHoursScreen extends ConsumerStatefulWidget {
  const TenantOperatingHoursScreen({super.key});

  @override
  ConsumerState<TenantOperatingHoursScreen> createState() =>
      _TenantOperatingHoursScreenState();
}

class _TenantOperatingHoursScreenState
    extends ConsumerState<TenantOperatingHoursScreen> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  final Set<int> _selectedDays = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _daysOfWeek = [
    {'value': 0, 'label': 'Domingo', 'short': 'Dom'},
    {'value': 1, 'label': 'Lunes', 'short': 'Lun'},
    {'value': 2, 'label': 'Martes', 'short': 'Mar'},
    {'value': 3, 'label': 'Miércoles', 'short': 'Mié'},
    {'value': 4, 'label': 'Jueves', 'short': 'Jue'},
    {'value': 5, 'label': 'Viernes', 'short': 'Vie'},
    {'value': 6, 'label': 'Sábado', 'short': 'Sáb'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tenantInfo = ref.watch(tenantInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios de Operación'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: tenantInfo.when(
        data: (tenant) {
          final operatingHours = tenant.config?.operatingHours;
          if (operatingHours != null) {
            _openTime = _parseTime(operatingHours.open);
            _closeTime = _parseTime(operatingHours.close);
            _selectedDays.clear();
            if (operatingHours.daysOfWeek != null) {
              _selectedDays.addAll(operatingHours.daysOfWeek!);
            }
          } else {
            _openTime ??= const TimeOfDay(hour: 6, minute: 0);
            _closeTime ??= const TimeOfDay(hour: 22, minute: 0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Horarios',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Define el horario de operación del centro. Los slots disponibles se generarán automáticamente desde la hora de apertura hasta la hora de cierre.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(24),
                  _buildTimeSelector(
                    context,
                    'Hora de Apertura',
                    _openTime ?? const TimeOfDay(hour: 6, minute: 0),
                    (time) => setState(() => _openTime = time),
                  ),
                  const Gap(16),
                  _buildTimeSelector(
                    context,
                    'Hora de Cierre',
                    _closeTime ?? const TimeOfDay(hour: 22, minute: 0),
                    (time) => setState(() => _closeTime = time),
                  ),
                  const Gap(24),
                  Text(
                    'Días de la Semana (Opcional)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Si no seleccionas días, el centro operará todos los días de la semana.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day['value']);
                      return FilterChip(
                        label: Text(day['short'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day['value'] as int);
                            } else {
                              _selectedDays.remove(day['value'] as int);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(tenantInfoProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onTimeSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onTimeSelected(selectedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _formatTime(time),
          style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _handleSave() async {
    if (_openTime == null || _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona las horas de apertura y cierre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(tenantAdminServiceProvider);
      final daysList = _selectedDays.isEmpty
          ? null
          : (_selectedDays.toList()..sort());
      final operatingHours = OperatingHours(
        open: _formatTime(_openTime!),
        close: _formatTime(_closeTime!),
        daysOfWeek: daysList,
      );

      await service.updateOperatingHours(operatingHours);

      ref.invalidate(tenantInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horarios actualizados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
