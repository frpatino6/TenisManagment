/// Model representing a student payment transaction
class StudentPaymentModel {
  final String id;
  final double amount;
  final DateTime date;
  final String status;
  final String method;
  final String description;
  final String professorName;
  final String tenantName;

  StudentPaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
    required this.method,
    required this.description,
    required this.professorName,
    required this.tenantName,
  });

  factory StudentPaymentModel.fromJson(Map<String, dynamic> json) {
    return StudentPaymentModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      method: json['method'] as String,
      description: json['description'] as String,
      professorName: json['professorName'] as String,
      tenantName: json['tenantName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'method': method,
      'description': description,
      'professorName': professorName,
      'tenantName': tenantName,
    };
  }
}
