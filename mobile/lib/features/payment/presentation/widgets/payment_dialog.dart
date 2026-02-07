import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/payment_providers.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/config/app_config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/strategies/payment_platform_strategy.dart';
import '../../application/commands/initiate_payment_command.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final double? initialAmount;
  final Map<String, dynamic>? bookingData;
  final String? redirectUrl;
  final VoidCallback? onPaymentStart;
  final VoidCallback? onPaymentComplete;
  final VoidCallback? onPaymentFailed;
  final VoidCallback? onPaymentPending;

  const PaymentDialog({
    super.key,
    this.initialAmount,
    this.bookingData,
    this.redirectUrl,
    this.onPaymentStart,
    this.onPaymentComplete,
    this.onPaymentFailed,
    this.onPaymentPending,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();
  String? _checkoutUrl;
  String? _paymentReference;
  bool _isWaitingForWebResult = false;

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
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusResult(bool? resolvedStatus) async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    ref.invalidate(studentInfoProvider);
    ref.invalidate(myBookingsProvider);

    if (resolvedStatus == true) {
      widget.onPaymentComplete?.call();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pago procesado. Actualizando saldo...'),
          backgroundColor: Colors.green,
          duration: Timeouts.snackbarSuccess,
        ),
      );
    } else if (resolvedStatus == false) {
      widget.onPaymentFailed?.call();
    } else {
      widget.onPaymentPending?.call();
    }

    _isWaitingForWebResult = false;
    Navigator.pop(context, resolvedStatus);
  }

  Future<void> _initiatePayment(double amount) async {
    final command = InitiatePaymentCommand(
      ref: ref,
      amount: amount,
      bookingData: widget.bookingData,
      redirectUrl: widget.redirectUrl,
    );

    final result = await command.execute();

    if (!mounted) return;

    if (result != null && result['checkoutUrl'] != null) {
      final checkoutUrl = result['checkoutUrl'] as String;
      final reference = result['reference']?.toString();
      if (reference != null && reference.isNotEmpty) {
        _paymentReference = reference;
      }

      final redirectUrl = widget.redirectUrl ?? AppConfig.paymentRedirectUrl;

      if (kIsWeb) {
        setState(() {
          _checkoutUrl = checkoutUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL de pago lista. Haz clic para continuar.'),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        final strategy = PaymentPlatformStrategyFactory.getStrategy(kIsWeb);
        await strategy.processPayment(
          checkoutUrl: checkoutUrl,
          redirectUrl: redirectUrl,
          paymentReference: _paymentReference,
          context: context,
          ref: ref,
          onPaymentStart: widget.onPaymentStart ?? () {},
          onPaymentComplete: _handleStatusResult,
        );
      }
    }
  }

  Future<void> _processWebPayment() async {
    if (_checkoutUrl == null) return;

    final redirectUrl = widget.redirectUrl ?? AppConfig.paymentRedirectUrl;

    setState(() {
      _isWaitingForWebResult = true;
    });

    final strategy = PaymentPlatformStrategyFactory.getStrategy(kIsWeb);
    await strategy.processPayment(
      checkoutUrl: _checkoutUrl!,
      redirectUrl: redirectUrl,
      paymentReference: _paymentReference,
      context: context,
      ref: ref,
      onPaymentStart: widget.onPaymentStart ?? () {},
      onPaymentComplete: _handleStatusResult,
    );
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
                onPressed: _isWaitingForWebResult ? null : _processWebPayment,
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
                        final cleanAmount = _amountController.text.replaceAll(
                          '.',
                          '',
                        );
                        final amount = double.parse(cleanAmount);
                        await _initiatePayment(amount);

                        if (context.mounted && paymentState.hasError) {
                          final error = paymentState.error;
                          final message = error is AppException
                              ? error.userMessage
                              : error?.toString() ?? "Desconocido";

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al iniciar pago: $message'),
                            ),
                          );
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
