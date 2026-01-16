import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/payment_providers.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../screens/wompi_webview_screen.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/utils/web_utils_stub.dart'
    if (dart.library.js_interop) '../../../../core/utils/web_utils_web.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final double? initialAmount;
  final Map<String, dynamic>? bookingData;
  final String? redirectUrl;
  final VoidCallback? onPaymentComplete;

  const PaymentDialog({
    super.key,
    this.initialAmount,
    this.bookingData,
    this.redirectUrl,
    this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recargar Saldo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a recargar',
                prefixText: '\$ ',
                helperText: 'Mínimo \$10.000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 10000) {
                  return 'El monto mínimo es \$10.000';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Consumer(
          builder: (context, ref, child) {
            final paymentState = ref.watch(paymentControllerProvider);

            return FilledButton(
              onPressed: paymentState.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        final amount = double.parse(_amountController.text);
                        // Using read instead of watch for actions
                        final result = await ref
                            .read(paymentControllerProvider.notifier)
                            .initPayment(
                              amount,
                              bookingData: widget.bookingData,
                              redirectUrl: widget.redirectUrl,
                            );

                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog

                          if (result != null && result['checkoutUrl'] != null) {
                            bool? paymentCompleted;

                            if (kIsWeb) {
                              // On web: use WebUtils to navigate in the same tab
                              // This prevents mobile Safari from blocking it as a popup
                              final url = result['checkoutUrl'];
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Redirigiendo a Wompi...'),
                                  ),
                                );
                              }
                              WebUtils.openUrl(url);
                              paymentCompleted = null;
                            } else {
                              // On mobile (Android/iOS): use WebView
                              paymentCompleted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WompiWebViewScreen(
                                    checkoutUrl: result['checkoutUrl'],
                                    redirectUrl:
                                        widget.redirectUrl ??
                                        'https://tenis-uat.casacam.net/payment-complete',
                                  ),
                                ),
                              );
                            }

                            // Refresh data after payment flow with a small delay to allow webhook processing
                            if (context.mounted) {
                              Future.delayed(Timeouts.snackbarSuccess, () {
                                if (context.mounted) {
                                  ref.invalidate(studentInfoProvider);
                                  ref.invalidate(bookingServiceProvider);
                                  // Notify parent screen to refresh
                                  widget.onPaymentComplete?.call();
                                }
                              });

                              if (paymentCompleted == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pago procesado. Actualizando saldo...',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Timeouts.snackbarSuccess,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              final error = paymentState.error;
                              final message = error is AppException
                                  ? error.userMessage
                                  : error?.toString() ?? "Desconocido";

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al iniciar pago: $message',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
              child: paymentState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pagar con Wompi'),
            );
          },
        ),
      ],
    );
  }
}
