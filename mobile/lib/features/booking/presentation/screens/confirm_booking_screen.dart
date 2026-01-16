import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/constants/timeouts.dart';
import '../../domain/models/schedule_model.dart';
import '../providers/booking_provider.dart';
import '../../../payment/presentation/widgets/payment_dialog.dart';
import '../../../student/presentation/providers/student_provider.dart';

/// Screen to confirm a booking before creating it
///
/// Shows booking details and allows the student to confirm or cancel.
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

class _ConfirmBookingScreenState extends ConsumerState<ConfirmBookingScreen>
    with WidgetsBindingObserver {
  bool _isBooking = false;
  double _price = 0.0; // Will be calculated based on service type

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Default price for individual class (can be improved with pricing from professor)
    _price = 50000.0; // Default price in COP
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes (user returns from Wompi), refresh balance and bookings
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(studentInfoProvider);
      ref.invalidate(bookingServiceProvider);
    }
  }

  Future<void> _confirmBooking() async {
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
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
      body: SingleChildScrollView(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(_price),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
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
                    onPressed: _isBooking ? null : () => context.pop(),
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
                      final studentInfoAsync = ref.watch(studentInfoProvider);

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
                                      },
                                      redirectUrl:
                                          'https://tenis-uat.casacam.net/payment-complete',
                                    ),
                                  ).then((_) {
                                    // Refresh balance and bookings after dialog closes
                                    ref.invalidate(studentInfoProvider);
                                    ref.invalidate(bookingServiceProvider);
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
                            onPressed: _isBooking ? null : _confirmBooking,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isBooking
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Confirmar Reserva'),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
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
