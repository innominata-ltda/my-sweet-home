import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';

/// Use case to leave shared household.
class LeaveHouseholdUseCase {
  final HouseholdRepository _repository;

  const LeaveHouseholdUseCase(this._repository);

  Future<Result<void, Failure>> execute({required bool keepCopy}) {
    return _repository.leaveHousehold(keepCopy: keepCopy);
  }
}
