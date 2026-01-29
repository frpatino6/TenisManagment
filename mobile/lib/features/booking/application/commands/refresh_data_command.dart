import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../commands/booking_command.dart';
import '../../../../core/events/data_change_event.dart';
import '../../../../core/observers/data_change_observer.dart';

/// Command to refresh data by emitting data change events
/// Uses the Observer Pattern to automatically invalidate related providers
class RefreshDataCommand implements BookingCommand {
  final WidgetRef ref;

  RefreshDataCommand(this.ref);

  @override
  Future<void> execute() async {
    final observer = ref.read(dataChangeObserverProvider);

    observer.notifyChange(
      const DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'court',
      ),
    );

    observer.notifyChange(
      const DataChangeEvent(
        changeType: DataChangeType.updated,
        entityType: 'booking',
      ),
    );
  }

  @override
  Future<void> undo() async {
    // Cannot undo a refresh operation
  }

  @override
  String getDescription() => 'Actualizar datos';
}
