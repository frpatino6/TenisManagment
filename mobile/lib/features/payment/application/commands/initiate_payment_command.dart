import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/payment_providers.dart';

abstract class PaymentCommand {
  Future<Map<String, dynamic>?> execute();
}

class InitiatePaymentCommand implements PaymentCommand {
  final WidgetRef ref;
  final double amount;
  final Map<String, dynamic>? bookingData;
  final String? redirectUrl;

  InitiatePaymentCommand({
    required this.ref,
    required this.amount,
    this.bookingData,
    this.redirectUrl,
  });

  @override
  Future<Map<String, dynamic>?> execute() async {
    final result = await ref
        .read(paymentControllerProvider.notifier)
        .initPayment(
          amount,
          bookingData: bookingData,
          redirectUrl: redirectUrl,
        );
    return result;
  }
}
