import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../commands/booking_command.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../presentation/providers/booking_provider.dart';

/// Command to refresh data by invalidating relevant providers.
class RefreshDataCommand implements BookingCommand {
  final WidgetRef ref;

  RefreshDataCommand(this.ref);

  @override
  Future<void> execute() async {
    ref.invalidate(courtsProvider);
    ref.invalidate(studentBookingsProvider);
  }

  @override
  Future<void> undo() async {
    // Cannot undo a refresh operation
  }

  @override
  String getDescription() => 'Actualizar datos';
}
