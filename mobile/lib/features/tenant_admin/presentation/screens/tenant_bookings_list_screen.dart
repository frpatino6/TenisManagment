import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantBookingsListScreen extends ConsumerStatefulWidget {
  const TenantBookingsListScreen({super.key});

  @override
  ConsumerState<TenantBookingsListScreen> createState() =>
      _TenantBookingsListScreenState();
}

class _TenantBookingsListScreenState
    extends ConsumerState<TenantBookingsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(tenantBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              context.push('/tenant-admin-home/bookings/calendar');
            },
            tooltip: 'Vista de calendario',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              context.push('/tenant-admin-home/bookings/stats');
            },
            tooltip: 'Estadísticas',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context),
          Expanded(
            child: bookingsAsync.when(
              data: (data) {
                final bookings = data['bookings'] as List<TenantBookingModel>;
                final pagination = data['pagination'] as BookingPagination;

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron reservas con los filtros aplicados.',
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Mostrando ${bookings.length} de ${pagination.totalItems} reservas',
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            'Página ${pagination.currentPage} / ${pagination.totalPages}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: bookings.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return _buildBookingCard(context, bookings[index]);
                        },
                      ),
                    ),
                    _buildPaginationControls(context, pagination),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget.fromError(
                error,
                onRetry: () => ref.refresh(tenantBookingsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final currentStatus = ref.watch(bookingStatusFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar estudiante...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(bookingStudentSearchProvider.notifier).set("");
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (value) {
              ref.read(bookingStudentSearchProvider.notifier).set(value);
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('Todas', null, currentStatus == null),
              const Gap(8),
              _buildFilterChip(
                'Pendientes',
                'pending',
                currentStatus == 'pending',
              ),
              const Gap(8),
              _buildFilterChip(
                'Confirmadas',
                'confirmed',
                currentStatus == 'confirmed',
              ),
              const Gap(8),
              _buildFilterChip(
                'Completadas',
                'completed',
                currentStatus == 'completed',
              ),
              const Gap(8),
              _buildFilterChip(
                'Canceladas',
                'cancelled',
                currentStatus == 'cancelled',
              ),
            ],
          ),
        ),
        const Gap(8),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(bookingStatusFilterProvider.notifier).set(value);
        }
      },
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildBookingCard(BuildContext context, TenantBookingModel booking) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () async {
          final refresh = await context.push<bool>(
            '/tenant-admin-home/bookings/${booking.id}',
          );
          if (refresh == true) {
            ref.invalidate(tenantBookingsProvider);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.student.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                children: [
                  const Icon(Icons.sports_tennis, size: 16, color: Colors.grey),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      booking.court?.name ?? 'Sin cancha',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(16),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      booking.professor?.name ?? 'Sin profesor',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const Gap(4),
                  Text(
                    booking.date != null
                        ? '${booking.date!.day}/${booking.date!.month}/${booking.date!.year}'
                        : 'Sin fecha',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Gap(16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const Gap(4),
                  Text(
                    booking.startTime != null && booking.endTime != null
                        ? '${DateFormat('HH:mm').format(booking.startTime!)} - ${DateFormat('HH:mm').format(booking.endTime!)}'
                        : 'Sin horario',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.serviceType == 'court_rental'
                        ? 'Alquiler'
                        : 'Clase',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    CurrencyUtils.format(booking.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (booking.paymentStatus != 'paid' &&
                  booking.status != 'cancelled') ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmQuickBooking(context, booking),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Confirmar Pago'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmQuickBooking(
    BuildContext context,
    TenantBookingModel booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
          '¿Confirmar pago de ${CurrencyUtils.format(booking.price)} para ${booking.student.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Procesando pago...'),
            duration: Duration(seconds: 1),
          ),
        );

        await ref
            .read(tenantAdminServiceProvider)
            .confirmBooking(booking.id, paymentStatus: 'paid');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pago confirmado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(tenantBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPaginationControls(
    BuildContext context,
    BookingPagination pagination,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: pagination.hasPrevious
                ? () => ref
                      .read(bookingPageProvider.notifier)
                      .setPage(pagination.currentPage - 1)
                : null,
          ),
          Text('Página ${pagination.currentPage} de ${pagination.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: pagination.hasNext
                ? () => ref
                      .read(bookingPageProvider.notifier)
                      .setPage(pagination.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
