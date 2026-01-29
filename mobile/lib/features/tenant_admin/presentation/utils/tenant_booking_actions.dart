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

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (loadingContext) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirmando reserva...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Procesando pago y actualizando estado',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    await ref
        .read(tenantAdminServiceProvider)
        .confirmBooking(booking.id, paymentStatus: 'paid');

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final observer = ref.read(dataChangeObserverProvider);
    observer.notifyChange(
      DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'booking',
        entityId: booking.id,
      ),
    );
    observer.notifyChange(
      DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'payment',
        entityId: booking.id,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago confirmado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
