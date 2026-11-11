import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/domain/backup_bundle.dart';

/// Backup import mode.
enum ImportMode {
  /// Deletes all current data and replaces it with backup data.
  replace,

  /// Preserves current data and inserts/updates records from the backup.
  merge,
}

/// Preview data of a backup file before importation.
class BackupPreview {
  /// Backup schema version.
  final int schemaVersion;

  /// ISO 8601 timestamp of the export.
  final String exportedAt;

  /// Total number of records contained in the backup.
  final int totalRecords;

  /// Record count per table in the backup.
  final Map<String, int> tableRecordCounts;

  const BackupPreview({
    required this.schemaVersion,
    required this.exportedAt,
    required this.totalRecords,
    required this.tableRecordCounts,
  });

  /// One-sentence description for the "Replace all" option (RN-232).
  static const String replaceDescription =
      'Apaga todos os dados atuais do aplicativo e substitui pelos dados do backup.';

  /// One-sentence description for the "Merge" option (RN-232).
  static const String mergeDescription =
      'Mantém os dados atuais e adiciona novos registros ou atualiza existentes sem apagar nada.';
}

/// Stages of the export/backup creation process (RN-424, CA-5.1).
enum BackupStage {
  /// Reading and collecting database records.
  collecting,

  /// JSON serialization and encryption (AES-GCM 256 + Argon2id).
  encrypting,

  /// Writing or preparing the final file.
  writing,

  /// Process completed successfully.
  done,
}

/// Export and restore service for application data and backups.
abstract interface class BackupService {
  /// Exporta todos os dados do aplicativo em um [BackupBundle] (JSON + CSV).
  ///
  /// If [includePhotos] is `true`, includes Base64 content of receipt/recipe photos (RN-237).
  /// By default (`false`), photos are NOT included in the backup (RN-237).
  Future<Result<BackupBundle, Failure>> exportBackup({
    bool includePhotos = false,
  });

  /// Estima o tamanho total em bytes das fotos armazenadas no aplicativo (RN-237).
  Future<Result<int, Failure>> estimatePhotosSize();

  /// Generates the preview of JSON backup content (RN-232).
  Future<Result<BackupPreview, Failure>> previewBackup(String jsonContent);

  /// Restaura ou mescla os dados do aplicativo a partir da string JSON do backup.
  ///
  /// [mode] define se substitui todos os dados ([ImportMode.replace]) ou se
  /// merges with existing data ([ImportMode.merge]).
  Future<Result<void, Failure>> importBackup(
    String jsonContent, {
    ImportMode mode = ImportMode.replace,
  });

  /// Generates CSV export for expenses only.
  Future<Result<String, Failure>> exportExpensesCsv();

  /// Generates CSV export for purchases only.
  Future<Result<String, Failure>> exportPurchasesCsv();

  /// Exporta o backup criptografado no cliente com AES-GCM 256 + Argon2id (RN-234, ADR-0007).
  ///
  /// If [includePhotos] is `true`, includes Base64 content of photos (RN-237).
  /// [onStage] receives notifications of process stages for responsive UI (RN-424, CA-5.1).
  Future<Result<String, Failure>> exportEncryptedBackup(
    String password, {
    bool includePhotos = false,
    void Function(BackupStage stage)? onStage,
  });

  /// Restaura os dados a partir de um backup criptografado (RN-234, CA-3.1).
  Future<Result<void, Failure>> importEncryptedBackup(
    String encryptedContent,
    String password, {
    ImportMode mode = ImportMode.replace,
  });
}
