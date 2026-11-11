library;

import '../../result/result.dart';

/// Port implemented by each feature to recalculate derived data or reschedule
/// notifications after a sync batch is applied (RN-327, CA-5.4, CA-5.6).
abstract interface class DerivedDataRebuilder {
  /// Table names whose changes trigger this rebuilder.
  Set<String> get watchesTables;

  /// Recalculates derived data for touched IDs.
  Future<Result<void, Failure>> rebuild(Set<String> touchedRowIds);
}
