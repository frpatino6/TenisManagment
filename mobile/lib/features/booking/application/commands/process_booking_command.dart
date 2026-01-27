import '../../domain/services/court_service.dart';
import '../commands/booking_command.dart';

/// Command to process the actual booking through the court service.
class ProcessBookingCommand implements BookingCommand {
  final CourtService courtService;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;

  String? _bookingId;

  ProcessBookingCommand({
    required this.courtService,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  @override
  Future<void> execute() async {
    final result = await courtService.bookCourt(
      courtId: courtId,
      startTime: startTime,
      endTime: endTime,
      price: price,
    );

    _bookingId = result['id'] as String?;
  }

  @override
  Future<void> undo() async {
    // Note: CourtService doesn't have a cancelBooking method yet
    // This is a placeholder for future undo functionality
    // In a real scenario, you would call: await courtService.cancelBooking(_bookingId!);
    _bookingId = null;
  }

  @override
  String getDescription() => 'Realizar reserva';

  /// Returns the booking ID after execution.
  /// Returns null if booking hasn't been processed yet.
  String? get bookingId => _bookingId;
}
