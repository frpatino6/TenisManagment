import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/court_model.dart';
import '../providers/booking_provider.dart';
import '../../../../core/providers/tenant_provider.dart';

class BookCourtScreen extends ConsumerStatefulWidget {
  const BookCourtScreen({super.key});

  @override
  ConsumerState<BookCourtScreen> createState() => _BookCourtScreenState();
}

class _BookCourtScreenState extends ConsumerState<BookCourtScreen> {
  CourtModel? _selectedCourt;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final hasTenant = ref.watch(hasTenantProvider);
    final tenantState = ref.watch(tenantNotifierProvider);
    final tenantId = ref.watch(currentTenantIdProvider);
    final courtsAsync = ref.watch(courtsProvider);

    // Debug logging
    print('=== BookCourtScreen Debug ===');
    print('hasTenant: $hasTenant');
    print('tenantId: $tenantId');
    print('tenantState.isLoading: ${tenantState.isLoading}');
    print('tenantState.hasError: ${tenantState.hasError}');
    tenantState.when(
      data: (id) => print('tenantState.data: $id'),
      loading: () => print('tenantState: loading'),
      error: (e, st) => print('tenantState.error: $e'),
    );
    print('courtsAsync.isLoading: ${courtsAsync.isLoading}');
    print('courtsAsync.hasError: ${courtsAsync.hasError}');
    print('============================');

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

    // Check if tenant state has error (e.g., tenant was cleared)
    if (tenantState.hasError) {
      // If error, treat as no tenant
      return _buildNoTenantScreen(context);
    }

    // Validate tenant first
    if (!hasTenant) {
      return _buildNoTenantScreen(context);
    }

    final tenantAsync = ref.watch(currentTenantProvider);
    
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
          return _buildContent(context, courts, tenantAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          print('[BookCourtScreen] Error loading courts: $error');
          print('[BookCourtScreen] Stack trace: $stackTrace');
          return _buildErrorState(context, error);
        },
      ),
    );
  }

  Widget _buildNoTenantScreen(BuildContext context) {
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              'No hay canchas disponibles',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'No hay canchas disponibles en este centro en este momento',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final errorMessage = error.toString().contains('Tenant ID requerido')
        ? 'Selecciona un centro primero'
        : 'Error al cargar las canchas';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const Gap(16),
            Text(
              errorMessage,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            if (error.toString().contains('Tenant ID requerido'))
              FilledButton.icon(
                onPressed: () => context.push('/select-tenant'),
                icon: const Icon(Icons.business),
                label: const Text('Seleccionar Centro'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(courtsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<CourtModel> courts, AsyncValue tenantAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tenant info card
          tenantAsync.when(
            data: (tenant) {
              if (tenant == null) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              tenant.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Court selection
          Text(
            'Selecciona una cancha',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Gap(12),
          ...courts.map((court) => _buildCourtCard(context, court)).toList(),

          const Gap(24),

          // Date selection
          if (_selectedCourt != null) ...[
            Text(
              'Selecciona la fecha',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildDateSelector(context),

            const Gap(24),
          ],

          // Time selection
          if (_selectedDate != null) ...[
            Text(
              'Selecciona la hora',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildTimeSelector(context),

            const Gap(24),
          ],

          // Booking summary and button
          if (_selectedCourt != null &&
              _selectedDate != null &&
              _selectedTime != null) ...[
            _buildBookingSummary(context),
            const Gap(16),
            _buildBookButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCourtCard(BuildContext context, CourtModel court) {
    final isSelected = _selectedCourt?.id == court.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCourt = court;
            _selectedDate = null;
            _selectedTime = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis,
                  color: Theme.of(context).colorScheme.primary,
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
                    Text(
                      court.typeDisplayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (court.features.isNotEmpty) ...[
                      const Gap(4),
                      Wrap(
                        spacing: 8,
                        children: court.features
                            .take(3)
                            .map(
                              (feature) => Chip(
                                label: Text(
                                  feature,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${court.formattedPrice}/hora',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final firstDate = now;
          final lastDate = now.add(const Duration(days: 30));

          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? now,
            firstDate: firstDate,
            lastDate: lastDate,
            locale: const Locale('es', 'ES'),
          );

          if (picked != null) {
            setState(() {
              _selectedDate = picked;
              _selectedTime = null;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Selecciona una fecha',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
          );

          if (picked != null) {
            setState(() {
              _selectedTime = picked;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hora',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Selecciona una hora',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary(BuildContext context) {
    if (_selectedCourt == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de la reserva',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildSummaryRow(
              context,
              'Cancha',
              _selectedCourt!.name,
              Icons.sports_tennis,
            ),
            const Gap(8),
            _buildSummaryRow(
              context,
              'Fecha',
              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              Icons.calendar_today,
            ),
            const Gap(8),
            _buildSummaryRow(
              context,
              'Hora',
              _selectedTime!.format(context),
              Icons.access_time,
            ),
            const Gap(12),
            const Divider(),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Precio por hora',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _selectedCourt!.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const Gap(12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return FilledButton(
      onPressed: _isBooking ? null : _handleBooking,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isBooking
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              'Confirmar Reserva',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _handleBooking() async {
    if (_selectedCourt == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // TODO: Implement actual booking logic
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reserva realizada exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset selection
        setState(() {
          _selectedCourt = null;
          _selectedDate = null;
          _selectedTime = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al realizar la reserva: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }
}
