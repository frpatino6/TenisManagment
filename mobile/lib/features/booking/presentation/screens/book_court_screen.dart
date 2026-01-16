import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../payment/presentation/widgets/payment_dialog.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/logging/logger.dart';
import '../../domain/models/court_model.dart';
import '../../domain/services/court_service.dart';
import '../providers/booking_provider.dart';
import '../../../../core/providers/tenant_provider.dart';
import '../../../tenant/domain/services/tenant_service.dart' as tenant_domain;
import '../../../tenant/domain/models/tenant_model.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../../core/widgets/web_image.dart';

/// Provider for available tenants for dropdown selection
final availableTenantsProvider = FutureProvider.autoDispose<List<TenantModel>>((
  ref,
) async {
  final service = ref.watch(tenant_domain.tenantDomainServiceProvider);
  return service.getAvailableTenants();
});

class BookCourtScreen extends ConsumerStatefulWidget {
  const BookCourtScreen({super.key});

  @override
  ConsumerState<BookCourtScreen> createState() => _BookCourtScreenState();
}

class _BookCourtScreenState extends ConsumerState<BookCourtScreen> {
  final _logger = AppLogger.tag('BookCourtScreen');
  CourtModel? _selectedCourt;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;
  bool _shouldAutoConfirm = false; // Flag to prevent ghost bookings
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tenantState = ref.read(tenantNotifierProvider);
      tenantState.when(
        data: (favoriteTenantId) {
          if (favoriteTenantId != null) {
            final currentTenantId = ref.read(currentTenantIdProvider);
            if (currentTenantId != favoriteTenantId) {
              ref
                  .read(currentTenantIdProvider.notifier)
                  .update(favoriteTenantId);
            }
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    });
  }

