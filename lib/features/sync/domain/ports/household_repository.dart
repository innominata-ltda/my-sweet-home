import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// Falha ao operar sobre a casa compartilhada.
final class HouseholdFailure extends Failure {
  final String message;
  final Object? cause;

  const HouseholdFailure(this.message, [this.cause]);

  @override
  String toString() => 'HouseholdFailure: $message';
}

/// Porta para gerenciamento da casa compartilhada e seus membros.
abstract interface class HouseholdRepository {
  /// Retorna a casa atualmente ativa, ou nulo se nenhuma existir.
  Future<Result<Household?, Failure>> getHousehold();

  /// Observes changes in active household.
  Stream<Household?> watchHousehold();

  /// Retorna a lista de membros da casa.
  Future<Result<List<Member>, Failure>> getMembers();

  /// Observa a lista de membros da casa.
  Stream<List<Member>> watchMembers();

  /// Creates a new household with this device as first member.
  Future<Result<Household, Failure>> createHousehold({
    required String name,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
  });

  /// Updates active areas of household.
  Future<Result<void, Failure>> updateSharedAreas(Set<SyncArea> areas);

  /// Runs initial column versions backfill for pre-existing local data (T-08).
  Future<Result<int, Failure>> runInitialBackfill(Household household);

  /// Checks whether untransmitted local changes exist for other members (CA-6.1).
  Future<Result<bool, Failure>> hasPendingLocalChanges();

  /// Sai da casa compartilhada (RF-126, CA-7.2, CA-7.3, T-15).
  ///
  /// If [keepCopy] is true, keeps local data and only disables sync.
  /// If [keepCopy] is false, deletes shared areas data from device.
  Future<Result<void, Failure>> leaveHousehold({required bool keepCopy});

  /// Obtains preview of record count per area before joining a household (RN-314, T-10).
  Future<Result<HouseholdJoinPreviewData, Failure>> getJoinPreviewData();

  /// Joins an existing household using pairing data.
  Future<Result<Household, Failure>> joinHousehold({
    required String householdId,
    required String householdName,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
    List<Member> existingMembers = const [],
  });

  /// Remove um membro da casa (RF-126, CA-7.1, T-14).
  Future<Result<void, Failure>> removeMember(String memberId);

  /// Registers or updates a member by siteId and nickname (e.g., discovered via LAN or batch).
  Future<Result<void, Failure>> upsertMember({
    required String siteId,
    required String deviceName,
    DateTime? lastSeenAt,
  });
}
