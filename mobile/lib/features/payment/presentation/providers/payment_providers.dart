import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/payment_service.dart';
import '../../../../core/providers/tenant_provider.dart';
import 'dart:async';

part 'payment_providers.g.dart';

@Riverpod(keepAlive: true)
PaymentService paymentService(Ref ref) {
  return PaymentService();
}

@riverpod
class PaymentController extends _$PaymentController {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>?> initPayment(
    double amount, {
    Map<String, dynamic>? bookingData,
    String? redirectUrl,
  }) async {
    state = const AsyncLoading();
    try {
      final tenantId = ref.read(currentTenantIdProvider);
      if (tenantId == null) {
        throw Exception('No se ha seleccionado un centro');
      }
      final service = ref.read(paymentServiceProvider);
      final result = await service.initPayment(
        amount,
        tenantId,
        bookingData: bookingData,
        redirectUrl: redirectUrl,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
