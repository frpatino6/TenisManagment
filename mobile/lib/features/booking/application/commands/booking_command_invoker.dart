import 'booking_command.dart';

/// Invoker class that manages the execution of booking commands.
/// Maintains a history of executed commands for potential undo/redo functionality.
class BookingCommandInvoker {
  final List<BookingCommand> _commandHistory = [];
  int _currentIndex = -1;

  /// Executes a command and adds it to the history.
  /// If there are commands after the current index (from a previous undo),
  /// they are removed before adding the new command.
  Future<void> executeCommand(BookingCommand command) async {
    // Remove commands after current index if we're in the middle of history
    if (_currentIndex < _commandHistory.length - 1) {
      _commandHistory.removeRange(_currentIndex + 1, _commandHistory.length);
    }

    await command.execute();
    _commandHistory.add(command);
    _currentIndex = _commandHistory.length - 1;
  }

  /// Undoes the last executed command.
  /// Returns true if undo was successful, false if there's nothing to undo.
  Future<bool> undo() async {
    if (_currentIndex >= 0) {
      await _commandHistory[_currentIndex].undo();
      _currentIndex--;
      return true;
    }
    return false;
  }

  /// Redoes the last undone command.
  /// Returns true if redo was successful, false if there's nothing to redo.
  Future<bool> redo() async {
    if (_currentIndex < _commandHistory.length - 1) {
      _currentIndex++;
      await _commandHistory[_currentIndex].execute();
      return true;
    }
    return false;
  }

  /// Checks if there's a command that can be undone.
  bool canUndo() => _currentIndex >= 0;

  /// Checks if there's a command that can be redone.
  bool canRedo() => _currentIndex < _commandHistory.length - 1;

  /// Clears the command history.
  void clearHistory() {
    _commandHistory.clear();
    _currentIndex = -1;
  }

  /// Returns the number of commands in history.
  int get historyLength => _commandHistory.length;
}
