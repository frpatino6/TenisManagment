import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/payment_providers.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../screens/wompi_webview_screen.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/config/app_config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/web_utils_stub.dart'
    if (dart.library.js_interop) '../../../../core/utils/web_utils_web.dart';
import '../utils/wompi_redirect_utils.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final double? initialAmount;
  final Map<String, dynamic>? bookingData;
  final String? redirectUrl;
  final VoidCallback? onPaymentStart;
  final VoidCallback? onPaymentComplete;
  final VoidCallback? onPaymentFailed;

  const PaymentDialog({
    super.key,
    this.initialAmount,
    this.bookingData,
    this.redirectUrl,
    this.onPaymentStart,
    this.onPaymentComplete,
    this.onPaymentFailed,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();
  String? _checkoutUrl; // Store URL for two-step launch on web
  bool _isWaitingForWebResult = false;
  void Function()? _removeMessageListener;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialAmount?.toStringAsFixed(0) ?? '';
    _amountController = TextEditingController(
      text: initialValue.isNotEmpty ? _formatNumber(initialValue) : '',
    );
  }

  String _formatNumber(String s) {
    if (s.isEmpty) return '';
    return NumberFormat.decimalPattern('es_CO').format(int.parse(s));
  }

  @override
  void dispose() {
    _removeMessageListener?.call();
    _amountController.dispose();
    super.dispose();
  }

  void _handleWebMessage(String message) {
    final redirectUrl = widget.redirectUrl ?? AppConfig.paymentRedirectUrl;
    final messageUrl = extractRedirectUrlFromMessage(message);
    if (messageUrl == null || !messageUrl.contains(redirectUrl)) {
      return;
    }

    final isApproved = isWompiPaymentApproved(redirectUrl, messageUrl);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    ref.invalidate(studentInfoProvider);
    ref.invalidate(myBookingsProvider);

    if (isApproved) {
      widget.onPaymentComplete?.call();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pago procesado. Actualizando saldo...'),
          backgroundColor: Colors.green,
          duration: Timeouts.snackbarSuccess,
        ),
      );
    } else {
      widget.onPaymentFailed?.call();
    }

    _removeMessageListener?.call();
    _removeMessageListener = null;

    Navigator.pop(context, isApproved);
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto a recargar',
                prefixText: '\$ ',
                helperText: 'Mínimo \$10.000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                // Remove formatting to validate
                final cleanValue = value.replaceAll('.', '');
                final amount = double.tryParse(cleanValue);
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

            if (kIsWeb && _checkoutUrl != null) {
              return FilledButton.icon(
                onPressed: _isWaitingForWebResult
                    ? null
                    : () {
                        _removeMessageListener?.call();
                        _removeMessageListener =
                            WebUtils.addWindowMessageListener(_handleWebMessage);
                        setState(() {
                          _isWaitingForWebResult = true;
                        });
                        widget.onPaymentStart?.call();
                        WebUtils.openUrl(_checkoutUrl!, newTab: true);
                      },
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  _isWaitingForWebResult
                      ? 'Esperando confirmación...'
                      : 'Ir a la pasarela de pago',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              );
            }

            return FilledButton(
              onPressed: paymentState.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        // Remove formatting before sending to backend
                        final cleanAmount = _amountController.text.replaceAll(
                          '.',
                          '',
                        );
                        final amount = double.parse(cleanAmount);
                        // Using read instead of watch for actions
                        final result = await ref
                            .read(paymentControllerProvider.notifier)
                            .initPayment(
                              amount,
                              bookingData: widget.bookingData,
                              redirectUrl: widget.redirectUrl,
                            );

                        if (context.mounted) {
                          if (result != null && result['checkoutUrl'] != null) {
                            final checkoutUrl = result['checkoutUrl'];

                            if (kIsWeb) {
                              // On web: update state to show the "Proceed" button
                              // This ensures the next click is a direct user interaction
                              setState(() {
                                _checkoutUrl = checkoutUrl;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'URL de pago lista. Haz clic para continuar.',
                                  ),
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            } else {
                              // On mobile: keep automatic redirection with WebView
                              // Don't pop yet, wait for webview result

                              widget.onPaymentStart?.call();
                              final bool? paymentCompleted =
                                  await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WompiWebViewScreen(
                                        checkoutUrl: checkoutUrl,
                                        redirectUrl:
                                            widget.redirectUrl ??
                                            AppConfig.paymentRedirectUrl,
                                      ),
                                    ),
                                  );

                              if (context.mounted) {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final isApproved = paymentCompleted == true;

                                Navigator.pop(context, isApproved);

                                ref.invalidate(studentInfoProvider);
                                ref.invalidate(myBookingsProvider);

                                if (isApproved) {
                                  widget.onPaymentComplete?.call();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pago procesado. Actualizando saldo...',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Timeouts.snackbarSuccess,
                                    ),
                                  );
                                } else {
                                  widget.onPaymentFailed?.call();
                                }
                              }
                            }
                          } else {
                            // Error handling remains same
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int value = int.parse(newValue.text.replaceAll('.', ''));
    final formatter = NumberFormat.decimalPattern('es_CO');
    final String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