  @override
  void dispose() {
    // Don't use ref in dispose - it's unsafe when the widget is being unmounted
    // The tenant will remain as the user selected it, which is acceptable behavior
    // If we need to restore the original tenant, it should be done before dispose
    // or through a different mechanism that doesn't rely on ref
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTenant = ref.watch(hasTenantProvider);
    final tenantState = ref.watch(tenantNotifierProvider);
    final courtsAsync = ref.watch(courtsProvider);

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

    if (tenantState.hasError) {
      return _buildNoTenantScreen(context);
    }

    if (!hasTenant) {
      return _buildNoTenantScreen(context);
    }

    // Automation Logic: Listen for confirmed bookings
    ref.listen(myBookingsProvider, (previous, next) {
      if (next.hasValue &&
          _selectedCourt != null &&
          _selectedDate != null &&
          _selectedTime != null) {
        // Calculate the same start time used for booking to match
        final startDateTime = DateTime.utc(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final booking = next.value!
            .where(
              (b) =>
                  b.courtId == _selectedCourt?.id &&
                  b.status == 'confirmed' &&
                  b.bookingDate?.isAtSameMomentAs(startDateTime) == true,
            )
            .firstOrNull;

        if (booking != null && mounted && !_isBooking) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reserva de cancha confirmada automáticamente!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      }
    });

    // Automation Logic: Listen for balance updates to trigger booking
    ref.listen(studentInfoProvider, (previous, next) {
      if (next.hasValue &&
          _selectedCourt != null &&
          _selectedDate != null &&
          _selectedTime != null) {
        final info = next.value!;
        final balance = (info['balance'] as num?)?.toDouble() ?? 0.0;

        // Re-calculate price
        final price = _selectedCourt!.pricePerHour; // 1 hour default

        if (balance >= price && !_isBooking && _shouldAutoConfirm) {
          _logger.info(
            'Saldo suficiente (Cancha) tras recarga. Iniciando reserva automática...',
          );
          _handleBooking();
        }
      }
    });

    final tenantAsync = ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reservar Cancha',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          courtsAsync.when(
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
          if (_isBooking)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const Gap(16),
                    Text(
                      'Procesando reserva...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Sincronizando con el centro...',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tenantAsync.when(
            data: (currentTenant) {
              if (currentTenant == null) return const SizedBox.shrink();
              return Column(
                children: [
                  if (currentTenant.logo != null &&
                      currentTenant.logo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WebImage(
                          imageUrl: currentTenant.logo!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 120,
                                width: double.infinity,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const Gap(4),
                                      Text(
                                        'Error al cargar imagen',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  if ((currentTenant.config?['address'] != null &&
                          currentTenant.config!['address']
                              .toString()
                              .isNotEmpty) ||
                      (currentTenant.config?['website'] != null &&
                          currentTenant.config!['website']
                              .toString()
                              .isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentTenant.config?['address'] != null &&
                                currentTenant.config!['address']
                                    .toString()
                                    .isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      currentTenant.config!['address']
                                          .toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (currentTenant.config?['address'] != null &&
                                currentTenant.config!['address']
                                    .toString()
                                    .isNotEmpty &&
                                currentTenant.config?['website'] != null &&
                                currentTenant.config!['website']
                                    .toString()
                                    .isNotEmpty)
                              const Gap(8),
                            if (currentTenant.config?['website'] != null &&
                                currentTenant.config!['website']
                                    .toString()
                                    .isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.language,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      currentTenant.config!['website']
                                          .toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  _buildTenantDropdown(context, currentTenant),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),

          Text(
            'Selecciona una cancha',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Gap(12),
          ...courts.map((court) => _buildCourtCard(context, court)),

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

  Widget _buildTenantDropdown(BuildContext context, TenantModel currentTenant) {
    final currentTenantId = ref.watch(currentTenantIdProvider);
    final tenantsAsync = ref.watch(availableTenantsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: tenantsAsync.when(
          data: (tenants) {
            if (tenants.isEmpty) {
              return Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      currentTenant.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }

            return DropdownButtonFormField<String>(
              initialValue: currentTenantId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Centro',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              selectedItemBuilder: (BuildContext context) {
                return tenants.map<Widget>((tenant) {
                  return Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          tenant.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              iconSize: 28,
              borderRadius: BorderRadius.circular(12),
              items: tenants.map((tenant) {
                final isSelected = tenant.id == currentTenantId;
                return DropdownMenuItem<String>(
                  value: tenant.id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (tenant.logo != null && tenant.logo!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              tenant.logo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.business,
                                    size: 20,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        else
                          Icon(
                            Icons.business,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            tenant.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newTenantId) async {
                if (newTenantId == null || newTenantId == currentTenantId) {
                  return;
                }

                try {
                  ref
                      .read(currentTenantIdProvider.notifier)
                      .update(newTenantId);

                  if (mounted) {
                    setState(() {
                      _selectedCourt = null;
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                    ref.invalidate(courtsProvider);
                  }

                  if (mounted && context.mounted) {
                    final selectedTenant = tenants.firstWhere(
                      (t) => t.id == newTenantId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Centro cambiado a ${selectedTenant.name}',
                        ),
                        duration: Timeouts.snackbarSuccess,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al cambiar centro: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                        duration: Timeouts.snackbarError,
                      ),
                    );
                  }
                }
              },
            );
          },
          loading: () => Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  currentTenant.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
          error: (error, stackTrace) => Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  currentTenant.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            _selectedTime = null;
          });

          if (_selectedDate != null) {
            ref.invalidate(
              courtAvailableSlotsProvider((
                courtId: court.id,
                date: _selectedDate!,
              )),
            );
          }

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
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
            // Invalidate available slots provider to reload for new date
            if (_selectedCourt != null) {
              ref.invalidate(
                courtAvailableSlotsProvider((
                  courtId: _selectedCourt!.id,
                  date: picked,
                )),
              );
            }
            // Scroll to bottom to show time selection with a slight delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              }
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
    if (_selectedCourt == null || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    final availableSlotsAsync = ref.watch(
      courtAvailableSlotsProvider((
        courtId: _selectedCourt!.id,
        date: _selectedDate!,
      )),
    );

    return availableSlotsAsync.when(
      data: (data) {
        var availableSlots =
            (data['availableSlots'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        final bookedSlots =
            (data['bookedSlots'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];

        // Filter past slots if selected date is today
        if (_selectedDate != null) {
          final now = DateTime.now();
          final isToday =
              _selectedDate!.year == now.year &&
              _selectedDate!.month == now.month &&
              _selectedDate!.day == now.day;

          if (isToday) {
            availableSlots = availableSlots.where((slot) {
              final parts = slot.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);

              final slotTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );

              return slotTime.isAfter(now);
            }).toList();
          }
        }

        if (availableSlots.isEmpty) {
          return Card(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'No hay horarios disponibles para esta fecha',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona un horario disponible',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSlots.map((slot) {
                final timeParts = slot.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);

                // Slots from backend are in local time (matching operatingHours)
                // Display them directly without conversion
                final timeOfDay = TimeOfDay(hour: hour, minute: minute);

                final isSelected =
                    _selectedTime?.hour == timeOfDay.hour &&
                    _selectedTime?.minute == timeOfDay.minute;

                return FilterChip(
                  label: Text(
                    timeOfDay.format(context),
                    style: GoogleFonts.inter(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTime = timeOfDay;
                      });
                      // Scroll to bottom to show booking summary with a slight delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && _scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            if (bookedSlots.isNotEmpty) ...[
              const Gap(12),
              Text(
                'Horarios ocupados: ${bookedSlots.join(", ")}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'Cargando horarios disponibles...',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        final errorMessage = error.toString();
        final isConfigError =
            errorMessage.contains('horarios de operación configurados') ||
            errorMessage.contains('no tiene horarios');

        return Card(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isConfigError ? Icons.settings : Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        isConfigError
                            ? 'El centro no tiene horarios configurados'
                            : 'Error al cargar horarios',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.invalidate(
                          courtAvailableSlotsProvider((
                            courtId: _selectedCourt!.id,
                            date: _selectedDate!,
                          )),
                        );
                      },
                    ),
                  ],
                ),
                if (!isConfigError) ...[
                  const Gap(8),
                  Text(
                    errorMessage,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ] else ...[
                  const Gap(8),
                  Text(
                    'Contacta al administrador del centro para configurar los horarios de operación.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
    // Default duration is 1 hour
    final price = _selectedCourt!.pricePerHour;

    return Consumer(
      builder: (context, ref, child) {
        final studentInfoAsync = ref.watch(studentInfoProvider);

        return studentInfoAsync.when(
          data: (info) {
            final balance = (info['balance'] as num?)?.toDouble() ?? 0.0;
            final isInsufficient = balance < price;
            final missingAmount = price - balance;

            if (isInsufficient) {
              return FilledButton.icon(
                onPressed: () =>
                    showDialog<String>(
                      context: context,
                      builder: (_) => PaymentDialog(
                        initialAmount: missingAmount,
                        bookingData: {
                          'courtId': _selectedCourt?.id,
                          'startTime': DateTime.utc(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          ).toIso8601String(),
                          'endTime': DateTime.utc(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour + 1, // Default 1 hour
                            _selectedTime!.minute,
                          ).toIso8601String(),
                          'serviceType': 'court_rental',
                          'price': price,
                        },
                      ),
                    ).then((transactionId) {
                      if (transactionId != null) {
                        if (mounted) {
                          setState(() {
                            _isBooking = true;
                            _shouldAutoConfirm = true;
                          });
                        }
                      }
                      ref.invalidate(studentInfoProvider);
                    }),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_card),
                label: const Text('Recargar y Reservar'),
              );
            }

            return FilledButton(
              onPressed: _isBooking ? null : _handleBooking,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          },
          loading: () => const FilledButton(
            onPressed: null,
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
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
      // Build start and end times using the selected local time
      // Convert to UTC when sending to backend
      if (_selectedTime == null) {
        throw Exception('Error: No se pudo determinar la hora seleccionada');
      }

      // The selected time is in the server's local timezone (matching operatingHours)
      // operatingHours are configured in the server's local time, so we create UTC directly
      // This ensures that 10:00 selected = 10:00 UTC stored (not 15:00 UTC)
      final startDateTime = DateTime.utc(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Default to 1 hour duration for court rental
      final endDateTime = startDateTime.add(const Duration(hours: 1));

      // Calculate price based on duration and price per hour
      final durationInHours = endDateTime.difference(startDateTime).inHours;
      final totalPrice = _selectedCourt!.pricePerHour * durationInHours;

      // Get court service and make booking
      final courtService = ref.read(courtServiceProvider);

      await courtService.bookCourt(
        courtId: _selectedCourt!.id,
        startTime: startDateTime,
        endTime: endDateTime,
        price: totalPrice,
      );

      // Invalidate providers to refresh data
      ref.invalidate(courtsProvider);
      ref.invalidate(studentBookingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reserva realizada exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            duration: Timeouts.snackbarSuccess,
          ),
        );

        // Reset selection
        setState(() {
          _selectedCourt = null;
          _selectedDate = null;
          _selectedTime = null;
        });

        // Navigate back after a short delay
        await Future.delayed(Timeouts.animationExtraLong);
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al realizar la reserva: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            duration: Timeouts.snackbarError,
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
