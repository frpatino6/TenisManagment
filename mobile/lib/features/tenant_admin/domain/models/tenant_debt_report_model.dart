class TenantDebtReportModel {
  final DebtSummary summary;
  final List<DebtorItem> debtors;

  TenantDebtReportModel({required this.summary, required this.debtors});

  factory TenantDebtReportModel.fromJson(Map<String, dynamic> json) {
    return TenantDebtReportModel(
      summary: DebtSummary.fromJson(json['summary'] as Map<String, dynamic>),
      debtors: (json['debtors'] as List<dynamic>)
          .map((item) => DebtorItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DebtSummary {
  final double totalDebt;
  final double debtByBalance;
  final double debtByPendingPayments;
  final int debtorCount;

  DebtSummary({
    required this.totalDebt,
    required this.debtByBalance,
    required this.debtByPendingPayments,
    required this.debtorCount,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      totalDebt: (json['totalDebt'] as num).toDouble(),
      debtByBalance: (json['debtByBalance'] as num).toDouble(),
      debtByPendingPayments: (json['debtByPendingPayments'] as num).toDouble(),
      debtorCount: json['debtorCount'] as int,
    );
  }
}

class DebtorItem {
  final String studentId;
  final String name;
  final String email;
  final String phone;
  final double balance;
  final double pendingPaymentsAmount;
  final double totalDebt;

  DebtorItem({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.balance,
    required this.pendingPaymentsAmount,
    required this.totalDebt,
  });

  factory DebtorItem.fromJson(Map<String, dynamic> json) {
    return DebtorItem(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      balance: (json['balance'] as num).toDouble(),
      pendingPaymentsAmount: (json['pendingPaymentsAmount'] as num).toDouble(),
      totalDebt: (json['totalDebt'] as num).toDouble(),
    );
  }
}
