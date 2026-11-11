library;

import 'dart:convert';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_batch_factory.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/core/storage/cloud_storage_port.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_batch_codec.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

/// Async remote synchronization transport for household via user's cloud
/// (ADR-0011, RF-127, RN-333, CA-8.1, CA-8.2, T-17).
///
/// Uses a mailbox folder (store-and-forward) in user's cloud (Drive/iCloud),
/// com payloads criptografados de ponta a ponta com AES-256-GCM usando a chave da casa.
///
/// **RN-333 / CA-8.1:** No cloud request is performed if consent
/// `household_sync_remote` is denied or not granted.
class RemoteSyncTransport implements SyncTransportPort {
  final HouseholdRepository householdRepository;
  final HouseholdKeyStore keyStore;
  final ChangeSource changeSource;
  final TombstoneStore tombstoneStore;
  final SyncBatchCodec codec;
  final BatchApplier batchApplier;
  final SyncBatchFactory? batchFactory;
  final SettingsRepository settingsRepository;
  final CloudStoragePort cloudStoragePort;
  final Clock clock;

  RemoteSyncTransport({
    required this.householdRepository,
    required this.keyStore,
    required this.changeSource,
    required this.tombstoneStore,
    required this.codec,
    required this.batchApplier,
    this.batchFactory,
    required this.settingsRepository,
    required this.cloudStoragePort,
    required this.clock,
  });

  @override
  Future<Result<void, Failure>> start() async {
    // Async cloud transport does not maintain persistent socket connections
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> stop() async {
    return const Ok(null);
  }

  @override
  Stream<List<DiscoveredPeer>> watchPeers() => Stream.value(const []);

  @override
  Future<Result<SyncReport, Failure>> syncNow() async {
    // 1. Strict verification of prior consent (CA-8.1, RN-333)
    final isAllowed = await settingsRepository.isHouseholdSyncRemoteAllowed();
    if (!isAllowed) {
      return const Err(PermissionFailure(permission: 'household_sync_remote'));
    }

    // 2. Verification of active household
    final householdRes = await householdRepository.getHousehold();
    final household = householdRes.valueOrNull;
    if (household == null) {
      return const Ok(SyncReport());
    }

    // 3. Obtain household AES-256 symmetric key
    final keyRes = await keyStore.read();
    final key = keyRes.valueOrNull;
    if (key == null) {
      return const Err(HouseholdFailure('Chave da casa ausente.'));
    }

    var sentCount = 0;
    var appliedCount = 0;

    // 4. Send local changes to remote mailbox
    try {
      final SyncBatch localBatch;
      if (batchFactory != null) {
        final factoryRes = await batchFactory!.forRecipient(null);
        localBatch =
            factoryRes.valueOrNull ??
            SyncBatch(
              householdId: household.id,
              fromSiteId: household.localSiteId,
              senderVector: await changeSource.localVector(),
              changes:
                  (await changeSource.changesNotCoveredBy(
                    const VersionVector({}),
                    household.sharedAreas,
                  )).valueOrNull ??
                  [],
              purged: await tombstoneStore.getAllTombstones(),
            );
      } else {
        final changesRes = await changeSource.changesNotCoveredBy(
          const VersionVector({}),
          household.sharedAreas,
        );
        final changes = changesRes.valueOrNull ?? [];
        final tombstones = await tombstoneStore.getAllTombstones();

        final localVector = await changeSource.localVector();
        localBatch = SyncBatch(
          householdId: household.id,
          fromSiteId: household.localSiteId,
          senderVector: localVector,
          changes: changes,
          purged: tombstones,
        );
      }

      if (localBatch.changes.isNotEmpty || localBatch.purged.isNotEmpty) {
        final sealRes = await codec.seal(localBatch, key);
        if (sealRes.isErr) {
          return Err(sealRes.failureOrNull!);
        }
        final encryptedBytes = sealRes.valueOrNull!;
        final base64Payload = base64Encode(encryptedBytes);
        final fileName =
            'sync_${household.id}_${household.localSiteId}_${clock.nowUtc().millisecondsSinceEpoch}.syncbatch';

        final uploadRes = await cloudStoragePort.uploadBackup(
          fileName: fileName,
          encryptedContent: base64Payload,
        );

        if (uploadRes.isErr) {
          return Err(uploadRes.failureOrNull!);
        }
        sentCount = localBatch.changes.length + localBatch.purged.length;
      }
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha durante envio para armazenamento em nuvem: $e',
          cause: e,
        ),
      );
    }

    // 5. Download and apply changes from other household devices (CA-8.2)
    final contactedPeers = <String>{};
    try {
      final listRes = await cloudStoragePort.listBackups();
      if (listRes.isErr) {
        return Err(listRes.failureOrNull!);
      }

      final files = listRes.valueOrNull ?? [];
      final prefix = 'sync_${household.id}_';
      final ownInfix = '_${household.localSiteId}_';

      for (final fileName in files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith('.syncbatch')) {
          continue;
        }
        if (fileName.contains(ownInfix)) {
          // Ignore own batch
          continue;
        }

        final downloadRes = await cloudStoragePort.downloadBackup(
          fileName: fileName,
        );
        if (downloadRes.isOk) {
          final base64Content = downloadRes.valueOrNull!;
          try {
            final encryptedBytes = base64Decode(base64Content);
            final openRes = await codec.open(encryptedBytes, key);
            if (openRes.isOk) {
              final remoteBatch = openRes.valueOrNull!;
              if (remoteBatch.householdId == household.id) {
                contactedPeers.add(remoteBatch.fromSiteId);
                final applyRes = await batchApplier.apply(remoteBatch);
                if (applyRes.isOk) {
                  appliedCount +=
                      remoteBatch.changes.length + remoteBatch.purged.length;
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha durante sincronização remota: $e',
          cause: e,
        ),
      );
    }

    return Ok(
      SyncReport(
        sentChangesCount: sentCount,
        appliedChangesCount: appliedCount,
        peersContactedCount: contactedPeers.length,
      ),
    );
  }
}
