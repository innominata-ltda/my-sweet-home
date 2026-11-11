import 'package:my_sweet_home/core/settings/settings_repository.dart';
import 'package:my_sweet_home/core/storage/file_store_port.dart';

/// Result of attempt to clean receipt photo after processing (RN-202, CA-6.1).
enum PhotoCleanupResult {
  /// Photo was deleted from device ("delete photo" setting active).
  deleted,

  /// Photo was kept in private storage ("delete photo" setting inactive).
  retained,

  /// No action was performed (null, empty path or file not found).
  skipped,

  /// Cleanup attempt failed (e.g. permission or system I/O error).
  failed,
}

/// Receipt photo cleanup service post-processing (RF-048, RN-202, CA-6.1).
///
/// Responsible for deleting original receipt photo after OCR processing
/// when [isDeleteReceiptPhotoEnabled] in [SettingsRepository] is active (default: active).
final class ReceiptPhotoCleaner {
  final FileStorePort fileStorePort;
  final SettingsRepository settingsRepository;

  const ReceiptPhotoCleaner({
    required this.fileStorePort,
    required this.settingsRepository,
  });

  /// Deletes original receipt photo at [imagePath] if cleanup setting is active.
  ///
  /// Retorna [PhotoCleanupResult.deleted] se a foto foi removida do dispositivo,
  /// [PhotoCleanupResult.retained] if photo was kept because option was inactive,
  /// [PhotoCleanupResult.skipped] se o caminho for nulo, em branco ou inexistente,
  /// or [PhotoCleanupResult.failed] if deletion failed due to filesystem error.
  Future<PhotoCleanupResult> cleanUpPhoto(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return PhotoCleanupResult.skipped;
    }

    try {
      final shouldDelete = await settingsRepository
          .isDeleteReceiptPhotoEnabled();
      if (!shouldDelete) {
        return PhotoCleanupResult.retained;
      }

      final exists = await fileStorePort.exists(imagePath);
      if (!exists) {
        return PhotoCleanupResult.skipped;
      }

      await fileStorePort.delete(imagePath);
      return PhotoCleanupResult.deleted;
    } catch (_) {
      return PhotoCleanupResult.failed;
    }
  }
}
