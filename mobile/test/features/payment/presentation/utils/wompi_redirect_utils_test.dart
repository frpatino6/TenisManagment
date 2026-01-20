import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/payment/presentation/utils/wompi_redirect_utils.dart';

void main() {
  group('parseWompiPaymentStatus', () {
    test('returns true for approved status', () {
      final result = parseWompiPaymentStatus(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete?status=APPROVED',
      );

      expect(result, isTrue);
    });

    test('returns false for declined status', () {
      final result = parseWompiPaymentStatus(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete?status=DECLINED',
      );

      expect(result, isFalse);
    });

    test('reads status from fragment', () {
      final result = parseWompiPaymentStatus(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete#status=DECLINED',
      );

      expect(result, isFalse);
    });

    test('returns null when status is missing', () {
      final result = parseWompiPaymentStatus(
        'https://example.com/payment-complete',
        'https://example.com/payment-complete',
      );

      expect(result, isNull);
    });
  });

  group('extractRedirectUrlFromMessage', () {
    test('returns url when message is a full redirect URL', () {
      final url = extractRedirectUrlFromMessage(
        'https://example.com/payment-complete?status=APPROVED',
      );

      expect(
        url,
        equals('https://example.com/payment-complete?status=APPROVED'),
      );
    });

    test('returns null for non-url message', () {
      final url = extractRedirectUrlFromMessage('not-a-url');

      expect(url, isNull);
    });
  });
}
