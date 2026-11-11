library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_backup_port.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Use case to join an existing shared household.
///
/// 1. Allows querying preview of local records grouped by area (RN-314).
/// 2. Performs automatic safety export (SPEC-010, RN-314) before merging data.
/// 3. Writes key and household/members record, runs backfill and deterministic unification without duplicating data.
class JoinHouseholdUseCase {
  final HouseholdRepository repository;
  final HouseholdBackupPort? backupPort;

  const JoinHouseholdUseCase({required this.repository, this.backupPort});

  /// Obtains preview of local record count by area before confirming join.
  Future<Result<HouseholdJoinPreviewData, Failure>> getPreview() {
    return repository.getJoinPreviewData();
  }

  /// Executes process of joining household with prior automatic export.
  Future<Result<Household, Failure>> execute({
    required String householdId,
    required String householdName,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
    List<Member> existingMembers = const [],
  }) async {
    final cleanDeviceName = deviceName.trim();
    if (cleanDeviceName.isEmpty) {
      return const Err(
        HouseholdFailure('O nome do aparelho não pode ser vazio.'),
      );
    }

    if (sharedAreas.isEmpty) {
      return const Err(
        HouseholdFailure(
          'A casa deve conter pelo menos uma área compartilhada.',
        ),
      );
    }

    // 1. Generates automatic prior export (SPEC-010, RN-314)
    if (backupPort != null) {
      final exportResult = await backupPort!.exportBackup();
      if (exportResult.isErr) {
        return Err(
          HouseholdFailure(
            'Falha ao gerar export prévio de segurança: ${exportResult.failureOrNull}',
          ),
        );
      }
    }

    // 2. Registra na base e une os dados sem duplicar
    return repository.joinHousehold(
      householdId: householdId,
      householdName: householdName,
      deviceName: cleanDeviceName,
      sharedAreas: sharedAreas,
      key: key,
      existingMembers: existingMembers,
    );
  }
}
