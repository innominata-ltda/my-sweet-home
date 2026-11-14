import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/backup/domain/backup_service.dart';
import 'package:my_sweet_home/features/backup/presentation/export_backup_screen.dart';
import 'package:my_sweet_home/features/backup/presentation/import_backup_screen.dart';

class _MockBackupService extends Mock implements BackupService {}

void main() {
  group('ExportBackupScreen', () {
    testWidgets('calls exportEncryptedBackup and shareBackup on submit', (
      tester,
    ) async {
      final service = _MockBackupService();
      when(
        () => service.exportEncryptedBackup(
          'secret123',
          includePhotos: false,
          onStage: any(named: 'onStage'),
        ),
      ).thenAnswer((_) async => const Ok('{"salt":"abc","ciphertext":"xyz"}'));

      String? sharedContent;
      String? sharedFileName;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ExportBackupScreen(
              backupService: service,
              shareBackup: (content, name) async {
                sharedContent = content;
                sharedFileName = name;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('export_backup_button')));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(sharedContent, '{"salt":"abc","ciphertext":"xyz"}');
      expect(sharedFileName, 'my_sweet_home_backup.mshbackup');
      expect(
        find.text('Backup gerado e exportado com sucesso!'),
        findsOneWidget,
      );
    });

    testWidgets('shows error snackbar when exportEncryptedBackup fails', (
      tester,
    ) async {
      final service = _MockBackupService();
      when(
        () => service.exportEncryptedBackup(
          'secret123',
          includePhotos: false,
          onStage: any(named: 'onStage'),
        ),
      ).thenAnswer((_) async => const Err(StorageFailure(detail: 'disk full')));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ExportBackupScreen(
              backupService: service,
              shareBackup: (_, _) async {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('export_backup_button')));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao gerar backup:'), findsOneWidget);
    });
  });

  group('ImportBackupScreen file picker', () {
    testWidgets('picks plain JSON backup and loads preview', (tester) async {
      final service = _MockBackupService();
      when(() => service.previewBackup('{"tables":{}}')).thenAnswer(
        (_) async => Ok(
          const BackupPreview(
            exportedAt: '2026-11-14T10:00:00Z',
            schemaVersion: 1,
            tableRecordCounts: {'tasks': 3},
            totalRecords: 3,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ImportBackupScreen(
              backupService: service,
              pickBackupContent: () async => '{"tables":{}}',
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('import_backup_pick_file_button')));
      await tester.pumpAndSettle();

      verify(() => service.previewBackup('{"tables":{}}')).called(1);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('picks encrypted backup, prompts password, and imports', (
      tester,
    ) async {
      final service = _MockBackupService();
      const envelope = '{"salt":"abc","ciphertext":"xyz"}';
      when(
        () => service.importEncryptedBackup(
          envelope,
          'pass123',
          mode: ImportMode.replace,
        ),
      ).thenAnswer((_) async => const Ok(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ImportBackupScreen(
              backupService: service,
              pickBackupContent: () async => envelope,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('import_backup_pick_file_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('import_encrypted_password_field')),
        'pass123',
      );
      await tester.tap(
        find.byKey(const Key('import_encrypted_confirm_button')),
      );
      await tester.pumpAndSettle();

      verify(
        () => service.importEncryptedBackup(
          envelope,
          'pass123',
          mode: ImportMode.replace,
        ),
      ).called(1);
      expect(find.text('Backup restaurado com sucesso!'), findsOneWidget);
    });
  });
}
