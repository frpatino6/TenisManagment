import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../domain/models/tenant_booking_model.dart';

class TenantBookingCard extends StatelessWidget {
  final TenantBookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onConfirmPayment;

  const TenantBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
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
                  Expanded(
                    child: Text(
                      _formattedDate(booking),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Gap(16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const Gap(4),
                  Text(
                    booking.startTime != null && booking.endTime != null
                        ? '${DateFormat('HH:mm').format(booking.startTime!)} - ${DateFormat('HH:mm').format(booking.endTime!)}'
                        : 'Sin horario',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
                  booking.status != 'cancelled' &&
                  onConfirmPayment != null) ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onConfirmPayment,
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

  static Color _statusColor(String status) {
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

  static String _formattedDate(TenantBookingModel b) {
    final dateToFormat = b.date ?? b.startTime;
    if (dateToFormat == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(dateToFormat);
  }
}
