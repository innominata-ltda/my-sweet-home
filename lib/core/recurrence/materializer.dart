/// Contract and use case for recurring item materialization (RN-017).
///
/// Materialization of recurrences MUST be triggered at a single point — app
/// bootstrap, once per session — for expenses, bills, and tasks.
/// No feature should trigger its own materialization on demand, preventing
/// duplicate occurrences from concurrent executions.
library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';

/// Entity kinds with recurrence support in the system.
enum RecurrenceKind {
  /// Recurring expenses (SPEC-005).
  expense,

  /// Recurring fixed bills (SPEC-006).
  bill,

  /// Recurring household tasks (SPEC-007).
  task,
}

/// Interface exposed by each feature for its recurrences to be
/// materialized.
///
/// Each feature registers its materializer at bootstrap; none triggers
/// materialization autonomously (RN-017, RN-114, RN-142, RN-162).
abstract interface class RecurrenceMaterializer {
  /// Recurrence kind handled by this materializer.
  RecurrenceKind get kind;

  /// Materializes all pending occurrences up to [instant] (in UTC).
  ///
  /// Returns the count of materialized occurrences on success ([Ok]),
  /// or a [Failure] on error ([Err]).
  Future<Result<int, Failure>> materializeUpTo(DateTime instant);
}

/// Use case that triggers materialization of all registered recurrences.
///
/// Executed exclusively during application bootstrap (RN-017).
abstract interface class MaterializeRecurrencesUseCase {
  /// Executes materialization for all registered materializers.
  ///
  /// Returns a map of total materialized occurrences per [RecurrenceKind],
  /// or the first encountered [Failure].
  Future<Result<Map<RecurrenceKind, int>, Failure>> call();
}

/// Default implementation of [MaterializeRecurrencesUseCase].
///
/// Iterates over registered [RecurrenceMaterializer] implementations and
/// delegates materialization up to current [Clock] instant.
final class DefaultMaterializeRecurrences
    implements MaterializeRecurrencesUseCase {
  const DefaultMaterializeRecurrences({
    required this.materializers,
    required this.clock,
  });

  /// List of registered materializers per feature.
  final List<RecurrenceMaterializer> materializers;

  /// System clock or test fake clock.
  final Clock clock;

  @override
  Future<Result<Map<RecurrenceKind, int>, Failure>> call() async {
    final now = clock.nowUtc();
    final results = <RecurrenceKind, int>{};

    for (final materializer in materializers) {
      final result = await materializer.materializeUpTo(now);
      switch (result) {
        case Ok(:final value):
          results[materializer.kind] =
              (results[materializer.kind] ?? 0) + value;
        case Err(:final failure):
          return Err(failure);
      }
    }

    return Ok(results);
  }
}
