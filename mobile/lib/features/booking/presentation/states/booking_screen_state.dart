/// UI state for [BookCourtScreen]. Encapsulates loading, success, and error
/// to replace scattered boolean flags (_isBooking, _isSyncing) with explicit
/// state transitions.
sealed class BookingScreenState {
  const BookingScreenState();
}

final class BookingInitial extends BookingScreenState {
  const BookingInitial();
}

final class BookingLoading extends BookingScreenState {
  final String? message;
  const BookingLoading([this.message]);
}

final class BookingSyncing extends BookingScreenState {
  final String? message;
  const BookingSyncing([this.message]);
}

final class BookingSuccess extends BookingScreenState {
  final String message;
  final String? courtName;
  final DateTime? date;
  const BookingSuccess(this.message, {this.courtName, this.date});
}

final class BookingError extends BookingScreenState {
  final String message;
  const BookingError(this.message);
}
