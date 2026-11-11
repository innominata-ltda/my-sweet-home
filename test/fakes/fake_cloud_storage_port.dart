import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/domain/cloud_storage_port.dart';

/// Deterministic fake of [CloudStoragePort] for unit and widget tests.
class FakeCloudStoragePort implements CloudStoragePort {
  final Map<String, String> remoteFiles = {};
  final Map<String, int> fileSizes = {};
  int uploadCallCount = 0;
  int downloadCallCount = 0;
  int listCallCount = 0;
  int sizeCallCount = 0;

  bool shouldFail = false;
  String? failureMessage;

  @override
  Future<Result<int, Failure>> backupSizeBytes({
    required String fileName,
  }) async {
    sizeCallCount++;
    if (shouldFail) {
      return const Err(NetworkFailure(isOffline: true));
    }
    final size = fileSizes[fileName] ?? (remoteFiles[fileName]?.length ?? 0);
    return Ok(size);
  }

  @override
  Future<Result<void, Failure>> uploadBackup({
    required String fileName,
    required String encryptedContent,
  }) async {
    uploadCallCount++;
    if (shouldFail) {
      return const Err(NetworkFailure(isOffline: true));
    }
    remoteFiles[fileName] = encryptedContent;
    return const Ok(null);
  }

  @override
  Future<Result<String, Failure>> downloadBackup({
    required String fileName,
  }) async {
    downloadCallCount++;
    if (shouldFail) {
      return const Err(NetworkFailure(isOffline: true));
    }
    final content = remoteFiles[fileName];
    if (content == null) {
      return Err(
        StorageFailure(detail: 'Backup file not found in cloud: $fileName'),
      );
    }
    return Ok(content);
  }

  @override
  Future<Result<List<String>, Failure>> listBackups() async {
    listCallCount++;
    if (shouldFail) {
      return const Err(NetworkFailure(isOffline: true));
    }
    return Ok(remoteFiles.keys.toList());
  }

  /// Limpa todos os contadores e arquivos remotos.
  void reset() {
    remoteFiles.clear();
    fileSizes.clear();
    uploadCallCount = 0;
    downloadCallCount = 0;
    listCallCount = 0;
    sizeCallCount = 0;
    shouldFail = false;
    failureMessage = null;
  }
}
