import 'dart:convert';

bool? parseWompiPaymentStatus(String redirectUrl, String url) {
  if (!url.contains(redirectUrl)) {
    return null;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }

  final params = <String, String>{...uri.queryParameters};
  if (uri.fragment.contains('=')) {
    try {
      params.addAll(Uri.splitQueryString(uri.fragment));
    } catch (_) {}
  }

  final statusCandidates = <String?>[
    params['status'],
    params['transactionStatus'],
    params['transaction_status'],
    params['transaction.status'],
    params['state'],
    params['paymentStatus'],
    params['payment_status'],
  ].whereType<String>().toList();

  if (statusCandidates.isEmpty) {
    return null;
  }

  if (statusCandidates.any(_isDeclinedStatus)) {
    return false;
  }

  if (statusCandidates.any(_isApprovedStatus)) {
    return true;
  }

  return null;
}

bool isWompiPaymentApproved(String redirectUrl, String url) {
  return parseWompiPaymentStatus(redirectUrl, url) == true;
}

String? extractRedirectUrlFromMessage(String message) {
  final uri = Uri.tryParse(message);
  if (uri != null && uri.hasScheme) {
    return message;
  }

  try {
    final decoded = jsonDecode(message);
    if (decoded is Map &&
        decoded['type'] == 'wompi_payment' &&
        decoded['url'] is String) {
      return decoded['url'] as String;
    }
  } catch (_) {}

  return null;
}

bool _isApprovedStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('approved') ||
      normalized.contains('success') ||
      normalized == 'paid';
}

bool _isDeclinedStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('declined') ||
      normalized.contains('rejected') ||
      normalized.contains('failed') ||
      normalized.contains('error') ||
      normalized.contains('void') ||
      normalized.contains('expired') ||
      normalized.contains('canceled') ||
      normalized.contains('cancelled');
}
