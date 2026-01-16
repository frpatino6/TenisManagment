class BookingModel {
  final String id;
  final String? scheduleId;
  final String studentId;
  final String? professorId;
  final String? professorName;
  final String? courtId;
  final String? courtName;
  final String serviceType;
  final double price;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    this.scheduleId,
    required this.studentId,
    this.professorId,
    this.professorName,
    this.courtId,
    this.courtName,
    required this.serviceType,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String?,
      studentId: json['studentId'] as String? ?? '',
      professorId: json['professorId'] as String?,
      professorName: json['professorName'] as String?,
      courtId: json['courtId'] as String?,
      courtName: json['courtName'] as String?,
      serviceType: json['serviceType'] as String? ?? 'individual_class',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(
        json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
