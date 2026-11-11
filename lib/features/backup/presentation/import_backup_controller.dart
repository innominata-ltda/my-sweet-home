import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/core/errors/user_message.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';

/// States of backup preview and import flow.
sealed class ImportBackupState {}

/// Estado inicial.
final class ImportBackupInitial extends ImportBackupState {}

/// Loading preview or executing import.
final class ImportBackupLoading extends ImportBackupState {}

/// Preview ready, allowing selection of mode (Replace vs Merge).
final class ImportBackupPreviewReady extends ImportBackupState {
  final BackupPreview preview;
  final String jsonContent;
  final ImportMode selectedMode;

  ImportBackupPreviewReady({
    required this.preview,
    required this.jsonContent,
    this.selectedMode = ImportMode.replace,
  });

  ImportBackupPreviewReady copyWith({
    BackupPreview? preview,
    String? jsonContent,
    ImportMode? selectedMode,
  }) {
    return ImportBackupPreviewReady(
      preview: preview ?? this.preview,
      jsonContent: jsonContent ?? this.jsonContent,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }
}

/// Import completed successfully.
final class ImportBackupSuccess extends ImportBackupState {
  final ImportMode importedMode;
  ImportBackupSuccess({required this.importedMode});
}

/// Error during preview or import.
final class ImportBackupError extends ImportBackupState {
  final String message;
  ImportBackupError(this.message);
}

/// Controller responsible for backup preview and import state (RN-232).
class ImportBackupController extends ValueNotifier<ImportBackupState> {
  final BackupService backupService;

  ImportBackupController({required this.backupService})
    : super(ImportBackupInitial());

  /// Generates preview from JSON backup content.
  Future<void> loadPreview(String jsonContent) async {
    value = ImportBackupLoading();
    final result = await backupService.previewBackup(jsonContent);

    result.fold(
      (preview) {
        value = ImportBackupPreviewReady(
          preview: preview,
          jsonContent: jsonContent,
        );
      },
      (failure) {
        value = ImportBackupError(_failureToMessage(failure));
      },
    );
  }

  /// Selects import mode ([ImportMode.replace] or [ImportMode.merge]).
  void selectMode(ImportMode mode) {
    final currentState = value;
    if (currentState is ImportBackupPreviewReady) {
      value = currentState.copyWith(selectedMode: mode);
    }
  }

  /// Executes import in selected mode.
  Future<void> confirmImport() async {
    final currentState = value;
    if (currentState is! ImportBackupPreviewReady) return;

    final mode = currentState.selectedMode;
    final jsonContent = currentState.jsonContent;

    value = ImportBackupLoading();
    final result = await backupService.importBackup(jsonContent, mode: mode);

    result.fold(
      (_) {
        value = ImportBackupSuccess(importedMode: mode);
      },
      (failure) {
        value = ImportBackupError(_failureToMessage(failure));
      },
    );
  }

  String _failureToMessage(Failure failure) => userMessageFor(failure);
}
