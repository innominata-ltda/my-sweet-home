import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/sync/batch_applier.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';
import 'package:my_sweet_home/data/sync/sync_batch_factory.dart';
import 'package:my_sweet_home/data/sync/tombstones.dart';
import 'package:my_sweet_home/features/sync/data/applied_bundle_ledger.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_key_store.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_batch_codec.dart';

/// File/bundle-based (.mshsync) synchronization transport (RF-123, RN-331, RN-409, CA-2.7, CA-4.1, CA-4.2, T-12).
///
/// Generates AES-256-GCM encrypted bundles for transport via any sharing channel (messaging, email, etc.)
/// and apply them atomically and idempotently on another device of the same household.
class BundleSyncTransport {
  final HouseholdRepository householdRepository;
  final HouseholdKeyStore keyStore;
  final ChangeSource changeSource;
  final TombstoneStore tombstoneStore;
  final SyncBatchCodec codec;
  final BatchApplier batchApplier;
  final SyncBatchFactory? batchFactory;
  final AppliedBundleLedger? appliedBundleLedger;
  final Clock clock;

  BundleSyncTransport({
    required this.householdRepository,
    required this.keyStore,
    required this.changeSource,
    required this.tombstoneStore,
    required this.codec,
    required this.batchApplier,
    this.batchFactory,
    this.appliedBundleLedger,
    this.clock = const SystemClock(),
  });

  /// Generates encrypted binary bundle (.mshsync) containing all active areas changes.
  Future<Result<Uint8List, Failure>> generateBundle({
    Set<SyncArea>? areas,
  }) async {
    final householdResult = await householdRepository.getHousehold();
    final household = householdResult.valueOrNull;
    if (household == null) {
      return const Err(
        HouseholdFailure('Nenhuma casa ativa encontrada para gerar pacote.'),
      );
    }

    final keyResult = await keyStore.read();
    final key = keyResult.valueOrNull;
    if (key == null) {
      return const Err(
        HouseholdFailure('Chave da casa ausente no armazenamento seguro.'),
      );
    }

    final effectiveAreas = areas ?? household.sharedAreas;

    final SyncBatch batch;
    if (batchFactory != null) {
      final factoryRes = await batchFactory!.forRecipient(null);
      if (factoryRes.isErr) {
        return Err(factoryRes.failureOrNull!);
      }
      batch = factoryRes.valueOrNull!;
    } else {
      final changesResult = await changeSource.changesNotCoveredBy(
        const VersionVector({}),
        effectiveAreas,
      );
      if (changesResult.isErr) {
        return Err(changesResult.failureOrNull!);
      }

      final changes = changesResult.valueOrNull ?? [];
      final tombstones = await tombstoneStore.getAllTombstones();
      final localVector = await changeSource.localVector();

      batch = SyncBatch(
        householdId: household.id,
        fromSiteId: household.localSiteId,
        senderVector: localVector,
        changes: changes,
        purged: tombstones,
      );
    }

    return codec.seal(batch, key);
  }

  /// Decrypts, authenticates and applies a received binary bundle.
  Future<Result<ApplyReport, Failure>> applyBundle(Uint8List bytes) async {
    final digest = await Sha256().hash(bytes);
    final sha256Hex = _bytesToHex(digest.bytes);
    if (appliedBundleLedger != null &&
        await appliedBundleLedger!.contains(sha256Hex)) {
      return const Ok(ApplyReport(alreadyApplied: true));
    }

    final householdResult = await householdRepository.getHousehold();
    final household = householdResult.valueOrNull;
    if (household == null) {
      return const Err(
        HouseholdFailure('Nenhuma casa ativa encontrada para aplicar pacote.'),
      );
    }

    final keyResult = await keyStore.read();
    final key = keyResult.valueOrNull;
    if (key == null) {
      return const Err(
        HouseholdFailure('Chave da casa ausente no armazenamento seguro.'),
      );
    }

    final openResult = await codec.open(bytes, key);
    if (openResult.isErr) {
      return Err(openResult.failureOrNull!);
    }

    final batch = openResult.valueOrNull!;
    if (batch.householdId != household.id) {
      return const Err(
        HouseholdFailure('O pacote pertence a outra casa compartilhada.'),
      );
    }

    final applyResult = await batchApplier.apply(batch);
    if (applyResult.isOk) {
      await appliedBundleLedger?.record(sha256Hex, clock.nowUtc());
    }
    return applyResult;
  }

  static String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
