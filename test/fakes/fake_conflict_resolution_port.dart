import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/tasks/domain/conflict_resolution_port.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

/// Deterministic fake of [ConflictResolutionPort] for unit tests.
class FakeConflictResolver implements ConflictResolutionPort {
  ConflictChoice? defaultChoice;
  final List<Conflict> resolvedConflicts = [];

  FakeConflictResolver([this.defaultChoice = ConflictChoice.keepLocal]);

  @override
  Future<Result<ConflictChoice, Failure>> resolve(Conflict conflict) async {
    resolvedConflicts.add(conflict);
    if (defaultChoice == null) {
      return const Err(CancelledFailure());
    }
    return Ok(defaultChoice!);
  }
}
