import 'package:flutter/material.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../commands/booking_command.dart';

/// Command to validate booking data before processing.
/// Ensures all required fields (courtId, date, time) are present.
class ValidateBookingCommand implements BookingCommand {
  final String? courtId;
  final DateTime? date;
  final TimeOfDay? time;

  ValidateBookingCommand({
    required this.courtId,
    required this.date,
    required this.time,
  });

  @override
  Future<void> execute() async {
    if (courtId == null || courtId!.isEmpty) {
      throw ValidationException(
        'Debes seleccionar una cancha',
        code: 'MISSING_COURT',
      );
    }

    if (date == null) {
      throw ValidationException(
        'Debes seleccionar una fecha',
        code: 'MISSING_DATE',
      );
    }

    if (time == null) {
      throw ValidationException(
        'Debes seleccionar una hora',
        code: 'MISSING_TIME',
      );
    }
  }

  @override
  Future<void> undo() async {
    // No undo operation for validation
  }

  @override
  String getDescription() => 'Validar datos de reserva';
}
