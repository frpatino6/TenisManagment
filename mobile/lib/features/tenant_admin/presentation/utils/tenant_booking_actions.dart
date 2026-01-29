import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../../../core/events/data_change_event.dart';
import '../../../../core/observers/data_change_observer.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';

Future<void> confirmBookingQuickPayment(
  BuildContext context,
  WidgetRef ref,
  TenantBookingModel booking,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Pago'),
      content: Text(
        '¿Confirmar pago de ${CurrencyUtils.format(booking.price)} para ${booking.student.name}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
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
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago confirmado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );

    final observer = ref.read(dataChangeObserverProvider);
    observer.notifyChange(
      DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'booking',
        entityId: booking.id,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
