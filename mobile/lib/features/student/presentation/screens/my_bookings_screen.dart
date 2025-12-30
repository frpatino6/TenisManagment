import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/booking_model.dart';
import '../providers/student_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Reservas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(studentBookingsProvider);
            },
          ),
        ],
      ),
      body: ref
          .watch(studentBookingsProvider)
          .when(
            data: (bookings) {
              if (bookings.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildBookingsList(context, bookings);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _buildErrorState(context, error.toString()),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const Gap(24),
          Text(
            'No tienes reservas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Text(
            'Reserva tu primera clase de tenis',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: () => context.push('/book-class'),
            icon: const Icon(Icons.book_online),
            label: const Text('Reservar Clase'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const Gap(24),
          Text(
            'Error al cargar reservas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(studentBookingsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<BookingModel> bookings) {
    final upcomingBookings = bookings
        .where(
          (b) =>
              b.status == 'confirmed' &&
              DateTime.parse(b.schedule.startTime).isAfter(DateTime.now()),
        )
        .toList();

    final pastBookings = bookings
        .where(
          (b) =>
              b.status == 'confirmed' &&
              DateTime.parse(b.schedule.startTime).isBefore(DateTime.now()),
        )
        .toList();

    final cancelledBookings = bookings
        .where((b) => b.status == 'cancelled')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcomingBookings.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Próximas Clases',
              upcomingBookings.length,
            ),
            const Gap(12),
            ...upcomingBookings.map(
              (booking) =>
                  _buildBookingCard(context, booking, isUpcoming: true),
            ),
            const Gap(24),
          ],

          if (pastBookings.isNotEmpty) ...[
            _buildSectionHeader(context, 'Clases Pasadas', pastBookings.length),
            const Gap(12),
            ...pastBookings.map(
              (booking) =>
                  _buildBookingCard(context, booking, isUpcoming: false),
            ),
            const Gap(24),
          ],

          if (cancelledBookings.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Canceladas',
              cancelledBookings.length,
            ),
            const Gap(12),
            ...cancelledBookings.map(
              (booking) =>
                  _buildBookingCard(context, booking, isUpcoming: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking, {
    required bool isUpcoming,
  }) {
    final startTime = DateTime.parse(booking.schedule.startTime);
    final endTime = DateTime.parse(booking.schedule.endTime);
    final isToday =
        startTime.day == DateTime.now().day &&
        startTime.month == DateTime.now().month &&
        startTime.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    booking.professor.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isUpcoming && isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'HOY',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  _formatDate(startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.sports_tennis,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  _getServiceTypeText(booking.serviceType),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '\$${booking.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (booking.court != null) ...[
              const Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const Gap(8),
                  Text(
                    'Cancha: ${booking.court!.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (isUpcoming && booking.status == 'confirmed') ...[
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, booking),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingDetails(context, booking),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detalles'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeText(String serviceType) {
    switch (serviceType) {
      case 'individual_class':
        return 'Clase Individual';
      case 'group_class':
        return 'Clase Grupal';
      case 'court_rental':
        return 'Alquiler de Cancha';
      default:
        return serviceType;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (bookingDate == today) {
      return 'Hoy';
    } else if (bookingDate == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else if (bookingDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showCancelDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Text(
          '¿Estás seguro de que quieres cancelar tu clase con ${booking.professor.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelBooking(booking);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de la Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Profesor', booking.professor.name),
            _buildDetailRow(
              'Servicio',
              _getServiceTypeText(booking.serviceType),
            ),
            _buildDetailRow(
              'Fecha',
              _formatDate(DateTime.parse(booking.schedule.startTime)),
            ),
            _buildDetailRow(
              'Hora',
              '${_formatTime(DateTime.parse(booking.schedule.startTime))} - ${_formatTime(DateTime.parse(booking.schedule.endTime))}',
            ),
            _buildDetailRow('Precio', '\$${booking.price.toStringAsFixed(0)}'),
            _buildDetailRow('Estado', _getStatusText(booking.status)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  void _cancelBooking(BookingModel booking) {
    // TODO: Implement cancel booking functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de cancelación en desarrollo'),
      ),
    );
  }
}
