library;

import 'package:my_sweet_home/core/result/result.dart';

/// Abstraction port for user's personal cloud storage service (Drive / iCloud).
///
/// **RN-235 / RN-333:** Backup and remote synchronization MUST target the user's
/// own cloud account (Drive/iCloud), never project servers, and strictly with
/// prior opt-in consent (`cloud_backup` or `household_sync_remote`).
abstract interface class CloudStoragePort {
  /// Returns size in bytes of the remote backup file (RN-402).
  Future<Result<int, Failure>> backupSizeBytes({required String fileName});

  /// Uploads encrypted backup or batch payload to the user's cloud account.
  Future<Result<void, Failure>> uploadBackup({
    required String fileName,
    required String encryptedContent,
  });

  /// Downloads encrypted backup payload from the user's cloud account.
  Future<Result<String, Failure>> downloadBackup({required String fileName});

  /// Lists available file names in user's cloud storage.
  Future<Result<List<String>, Failure>> listBackups();
}
