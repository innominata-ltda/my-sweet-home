/// Application bootstrap — single startup initialization (RN-017, RN-015).
///
/// Single entry point for startup tasks, such as recurrence materialization
/// and daily trash sweeping. No feature triggers its own on-demand materialization.
library;

import 'dart:collection';

import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/seed_loader.dart';

/// Consolidated report of app bootstrap routine.
///
/// Inherits from [UnmodifiableMapView<RecurrenceKind, int>] to maintain full
/// compatibility with code expecting `Map<RecurrenceKind, int>`,
/// additionally exposing [sweptTrashCount].
final class BootstrapReport extends UnmodifiableMapView<RecurrenceKind, int> {
  BootstrapReport({
    required Map<RecurrenceKind, int> recurrenceCounts,
    this.sweptTrashCount = 0,
  }) : recurrenceCounts = Map.unmodifiable(recurrenceCounts),
       super(recurrenceCounts);

  /// Occurrences created per recurrence kind.
  final Map<RecurrenceKind, int> recurrenceCounts;

  /// Number of expired records purged from trash.
  final int sweptTrashCount;
}

/// Executes app bootstrap routine upon startup.
///
/// Triggers:
/// 1. Materialization of all registered recurrences via [materializer] (RN-017, CA-10.1).
/// 2. Sweeping of expired trash records via [trashPolicy] or [trashSweepers] (RN-015, CA-9.2).
///
/// Returns the consolidated report [BootstrapReport] or a failure on error.
Future<Result<BootstrapReport, Failure>> bootstrap(
  MaterializeRecurrencesUseCase materializer, {
  TrashPolicy? trashPolicy,
  Iterable<TrashPolicy>? trashSweepers,
  SeedLoader? seedLoader,
}) async {
  if (seedLoader != null) {
    final seedResult = await seedLoader.loadIfNeeded();
    if (seedResult.isErr) {
      // Seed loading failure, continue startup if non-critical
    }
  }

  final recurrenceResult = await materializer.call();
  if (recurrenceResult.isErr) {
    return Err(recurrenceResult.failureOrNull!);
  }

  var totalSwept = 0;
  final policies = <TrashPolicy>[?trashPolicy, ...?trashSweepers];

  for (final policy in policies) {
    final sweepResult = await policy.sweepExpired();
    if (sweepResult.isErr) {
      return Err(sweepResult.failureOrNull!);
    }
    totalSwept += sweepResult.valueOrNull!;
  }

  return Ok(
    BootstrapReport(
      recurrenceCounts: recurrenceResult.valueOrNull!,
      sweptTrashCount: totalSwept,
    ),
  );
}
