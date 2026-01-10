import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../domain/models/tenant_professor_model.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/utils/currency_utils.dart';

class ProfessorScheduleTab extends ConsumerWidget {
  final TenantProfessorModel professor;

  const ProfessorScheduleTab({super.key, required this.professor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(professorBookingsProvider(professor.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const Gap(16),
                Text(
                  'Sin reservas',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(8),
                Text(
                  'No hay reservas programadas para ${professor.name}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group bookings by date
        final groupedBookings = <DateTime, List<TenantBookingModel>>{};
        for (final booking in bookings) {
          if (booking.date != null) {
            final dateKey = DateTime(
              booking.date!.year,
              booking.date!.month,
              booking.date!.day,
            );
            groupedBookings.putIfAbsent(dateKey, () => []).add(booking);
          }
        }

        // Sort dates
        final sortedDates = groupedBookings.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayBookings = groupedBookings[date]!;

            // Sort bookings by start time
            dayBookings.sort((a, b) {
              if (a.startTime == null || b.startTime == null) return 0;
              return a.startTime!.compareTo(b.startTime!);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const Gap(24),
                _buildDateHeader(context, date),
                const Gap(12),
                ...dayBookings.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBookingCard(context, booking),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              'Error cargando agenda',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
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
            const Gap(16),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(professorBookingsProvider(professor.id)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = 'Hoy';
    } else if (date == tomorrow) {
      dateLabel = 'Mañana';
    } else {
      dateLabel = DateFormat('EEEE, d MMMM', 'es').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dateLabel,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, TenantBookingModel booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    String serviceTypeLabel;
    IconData serviceIcon;
    switch (booking.serviceType) {
      case 'individual_class':
        serviceTypeLabel = 'Clase Individual';
        serviceIcon = Icons.person;
        break;
      case 'group_class':
        serviceTypeLabel = 'Clase Grupal';
        serviceIcon = Icons.group;
        break;
      case 'court_rental':
        serviceTypeLabel = 'Alquiler de Cancha';
        serviceIcon = Icons.sports_tennis;
        break;
      default:
        serviceTypeLabel = 'Servicio';
        serviceIcon = Icons.event;
    }

    final timeRange = booking.startTime != null && booking.endTime != null
        ? '${DateFormat('HH:mm').format(booking.startTime!)} - ${DateFormat('HH:mm').format(booking.endTime!)}'
        : 'Hora no especificada';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: colorScheme.primary),
                const Gap(8),
                Text(
                  timeRange,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const Gap(4),
                      Text(
                        _getStatusLabel(booking.status),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const Gap(12),
            Row(
              children: [
                Icon(
                  serviceIcon,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  serviceTypeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    booking.student.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (booking.court != null) ...[
              const Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const Gap(8),
                  Text(
                    booking.court!.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.format(booking.price),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }
}
