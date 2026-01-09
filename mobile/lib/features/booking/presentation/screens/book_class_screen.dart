import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/constants/timeouts.dart';
import '../../domain/models/professor_model.dart';
import '../../domain/models/available_schedule_model.dart';
import '../../domain/models/service_type.dart';
import '../providers/booking_provider.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../../../core/providers/tenant_provider.dart';

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
    final hasTenant = ref.watch(hasTenantProvider);
    final professorsAsync = ref.watch(professorsProvider);
    final preferencesAsync = ref.watch(preferencesNotifierProvider);

    // Validate tenant first
    if (!hasTenant) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Reservar Clase',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(16),
                Text(
                  'Selecciona un centro primero',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(8),
                Text(
                  'Necesitas seleccionar un centro para poder reservar clases',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                FilledButton.icon(
                  onPressed: () => context.push('/select-tenant'),
                  icon: const Icon(Icons.business),
                  label: const Text('Seleccionar Centro'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          // Sort professors: favorites first
          final favoriteIds = preferencesAsync.maybeWhen(
            data: (prefs) => prefs.favoriteProfessors.map((p) => p.id).toSet(),
            orElse: () => <String>{},
          );

          final sortedProfessors = List<ProfessorBookingModel>.from(professors)
            ..sort((a, b) {
              final aIsFavorite = favoriteIds.contains(a.id);
              final bIsFavorite = favoriteIds.contains(b.id);
              if (aIsFavorite && !bIsFavorite) return -1;
              if (!aIsFavorite && bIsFavorite) return 1;
              return 0;
            });

          return _buildContent(context, sortedProfessors, favoriteIds);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ProfessorBookingModel> professors,
    Set<String> favoriteIds,
  ) {
    final favoriteProfessors = professors
        .where((p) => favoriteIds.contains(p.id))
        .toList();
    final otherProfessors = professors
        .where((p) => !favoriteIds.contains(p.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un profesor',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          const Gap(16),

          // Favorites section
          if (favoriteProfessors.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const Gap(8),
                Text(
                  'Mis Favoritos',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const Gap(12),
            ...favoriteProfessors.asMap().entries.map((entry) {
              final index = entry.key;
              final professor = entry.value;
              return _buildProfessorCard(professor, index, isFavorite: true);
            }),
            const Gap(24),
            if (otherProfessors.isNotEmpty)
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            const Gap(16),
          ],

          // Other professors
          if (otherProfessors.isNotEmpty) ...[
            ...otherProfessors.asMap().entries.map((entry) {
              final index = entry.key;
              final professor = entry.value;
              return _buildProfessorCard(
                professor,
                favoriteProfessors.length + index,
                isFavorite: false,
              );
            }),
          ],

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

  Widget _buildProfessorCard(
    ProfessorBookingModel professor,
    int index, {
    bool isFavorite = false,
  }) {
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
                  // Top Section: Avatar, Name, Favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    professor.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final isFavorite = ref
                                        .watch(preferencesNotifierProvider)
                                        .when(
                                          data: (preferences) => preferences
                                              .favoriteProfessors
                                              .any((p) => p.id == professor.id),
                                          loading: () => false,
                                          error: (_, _) => false,
                                        );
                                    return IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? colorScheme.error
                                            : colorScheme.onSurfaceVariant,
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(
                                                preferencesNotifierProvider
                                                    .notifier,
                                              )
                                              .toggleFavoriteProfessor(
                                                professor.id,
                                              );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isFavorite
                                                      ? 'Profesor eliminado de favoritos'
                                                      : 'Profesor agregado a favoritos',
                                                ),
                                                duration:
                                                    Timeouts.snackbarSuccess,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error: ${e.toString()}',
                                                ),
                                                backgroundColor:
                                                    colorScheme.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (isFavorite) ...[
                              const Gap(4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 10,
                                      color: colorScheme.error,
                                    ),
                                    const Gap(4),
                                    Text(
                                      'Favorito',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Gap(8),
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
                    ],
                  ),
                  if (professor.specialties.isNotEmpty) ...[
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: professor.specialties.take(3).map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            specialty,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const Gap(16),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  const Gap(16),
                  // Bottom Section: Price and Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desde',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            CurrencyUtils.format(
                              professor.pricing.courtRental.toDouble(),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '/professor/${professor.id}/schedules?name=${Uri.encodeComponent(professor.name)}',
                          );
                        },
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: Text(
                          'Ver horarios',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
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

    if (_selectedProfessor == null) return const SizedBox.shrink();

    return Column(
      children: ServiceType.values.map((serviceType) {
        final isSelected = _selectedServiceType == serviceType;
        final price = serviceType.getPrice(_selectedProfessor!.pricing);

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
                        CurrencyUtils.format(price),
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
                          CurrencyUtils.format(
                            _selectedServiceType.getPrice(
                              _selectedProfessor!.pricing,
                            ),
                          ),
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
      final price = _selectedServiceType.getPrice(_selectedProfessor!.pricing);

      await service.bookLesson(
        schedule.id,
        serviceType: _selectedServiceType.value,
        price: price,
      );

      if (!mounted) return;

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
          duration: Timeouts.snackbarSuccess,
        ),
      );

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
