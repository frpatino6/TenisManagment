import '../../domain/models/court_model.dart';
import '../commands/booking_command.dart';

/// Command to calculate the total price for a booking based on duration and court price.
class CalculatePriceCommand implements BookingCommand {
  final CourtModel court;
  final DateTime startTime;
  final DateTime endTime;

  double? _calculatedPrice;

  CalculatePriceCommand({
    required this.court,
    required this.startTime,
    required this.endTime,
  });

  @override
  Future<void> execute() async {
    final durationInHours = endTime.difference(startTime).inHours;
    _calculatedPrice = court.pricePerHour * durationInHours;
  }

  @override
  Future<void> undo() async {
    _calculatedPrice = null;
  }

  @override
  String getDescription() => 'Calcular precio de reserva';

  /// Returns the calculated price. Must be called after [execute].
  /// Returns 0.0 if price hasn't been calculated yet.
  double get calculatedPrice => _calculatedPrice ?? 0.0;
}
