import '../../../data/database/database.dart';

/// Ledger of applied .mshsync bundles for guaranteed idempotency (RN-409, CA-2.7).
final class AppliedBundleLedger {
  final AppDatabase _db;

  AppliedBundleLedger(this._db);

  /// Returns whether bundle with given SHA-256 hash was previously applied.
  Future<bool> contains(String sha256Hex) async {
    final query = _db.select(_db.syncAppliedBundles)
      ..where((tbl) => tbl.digest.equals(sha256Hex));
    final row = await query.getSingleOrNull();
    return row != null;
  }

  /// Records bundle application in ledger with UTC timestamp.
  Future<void> record(String sha256Hex, DateTime atUtc) async {
    await _db
        .into(_db.syncAppliedBundles)
        .insertOnConflictUpdate(
          SyncAppliedBundlesCompanion.insert(
            digest: sha256Hex,
            appliedAt: atUtc.toIso8601String(),
          ),
        );
  }
}
