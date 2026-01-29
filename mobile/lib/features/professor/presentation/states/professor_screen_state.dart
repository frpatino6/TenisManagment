/// UI state for professor feature screens. Encapsulates loading, success,
/// and error for consistent state handling across professor screens.
sealed class ProfessorScreenState {
  const ProfessorScreenState();
}

final class ProfessorInitial extends ProfessorScreenState {
  const ProfessorInitial();
}

final class ProfessorLoading extends ProfessorScreenState {
  final String? message;
  const ProfessorLoading([this.message]);
}

final class ProfessorSuccess extends ProfessorScreenState {
  final String? message;
  const ProfessorSuccess([this.message]);
}

final class ProfessorError extends ProfessorScreenState {
  final String message;
  const ProfessorError(this.message);
}
