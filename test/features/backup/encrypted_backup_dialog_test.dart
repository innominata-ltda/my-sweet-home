import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/backup/presentation/encrypted_backup_dialog.dart';

void main() {
  group('T-04 — EncryptedBackupDialog Widget Tests', () {
    testWidgets(
      'EncryptedBackupExportDialog exibe aviso explícito sobre perda de senha (RN-234)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogCtx) => EncryptedBackupExportDialog(
                          onExportRequested: (
                            pass, {
                            includePhotos = false,
                          }) async {},
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Backup Criptografado'), findsOneWidget);
        expect(
          find.text('Se você perder a senha, o backup é perdido.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'O aplicativo não salva sua senha nem consegue ler o backup sem ela. Não há opção de recuperação.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('EncryptedBackupExportDialog valida senha vazia e divergente', (
      tester,
    ) async {
      String? exportedPassword;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogCtx) => EncryptedBackupExportDialog(
                        onExportRequested:
                            (pass, {includePhotos = false}) async {
                              exportedPassword = pass;
                            },
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Tenta exportar sem preencher senha
      await tester.tap(find.text('Exportar Criptografado'));
      await tester.pumpAndSettle();

      expect(
        find.text('Informe uma senha para proteger o backup'),
        findsOneWidget,
      );

      // Fill password and different confirmation
      await tester.enterText(find.byType(TextFormField).at(0), '12345');
      await tester.enterText(find.byType(TextFormField).at(1), '54321');
      await tester.tap(find.text('Exportar Criptografado'));
      await tester.pumpAndSettle();

      expect(find.text('As senhas não coincidem'), findsOneWidget);

      // Preenche senhas iguais e confirma
      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tester.tap(find.text('Exportar Criptografado'));
      await tester.pumpAndSettle();

      expect(exportedPassword, equals('12345'));
    });

    testWidgets(
      'EncryptedBackupImportDialog solicita senha e executa restauração',
      (tester) async {
        String? importedPassword;

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogCtx) => EncryptedBackupImportDialog(
                          onImportRequested: (pass) async {
                            importedPassword = pass;
                          },
                        ),
                      );
                    },
                    child: const Text('Abrir Import'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Import'));
        await tester.pumpAndSettle();

        expect(find.text('Restaurar Backup Criptografado'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'senha_teste_123');
        await tester.tap(find.text('Descriptografar e Restaurar'));
        await tester.pumpAndSettle();

        expect(importedPassword, equals('senha_teste_123'));
      },
    );

    testWidgets(
      'T-07 — EncryptedBackupExportDialog exibe checkbox desmarcada por padrão (RN-237) e tamanho estimado',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogCtx) => EncryptedBackupExportDialog(
                          estimatedPhotosSizeBytes: 1572864, // 1,50 MB
                          onExportRequested: (
                            pass, {
                            includePhotos = false,
                          }) async {},
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Incluir fotos no backup (RN-237)'), findsOneWidget);
        expect(find.textContaining('1,50 MB'), findsOneWidget);

        final checkbox = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        expect(checkbox.value, isFalse);
      },
    );

    testWidgets(
      'T-07 — EncryptedBackupExportDialog permite marcar fotos e repassa no callback onExportRequested',
      (tester) async {
        bool? exportedWithPhotos;

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogCtx) => EncryptedBackupExportDialog(
                          onExportRequested:
                              (pass, {includePhotos = false}) async {
                                exportedWithPhotos = includePhotos;
                              },
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        // Check photos option
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), '12345');
        await tester.enterText(find.byType(TextFormField).at(1), '12345');
        await tester.tap(find.text('Exportar Criptografado'));
        await tester.pumpAndSettle();

        expect(exportedWithPhotos, isTrue);
      },
    );
  });
}
