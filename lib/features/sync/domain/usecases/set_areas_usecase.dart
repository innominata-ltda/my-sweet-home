import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';

/// Use case to update active areas of shared household (RF-121, CA-2.1, T-13).
class SetAreasUseCase {
  final HouseholdRepository _repository;

  const SetAreasUseCase(this._repository);

  Future<Result<void, Failure>> execute(Set<SyncArea> areas) async {
    if (areas.isEmpty) {
      return const Err(
        HouseholdFailure(
          'Ao menos uma área compartilhada deve permanecer ativa.',
        ),
      );
    }
    return _repository.updateSharedAreas(areas);
  }
}
