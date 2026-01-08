import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../providers/tenant_admin_provider.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app_error;
import '../../domain/models/tenant_booking_model.dart';
import 'package:intl/intl.dart';

class TenantBookingsListScreen extends ConsumerWidget {
  const TenantBookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(tenantBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // TODO: Navigate to calendar view
            },
            tooltip: 'Vista de calendario',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Navigate to stats view
            },
            tooltip: 'Estadísticas',
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (data) {
          final bookings = data['bookings'] as List<TenantBookingModel>;
          final pagination = data['pagination'] as BookingPagination;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const Gap(16),
                  Text(
                    'No hay reservas',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      'Total',
                      pagination.total.toString(),
                      Icons.event,
                    ),
                    _buildSummaryItem(
                      context,
                      'Página',
                      '${pagination.page}/${pagination.totalPages}',
                      Icons.pages,
                    ),
                  ],
                ),
              ),

              // Bookings list
              Expanded(
                child: ListView.builder(
                  itemCount: bookings.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(context, booking, ref);
                  },
                ),
              ),

              // Pagination controls
              if (pagination.totalPages > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: pagination.hasPreviousPage
                            ? () {
                                // TODO: Update page provider
                              }
                            : null,
                      ),
                      Text(
                        'Página ${pagination.page} de ${pagination.totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: pagination.hasNextPage
                            ? () {
                                // TODO: Update page provider
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => app_error.ErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(tenantBookingsProvider),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const Gap(4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    TenantBookingModel booking,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    Color statusColor;
    IconData statusIcon;
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          booking.student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(4),
            if (booking.date != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const Gap(4),
                  Text(dateFormat.format(booking.date!)),
                  if (booking.startTime != null) ...[
                    const Gap(8),
                    const Icon(Icons.access_time, size: 14),
                    const Gap(4),
                    Text(timeFormat.format(booking.startTime!)),
                  ],
                ],
              ),
            const Gap(4),
            if (booking.court != null)
              Row(
                children: [
                  const Icon(Icons.sports_tennis, size: 14),
                  const Gap(4),
                  Text('${booking.court!.name} (${booking.court!.type})'),
                ],
              ),
            if (booking.professor != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 14),
                  const Gap(4),
                  Text(booking.professor!.name),
                ],
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${booking.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              _getServiceTypeLabel(booking.serviceType),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to booking details
        },
      ),
    );
  }

  String _getServiceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'individual_class':
        return 'Clase individual';
      case 'group_class':
        return 'Clase grupal';
      case 'court_rental':
        return 'Alquiler cancha';
      default:
        return serviceType;
    }
  }
}
