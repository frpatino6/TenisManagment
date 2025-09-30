import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/models/service_type.dart';
import '../providers/booking_provider.dart';

class BookClassScreen extends ConsumerStatefulWidget {
  const BookClassScreen({super.key});

  @override
  ConsumerState<BookClassScreen> createState() => _BookClassScreenState();
}

class _BookClassScreenState extends ConsumerState<BookClassScreen> {
  ProfessorBookingModel? _selectedProfessor;
  AvailableScheduleModel? _selectedSchedule;
  ServiceType _selectedServiceType = ServiceType.individualClass;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final professorsAsync = ref.watch(professorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reservar Clase',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: professorsAsync.when(
        data: (professors) {
          if (professors.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildContent(context, professors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ProfessorBookingModel> professors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professor selection
          Text(
            'Selecciona un profesor',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          const Gap(16),

          ...professors.asMap().entries.map((entry) {
            final index = entry.key;
            final professor = entry.value;
            return _buildProfessorCard(professor, index);
          }),

          if (_selectedProfessor != null) ...[
            const Gap(32),
            Text(
              'Tipo de servicio',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const Gap(16),
            _buildServiceTypeSelection(),
            const Gap(32),
            Text(
              'Horarios disponibles',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const Gap(16),
            _buildScheduleSelection(),
          ],

          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildProfessorCard(ProfessorBookingModel professor, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedProfessor?.id == professor.id;

    return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedProfessor = professor;
                _selectedSchedule =
                    null; // Reset schedule when changing professor
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            professor.name.isNotEmpty
                                ? professor.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professor.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                const Gap(4),
                                Text(
                                  professor.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Gap(12),
                                Icon(
                                  Icons.work_outline,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const Gap(4),
                                Text(
                                  '${professor.experienceYears} años',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${professor.hourlyRate.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            'por hora',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (professor.specialties.isNotEmpty) ...[
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: professor.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            specialty,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildServiceTypeSelection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: ServiceType.values.map((serviceType) {
        final isSelected = _selectedServiceType == serviceType;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedServiceType = serviceType;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getServiceTypeIcon(serviceType),
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceType.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          _getServiceTypeDescription(serviceType),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${serviceType.defaultPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'por hora',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getServiceTypeIcon(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.individualClass:
        return Icons.person;
      case ServiceType.groupClass:
        return Icons.groups;
      case ServiceType.courtRental:
        return Icons.sports_tennis;
    }
  }

  String _getServiceTypeDescription(ServiceType serviceType) {
    switch (serviceType) {
      case ServiceType.individualClass:
        return 'Clase personalizada 1 a 1';
      case ServiceType.groupClass:
        return 'Clase grupal (máx. 4 personas)';
      case ServiceType.courtRental:
        return 'Solo alquiler de cancha';
    }
  }

  Widget _buildScheduleSelection() {
    if (_selectedProfessor == null) return const SizedBox.shrink();

    final schedulesAsync = ref.watch(
      availableSchedulesProvider(_selectedProfessor!.id),
    );

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const Gap(16),
                  Text(
                    'No hay horarios disponibles',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return _buildScheduleCard(schedule, index);
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const Gap(16),
              Text(
                'Error al cargar horarios',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(AvailableScheduleModel schedule, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBookingThisSchedule =
        _isBooking && _selectedSchedule?.id == schedule.id;

    return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: colorScheme.primary,
                      ),
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
                              color: colorScheme.onSurface,
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
                          const Gap(2),
                          Text(
                            '${schedule.durationInMinutes} minutos',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_selectedServiceType.defaultPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          _selectedServiceType.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: isBookingThisSchedule
                        ? null
                        : () => _handleBookingForSchedule(schedule),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isBookingThisSchedule
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 20),
                    label: Text(
                      isBookingThisSchedule ? 'Reservando...' : 'Reservar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, end: 0);
  }

  Future<void> _handleBookingForSchedule(
    AvailableScheduleModel schedule,
  ) async {
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
      _selectedSchedule = schedule;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      await service.bookLesson(
        schedule.id,
        serviceType: _selectedServiceType.value,
        price: _selectedServiceType.defaultPrice,
      );

      if (!mounted) return;

      // Invalidate providers to refresh data
      ref.invalidate(professorsProvider);
      if (_selectedProfessor != null) {
        ref.invalidate(availableSchedulesProvider(_selectedProfessor!.id));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Clase reservada exitosamente!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset state after successful booking
      setState(() {
        _isBooking = false;
        _selectedSchedule = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isBooking = false;
        _selectedSchedule = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              'No hay profesores disponibles',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const Gap(16),
            Text(
              'Error al cargar profesores',
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
