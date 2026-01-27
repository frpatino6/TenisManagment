/// Abstract base class for booking commands following the Command Pattern.
/// Each command encapsulates a specific operation in the booking process.
abstract class BookingCommand {
  /// Executes the command operation.
  /// Throws [AppException] if the operation fails.
  Future<void> execute();

  /// Undoes the command operation (if applicable).
  /// Default implementation does nothing.
  Future<void> undo() async {
    // Default: no undo operation
  }

  /// Returns a human-readable description of what this command does.
  String getDescription();
}
