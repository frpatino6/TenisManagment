import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/payment/presentation/utils/wompi_redirect_utils.dart';

void main() {
  group('isWompiPaymentApproved', () {
    test('returns true for approved status', () {
      final result = isWompiPaymentApproved(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete?status=APPROVED',
      );

      expect(result, isTrue);
    });

    test('returns false for declined status', () {
      final result = isWompiPaymentApproved(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete?status=DECLINED',
      );

      expect(result, isFalse);
    });

    test('reads status from fragment', () {
      final result = isWompiPaymentApproved(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete#status=DECLINED',
      );

      expect(result, isFalse);
    });
  });
}
