import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';
import 'package:my_sweet_home/features/backup/domain/cloud_storage_port.dart';

/// Service responsible for managing upload and restore of cloud backups (Drive/iCloud).
///
/// **RN-234:** O backup em nuvem DEVE ser criptografado no aparelho antes de sair,
/// with key derived from user password.
/// **RN-235:** Backup MUST go to user's own account (Drive/iCloud), never to project server,
/// and **only with `cloud_backup` consent**.
/// **CA-4.1:** Given `cloud_backup` consent denied, no cloud request is performed.
class CloudBackupService {
  final BackupService backupService;
  final CloudStoragePort cloudStoragePort;
  final SettingsRepository settingsRepository;
  final SecurityLimits limits;

  const CloudBackupService({
    required this.backupService,
    required this.cloudStoragePort,
    required this.settingsRepository,
    this.limits = const SecurityLimits(),
  });

  /// Uploads encrypted backup to user cloud storage.
  ///
  /// DEVE verificar primeiro se o consentimento `cloud_backup` foi concedido em [SettingsRepository].
  /// If denied (default), MUST NOT perform any external request (CA-4.1, RN-235).
  Future<Result<void, Failure>> uploadCloudBackup({
    required String password,
    String fileName = 'my_sweet_home_backup.enc',
  }) async {
    final isAllowed = await settingsRepository.isCloudBackupAllowed();
    if (!isAllowed) {
      return const Err(PermissionFailure(permission: 'cloud_backup'));
    }

    final encryptRes = await backupService.exportEncryptedBackup(password);
    if (encryptRes.isErr) {
      return Err(encryptRes.failureOrNull!);
    }

    final encryptedContent = encryptRes.valueOrNull!;
    return cloudStoragePort.uploadBackup(
      fileName: fileName,
      encryptedContent: encryptedContent,
    );
  }

  /// Downloads and restores encrypted backup from user cloud storage.
  ///
  /// DEVE verificar primeiro se o consentimento `cloud_backup` foi concedido em [SettingsRepository].
  /// If denied, MUST NOT perform any external request (CA-4.1, RN-235).
  Future<Result<void, Failure>> restoreCloudBackup({
    required String password,
    String fileName = 'my_sweet_home_backup.enc',
    ImportMode mode = ImportMode.replace,
  }) async {
    final isAllowed = await settingsRepository.isCloudBackupAllowed();
    if (!isAllowed) {
      return const Err(PermissionFailure(permission: 'cloud_backup'));
    }

    final sizeRes = await cloudStoragePort.backupSizeBytes(fileName: fileName);
    if (sizeRes.isErr) {
      return Err(sizeRes.failureOrNull!);
    }

    final size = sizeRes.valueOrNull!;
    if (size > limits.maxBackupBytes) {
      return const Err(
        ValidationFailure(
          fields: {
            'size': 'O arquivo de backup excede o tamanho máximo permitido.',
          },
        ),
      );
    }

    final downloadRes = await cloudStoragePort.downloadBackup(
      fileName: fileName,
    );
    if (downloadRes.isErr) {
      return Err(downloadRes.failureOrNull!);
    }

    final encryptedContent = downloadRes.valueOrNull!;
    return backupService.importEncryptedBackup(
      encryptedContent,
      password,
      mode: mode,
    );
  }

  /// Lists backups stored in user's own cloud storage.
  ///
  /// DEVE verificar primeiro se o consentimento `cloud_backup` foi concedido.
  Future<Result<List<String>, Failure>> listCloudBackups() async {
    final isAllowed = await settingsRepository.isCloudBackupAllowed();
    if (!isAllowed) {
      return const Err(PermissionFailure(permission: 'cloud_backup'));
    }

    return cloudStoragePort.listBackups();
  }
}
