/// UI state for student feature screens. Encapsulates loading, success,
/// and error for consistent state handling across student screens.
sealed class StudentScreenState {
  const StudentScreenState();
}

final class StudentInitial extends StudentScreenState {
  const StudentInitial();
}

final class StudentLoading extends StudentScreenState {
  final String? message;
  const StudentLoading([this.message]);
}

final class StudentSuccess extends StudentScreenState {
  final String? message;
  const StudentSuccess([this.message]);
}

final class StudentError extends StudentScreenState {
  final String message;
  const StudentError(this.message);
}
