class TenantPaymentModel {
  final String id;
  final String reference;
  final double amount;
  final String currency;
  final String status;
  final String gateway;
  final DateTime date;
  final String studentName;
  final String? paymentMethodType;
  final String? customerEmail;
  final String? channel;
  final String? type;
  final String? description;

  TenantPaymentModel({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gateway,
    required this.date,
    required this.studentName,
    this.paymentMethodType,
    this.customerEmail,
    this.channel,
    this.type,
    this.description,
  });

  factory TenantPaymentModel.fromJson(Map<String, dynamic> json) {
    return TenantPaymentModel(
      id: json['id'] as String? ?? json['_id'] as String,
      reference: json['reference'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'COP',
      status: json['status'] as String? ?? 'PENDING',
      gateway: json['gateway'] as String? ?? 'WOMPI',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.parse(json['createdAt'] as String),
      studentName: json['studentName'] as String? ?? 'Estudiante',
      paymentMethodType: json['paymentMethodType'] as String?,
      customerEmail: json['customerEmail'] as String?,
      channel: json['channel'] as String?,
      type: json['type'] as String?,
      description: json['description'] as String?,
    );
  }
}

class PaymentsPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaymentsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaymentsPagination.fromJson(Map<String, dynamic> json) {
    return PaymentsPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

class TenantPaymentsResponse {
  final List<TenantPaymentModel> payments;
  final PaymentsPagination pagination;

  TenantPaymentsResponse({required this.payments, required this.pagination});

  factory TenantPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return TenantPaymentsResponse(
      payments: (json['payments'] as List<dynamic>)
          .map(
            (item) => TenantPaymentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pagination: PaymentsPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}
