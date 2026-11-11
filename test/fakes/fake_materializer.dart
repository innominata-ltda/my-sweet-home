/// FakeMaterializer: test implementation for [RecurrenceMaterializer].
///
/// Tracks calls, received instants, and simulates materialization idempotence
/// (same day does not generate new occurrences — RN-017, CA-10.1).
library;

import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/result/result.dart';

/// Fake of [RecurrenceMaterializer] for deterministic tests.
final class FakeMaterializer implements RecurrenceMaterializer {
  FakeMaterializer({required this.kind, this.pendingCount = 1, this.failure});

  @override
  final RecurrenceKind kind;

  int pendingCount;
  Failure? failure;

  int callCount = 0;
  final List<DateTime> calledInstants = [];
  DateTime? lastMaterializedDate;

  @override
  Future<Result<int, Failure>> materializeUpTo(DateTime instant) async {
    callCount++;
    calledInstants.add(instant);

    if (failure != null) {
      return Err(failure!);
    }

    final dateOnly = DateTime.utc(instant.year, instant.month, instant.day);
    if (lastMaterializedDate != null && lastMaterializedDate == dateOnly) {
      // Already materialized on the same day: does not create any new occurrence (RN-017, CA-10.1)
      return const Ok(0);
    }

    lastMaterializedDate = dateOnly;
    final count = pendingCount;
    pendingCount = 0;
    return Ok(count);
  }
}
