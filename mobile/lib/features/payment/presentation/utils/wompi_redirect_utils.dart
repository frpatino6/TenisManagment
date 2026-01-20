bool isWompiPaymentApproved(String redirectUrl, String url) {
  if (!url.contains(redirectUrl)) {
    return false;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    return true;
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
    return true;
  }

  if (statusCandidates.any(_isDeclinedStatus)) {
    return false;
  }

  if (statusCandidates.any(_isApprovedStatus)) {
    return true;
  }

  return true;
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
