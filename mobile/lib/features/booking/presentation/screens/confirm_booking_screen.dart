import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/constants/timeouts.dart';
import '../../domain/models/schedule_model.dart';
import '../providers/booking_provider.dart';
import '../../../payment/presentation/widgets/payment_dialog.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../../core/logging/logger.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen to confirm a booking before creating it
///
/// Shows booking details and allows the student to confirm or cancel.
///
/// ### 2. Automatización "Cero Clics" Total
/// - **Doble Verificación:** La app ahora escucha tanto la creación automática de reservas (vía webhooks) como las actualizaciones de saldo.
/// - **Gatillo Automático:** Si el saldo llega a ser suficiente y la reserva aún no aparece confirmada, la app dispara el proceso de confirmación de inmediato.
/// - **Experiencia Fluida:** El usuario ya no ve el botón "Confirmar Reserva" después de pagar; es redirigido directamente al éxito.
class ConfirmBookingScreen extends ConsumerStatefulWidget {
  final ScheduleModel schedule;
  final String professorId;
  final String professorName;
  final String tenantId;
  final String tenantName;

  const ConfirmBookingScreen({
    super.key,
    required this.schedule,
    required this.professorId,
    required this.professorName,
    required this.tenantId,
    required this.tenantName,
  });

  @override
  ConsumerState<ConfirmBookingScreen> createState() =>
      _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends ConsumerState<ConfirmBookingScreen> {
  final _logger = AppLogger.tag('ConfirmBookingScreen');
  bool _isBooking = false;
  bool _isSyncing = false;
  bool _shouldAutoConfirm = false;
  double _price = 0.0; // Will be calculated based on service type
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Default price for individual class (can be improved with pricing from professor)
    _price = 50000.0; // Default price in COP
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPaymentPolling() {
    _logger.info('Starting robust payment polling using ref.refresh...');
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || !_shouldAutoConfirm || _isBooking) {
        timer.cancel();
        return;
      }

      _logger.info('Polling for payment completion (attempt ${timer.tick})...');

      try {
        // Robust refresh: Wait for the futures to complete with new data from server
        // ref.refresh(provider.future) invalidates the provider AND returns the new future
        final studentInfo = await ref.refresh(studentInfoProvider.future);
        final bookings = await ref.refresh(myBookingsProvider.future);

        if (!mounted) {
          timer.cancel();
          return;
        }

        // Check if webhook already created the booking
        final hasBooking = bookings.any(
          (b) => b.scheduleId == widget.schedule.id && b.status == 'confirmed',
        );

        if (hasBooking) {
          _logger.info('Booking detected by webhook, redirecting...');
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Reserva confirmada automáticamente!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          }
          return;
        }

        // Check if balance is sufficient
        final balance = (studentInfo['balance'] as num?)?.toDouble() ?? 0.0;

        if (balance >= _price) {
          _logger.info(
            'Balance sufficient ($balance >= $_price), confirming booking...',
          );
          timer.cancel();
          _confirmBooking();
        }
      } catch (e) {
        _logger.error('Error during polling refresh', error: e);
        // Continue polling on error, as transient network errors shouldn't stop the polling
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
      _isSyncing = true;
    });

    try {
      final service = ref.read(bookingServiceProvider);

      await service.bookLesson(
        widget.schedule.id,
        serviceType: 'individual_class', // Default service type
        price: _price,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Clase reservada exitosamente!'),
          backgroundColor: Colors.green,
          duration: Timeouts.snackbarSuccess,
        ),
      );

      // Navigate back to home
      context.go('/home');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isBooking = false;
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reservar: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Reserva')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Reserva',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.person,
                          'Profesor',
                          widget.professorName,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.business,
                          'Centro',
                          widget.tenantName,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Fecha',
                          widget.schedule.formattedDate,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.access_time,
                          'Horario',
                          widget.schedule.timeRange,
                        ),
                        if (widget.schedule.courtName != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.stadium,
                            'Cancha',
                            widget.schedule.courtName!,
                          ),
                        ],
                        if (widget.schedule.notes != null &&
                            widget.schedule.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildDetailRow(
                              Icons.note,
                              'Notas',
                              widget.schedule.notes!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Price card
                Card(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precio',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyUtils.format(_price),
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSyncing ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final studentInfoAsync = ref.watch(
                            studentInfoProvider,
                          );

                          return studentInfoAsync.when(
                            data: (info) {
                              final balance =
                                  (info['balance'] as num?)?.toDouble() ?? 0.0;
                              final isInsufficient = balance < _price;
                              final missingAmount = _price - balance;

                              if (isInsufficient) {
                                return ElevatedButton.icon(
                                  onPressed: () =>
                                      showDialog(
                                        context: context,
                                        builder: (_) => PaymentDialog(
                                          initialAmount: missingAmount,
                                          bookingData: {
                                            'scheduleId': widget.schedule.id,
                                            'serviceType': 'individual_class',
                                            'price': _price,
                                            'professorId': widget.professorId,
                                            'tenantId': widget.tenantId,
                                          },
                                          redirectUrl:
                                              'https://tenis-uat.casacam.net/payment-complete',
                                          onPaymentComplete: () {
                                            // Refresh data after payment
                                            Future.delayed(
                                              const Duration(seconds: 2),
                                              () {
                                                if (context.mounted) {
                                                  ref.invalidate(
                                                    studentInfoProvider,
                                                  );
                                                  ref.invalidate(
                                                    myBookingsProvider,
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          setState(() {
                                            _shouldAutoConfirm = true;
                                            _isSyncing = true;
                                          });
                                          // Start polling to check payment completion
                                          _startPaymentPolling();
                                        }
                                      }),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                  icon: const Icon(Icons.add_card),
                                  label: const Text('Recargar y Reservar'),
                                );
                              }

                              return ElevatedButton(
                                onPressed: _isSyncing ? null : _confirmBooking,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: _isBooking
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text('Confirmar Reserva'),
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) =>
                                Center(child: Text('Error: $error')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Procesando reserva...',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estamos sincronizando con el servidor',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
