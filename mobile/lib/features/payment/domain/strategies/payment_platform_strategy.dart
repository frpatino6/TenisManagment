import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/web_utils_stub.dart'
    if (dart.library.js_interop) '../../../../core/utils/web_utils_web.dart';
import '../../presentation/screens/wompi_webview_screen.dart';
import '../../presentation/utils/wompi_redirect_utils.dart';
import '../../presentation/providers/payment_providers.dart';
import '../../../../core/providers/tenant_provider.dart';

abstract class PaymentPlatformStrategy {
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPaymentStart,
    required Function(bool?) onPaymentComplete,
  });
}

class WebPaymentStrategy implements PaymentPlatformStrategy {
  @override
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPaymentStart,
    required Function(bool?) onPaymentComplete,
  }) async {
    final String webPaymentStorageKey = 'wompi_payment_redirect';
    void Function()? removeMessageListener;
    void Function()? removeStorageListener;
    void Function()? removeFocusListener;
    bool isWaitingForWebResult = true;

    Future<bool?> resolveStatusFromBackend({
      String? transactionId,
      String? reference,
    }) async {
      final tenantId = ref.read(currentTenantIdProvider);
      if (tenantId == null) return null;

      try {
        final service = ref.read(paymentServiceProvider);
        final result = await service.getTransactionStatus(
          transactionId: transactionId,
          reference: reference,
          tenantId: tenantId,
        );
        final backendStatus = result['status'] as String?;
        if (backendStatus == 'APPROVED') {
          return true;
        }
        if (backendStatus == 'DECLINED' ||
            backendStatus == 'VOIDED' ||
            backendStatus == 'ERROR') {
          return false;
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    Future<void> handleWebMessage(String message) async {
      final messageUrl = extractRedirectUrlFromMessage(message);
      if (messageUrl == null || !messageUrl.contains(redirectUrl)) {
        return;
      }

      final status = parseWompiPaymentStatus(redirectUrl, messageUrl);
      final uri = Uri.tryParse(messageUrl);
      final transactionId =
          uri?.queryParameters['id'] ?? uri?.queryParameters['transaction_id'];

      bool? resolvedStatus = status;
      resolvedStatus ??= await resolveStatusFromBackend(
        transactionId: transactionId,
        reference: paymentReference,
      );

      if (!context.mounted) return;

      removeMessageListener?.call();
      removeMessageListener = null;
      removeStorageListener?.call();
      removeStorageListener = null;
      removeFocusListener?.call();
      removeFocusListener = null;
      WebUtils.removeLocalStorageItem(webPaymentStorageKey);
      isWaitingForWebResult = false;

      onPaymentComplete(resolvedStatus);
      return;
    }

    Future<void> handleFocusReturn() async {
      if (!isWaitingForWebResult) return;
      final resolvedStatus = await resolveStatusFromBackend(
        reference: paymentReference,
      );
      if (!context.mounted || !isWaitingForWebResult) return;

      removeMessageListener?.call();
      removeMessageListener = null;
      removeStorageListener?.call();
      removeStorageListener = null;
      removeFocusListener?.call();
      removeFocusListener = null;
      WebUtils.removeLocalStorageItem(webPaymentStorageKey);
      isWaitingForWebResult = false;

      onPaymentComplete(resolvedStatus);
    }

    removeMessageListener = WebUtils.addWindowMessageListener(handleWebMessage);
    removeStorageListener = WebUtils.addWindowStorageListener((key, value) {
      if (key == webPaymentStorageKey && value != null) {
        handleWebMessage(value);
      }
    });
    removeFocusListener = WebUtils.addWindowFocusListenerWithDispose(
      handleFocusReturn,
    );

    onPaymentStart();
    WebUtils.openUrl(checkoutUrl, newTab: true);

    return null;
  }
}

class MobilePaymentStrategy implements PaymentPlatformStrategy {
  @override
  Future<bool?> processPayment({
    required String checkoutUrl,
    required String redirectUrl,
    required String? paymentReference,
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPaymentStart,
    required Function(bool?) onPaymentComplete,
  }) async {
    onPaymentStart();

    final dynamic paymentResult = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => WompiWebViewScreen(
          checkoutUrl: checkoutUrl,
          redirectUrl: redirectUrl,
        ),
      ),
    );

    if (!context.mounted) return null;

    bool? status;
    String? transactionId;
    if (paymentResult is Map) {
      status = paymentResult['status'] as bool?;
      transactionId = paymentResult['transactionId'] as String?;
    } else if (paymentResult is bool) {
      status = paymentResult;
    }

    bool? resolvedStatus = status;
    if (resolvedStatus == null && transactionId != null) {
      final tenantId = ref.read(currentTenantIdProvider);
      if (tenantId != null) {
        try {
          final service = ref.read(paymentServiceProvider);
          final result = await service.getTransactionStatus(
            transactionId: transactionId,
            tenantId: tenantId,
          );
          final backendStatus = result['status'] as String?;
          if (backendStatus == 'APPROVED') {
            resolvedStatus = true;
          } else if (backendStatus == 'DECLINED' ||
              backendStatus == 'VOIDED' ||
              backendStatus == 'ERROR') {
            resolvedStatus = false;
          }
        } catch (_) {
          resolvedStatus = null;
        }
      }
    }

    onPaymentComplete(resolvedStatus);
    return resolvedStatus;
  }
}

class PaymentPlatformStrategyFactory {
  static PaymentPlatformStrategy getStrategy(bool isWeb) {
    if (isWeb) {
      return WebPaymentStrategy();
    } else {
      return MobilePaymentStrategy();
    }
  }
}
