import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/court_model.dart';
import '../providers/booking_provider.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../../tenant/domain/services/tenant_service.dart' as tenant_domain;
import '../../../tenant/domain/models/tenant_model.dart';

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

  Widget _buildContent(
    BuildContext context,
    List<CourtModel> courts,
    AsyncValue tenantAsync,
  ) {
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                      IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Cambiar centro',
                        onPressed: () => _showChangeTenantDialog(context),
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

  /// Show dialog to change tenant without modifying favorites
  Future<void> _showChangeTenantDialog(BuildContext context) async {
    try {
      // Load available tenants
      final service = ref.read(tenant_domain.tenantDomainServiceProvider);
      final tenants = await service.getAvailableTenants();

      if (tenants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay centros disponibles'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final currentTenantId = ref.read(currentTenantIdProvider);

      if (!mounted) return;

      // Show dialog with tenant list
      final selectedTenant = await showDialog<TenantModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Cambiar Centro',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                final isSelected = tenant.id == currentTenantId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: tenant.logo != null
                        ? ClipOval(
                            child: Image.network(
                              tenant.logo!,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                  ),
                  title: Text(
                    tenant.name,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: tenant.slug.isNotEmpty
                      ? Text(
                          tenant.slug,
                          style: GoogleFonts.inter(fontSize: 12),
                        )
                      : null,
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(tenant);
                  },
                  selected: isSelected,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (selectedTenant != null && selectedTenant.id != currentTenantId) {
        // Change tenant without modifying favorites
        await ref
            .read(tenantNotifierProvider.notifier)
            .setTenant(selectedTenant.id);

        // Reset selection
        if (mounted) {
          setState(() {
            _selectedCourt = null;
            _selectedDate = null;
            _selectedTime = null;
          });
        }

        // Invalidate providers to reload data with new tenant
        // The widget will automatically rebuild because it's watching these providers
        // Using Future.microtask to ensure the tenant change is processed first
        Future.microtask(() {
          ref.invalidate(courtsProvider);
          ref.invalidate(currentTenantProvider);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Centro cambiado a ${selectedTenant.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar centro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
