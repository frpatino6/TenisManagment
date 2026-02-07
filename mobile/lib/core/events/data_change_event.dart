/// Event types for data changes
enum DataChangeType { created, updated, deleted }

/// Represents a data change event in the application
/// Used by the Observer Pattern to notify about data mutations
class DataChangeEvent {
  /// Type of change that occurred
  final DataChangeType changeType;

  /// Entity type that changed (e.g., 'booking', 'court', 'payment', 'student')
  final String entityType;

  /// Optional ID of the specific entity that changed
  final String? entityId;

  /// Optional metadata about the change
  final Map<String, dynamic>? metadata;

  const DataChangeEvent({
    required this.changeType,
    required this.entityType,
    this.entityId,
    this.metadata,
  });

  @override
  String toString() {
    return 'DataChangeEvent(changeType: $changeType, entityType: $entityType, entityId: $entityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataChangeEvent &&
        other.changeType == changeType &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(changeType, entityType, entityId);
}
