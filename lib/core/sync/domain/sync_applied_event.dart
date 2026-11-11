library;

/// Event emitted when a synchronization batch is successfully applied to the database.
final class SyncAppliedEvent {
  /// Household identifier.
  final String householdId;

  /// Sender device identifier.
  final String fromSiteId;

  /// Touched table names.
  final Set<String> touchedTables;

  /// Touched row identifiers.
  final Set<String> touchedRowIds;

  /// Total count of applied column changes.
  final int changesAppliedCount;

  const SyncAppliedEvent({
    required this.householdId,
    required this.fromSiteId,
    required this.touchedTables,
    required this.touchedRowIds,
    required this.changesAppliedCount,
  });

  @override
  String toString() =>
      'SyncAppliedEvent(household: $householdId, from: $fromSiteId, changes: $changesAppliedCount)';
}
