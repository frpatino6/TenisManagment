import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../domain/models/court_model.dart';
import '../providers/booking_provider.dart';
import '../../domain/services/court_service.dart';
import '../../../../core/providers/tenant_provider.dart';

/// Screen for booking a court directly (without professor)
class BookCourtScreen extends ConsumerStatefulWidget {
  const BookCourtScreen({super.key});

  @override
  ConsumerState<BookCourtScreen> createState() => _BookCourtScreenState();
}

class _BookCourtScreenState extends ConsumerState<BookCourtScreen> {
  CourtModel? _selectedCourt;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final hasTenant = ref.watch(hasTenantProvider);
    final tenantState = ref.watch(tenantNotifierProvider);
    final courtsAsync = ref.watch(courtsProvider);

    // Wait for tenant state to load before showing error
    if (tenantState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Reservar Cancha',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Validate tenant first
    if (!hasTenant) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Reservar Cancha',
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
                  'Necesitas seleccionar un centro para poder reservar canchas',
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
          'Reservar Cancha',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: courtsAsync.when(
        data: (courts) {
          if (courts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildContent(context, courts);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<CourtModel> courts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona una cancha',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
          const Gap(16),

          ...courts.asMap().entries.map((entry) {
            final index = entry.key;
            final court = entry.value;
            return _buildCourtCard(court, index);
          }),

          if (_selectedCourt != null) ...[
            const Gap(32),
            Text(
              'Fecha y hora',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const Gap(16),
            _buildDateTimeSelection(),
            const Gap(32),
            _buildBookingSummary(),
          ],

          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildCourtCard(CourtModel court, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCourt?.id == court.id;

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
            _selectedCourt = court;
            _selectedDate = null;
            _selectedStartTime = null;
            _selectedEndTime = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  _getCourtTypeIcon(court.type),
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            court.typeDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (court.features.isNotEmpty) ...[
                          const Gap(8),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const Gap(4),
                          Text(
                            '${court.features.length} características',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (court.description != null && court.description!.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        court.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    court.formattedPrice,
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
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideX(begin: -0.2, end: 0);
  }

  IconData _getCourtTypeIcon(String type) {
    switch (type) {
      case 'tennis':
        return Icons.sports_tennis;
      case 'padel':
        return Icons.sports;
      case 'multi':
        return Icons.sports_soccer;
      default:
        return Icons.sports_tennis;
    }
  }

  Widget _buildDateTimeSelection() {
    return Column(
      children: [
        // Date selection
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              _selectedDate == null
                  ? 'Seleccionar fecha'
                  : DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate!),
              style: GoogleFonts.inter(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                locale: const Locale('es', 'ES'),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
        ),
        const Gap(12),
        // Start time selection
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              _selectedStartTime == null
                  ? 'Hora de inicio'
                  : _selectedStartTime!.format(context),
              style: GoogleFonts.inter(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _selectedStartTime = time;
                  // Auto-set end time to 1 hour later
                  _selectedEndTime = TimeOfDay(
                    hour: (time.hour + 1) % 24,
                    minute: time.minute,
                  );
                });
              }
            },
          ),
        ),
        const Gap(12),
        // End time selection
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              _selectedEndTime == null
                  ? 'Hora de fin'
                  : _selectedEndTime!.format(context),
              style: GoogleFonts.inter(),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedStartTime ?? TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _selectedEndTime = time;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedCourt == null ||
        _selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate duration and price
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );
    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours + (duration.inMinutes % 60) / 60;
    final totalPrice = _selectedCourt!.pricePerHour * hours;

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de reserva',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(16),
            _buildSummaryRow('Cancha', _selectedCourt!.name),
            _buildSummaryRow('Tipo', _selectedCourt!.typeDisplayName),
            _buildSummaryRow(
              'Fecha',
              DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate!),
            ),
            _buildSummaryRow(
              'Horario',
              '${_selectedStartTime!.format(context)} - ${_selectedEndTime!.format(context)}',
            ),
            _buildSummaryRow('Duración', '${duration.inHours}h ${duration.inMinutes % 60}m'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isBooking ? null : () => _handleBooking(startDateTime, endDateTime, totalPrice),
                icon: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 20),
                label: Text(
                  _isBooking ? 'Reservando...' : 'Confirmar Reserva',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking(
    DateTime startTime,
    DateTime endTime,
    double price,
  ) async {
    if (_isBooking || _selectedCourt == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final service = ref.read(courtServiceProvider);
      await service.bookCourt(
        courtId: _selectedCourt!.id,
        startTime: startTime,
        endTime: endTime,
        price: price,
      );

      if (!mounted) return;

      // Invalidate courts to refresh list
      ref.invalidate(courtsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Cancha reservada exitosamente!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back
      context.pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al reservar: ${error.toString()}',
            style: GoogleFonts.inter(),
          ),
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
              Icons.sports_tennis_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              'No hay canchas disponibles',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              'No hay canchas disponibles en este centro en este momento',
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
              'Error al cargar canchas',
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
            const Gap(16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(courtsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

