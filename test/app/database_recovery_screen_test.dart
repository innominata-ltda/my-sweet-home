import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/database_recovery_screen.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/database/database_vault.dart';

import '../fakes/fake_database_vault.dart';

void main() {
  group('DatabaseRecoveryScreen — CA-3.4, CA-3.5 (RN-416, RN-417)', () {
    testWidgets(
      'CA-3.5: displays Import backup and Start from scratch options when VaultKeyUnavailable',
      (tester) async {
        final fakeVault = FakeDatabaseVault();
        var importCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseRecoveryScreen(
              opening: VaultKeyUnavailable(),
              vault: fakeVault,
              onImportBackup: () async {
                importCalled = true;
              },
            ),
          ),
        );

        expect(find.text('Chave do banco inacessível'), findsOneWidget);
        expect(
          find.byKey(const Key('recovery_import_backup_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recovery_restart_button')),
          findsOneWidget,
        );

        // Triggers backup import
        await tester.tap(
          find.byKey(const Key('recovery_import_backup_button')),
        );
        await tester.pump();
        expect(importCalled, isTrue);
      },
    );

    testWidgets(
      'CA-3.5: Reset from scratch requires double confirmation before destroying vault',
      (tester) async {
        final fakeVault = FakeDatabaseVault();
        var restartCompleted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseRecoveryScreen(
              opening: VaultKeyUnavailable(),
              vault: fakeVault,
              onRestartComplete: () async {
                restartCompleted = true;
              },
            ),
          ),
        );

        // 1. Taps reset from scratch button
        await tester.tap(find.byKey(const Key('recovery_restart_button')));
        await tester.pumpAndSettle();

        // First confirmation visible
        expect(find.text('Recomeçar do zero?'), findsOneWidget);
        expect(
          find.byKey(const Key('recovery_confirm_proceed_1')),
          findsOneWidget,
        );
        expect(fakeVault.destroyCalled, isFalse);

        // 2. Confirms first dialog
        await tester.tap(find.byKey(const Key('recovery_confirm_proceed_1')));
        await tester.pumpAndSettle();

        // Second confirmation visible (double confirmation — CA-3.5)
        expect(find.text('Confirmação definitiva'), findsOneWidget);
        expect(
          find.byKey(const Key('recovery_confirm_proceed_2')),
          findsOneWidget,
        );
        expect(fakeVault.destroyCalled, isFalse);

        // 3. Confirms second dialog definitively
        await tester.tap(find.byKey(const Key('recovery_confirm_proceed_2')));
        await tester.pumpAndSettle();

        expect(fakeVault.destroyCalled, isTrue);
        expect(restartCompleted, isTrue);
      },
    );

    testWidgets(
      'cancellation at any confirmation step does not destroy vault',
      (tester) async {
        final fakeVault = FakeDatabaseVault();

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseRecoveryScreen(
              opening: VaultKeyUnavailable(),
              vault: fakeVault,
            ),
          ),
        );

        // Opens first dialog and cancels
        await tester.tap(find.byKey(const Key('recovery_restart_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recovery_confirm_cancel_1')));
        await tester.pumpAndSettle();
        expect(fakeVault.destroyCalled, isFalse);

        // Opens first dialog, proceeds to second, and cancels
        await tester.tap(find.byKey(const Key('recovery_restart_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recovery_confirm_proceed_1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recovery_confirm_cancel_2')));
        await tester.pumpAndSettle();
        expect(fakeVault.destroyCalled, isFalse);
      },
    );

    testWidgets(
      'CA-3.4: exibe "Exportar backup" e "Continuar" quando VaultConversionFailed',
      (tester) async {
        final fakeVault = FakeDatabaseVault();
        final plaintextDb = AppDatabase.memory();
        addTearDown(plaintextDb.close);

        var exportCalled = false;
        var continueCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: DatabaseRecoveryScreen(
              opening: VaultConversionFailed(plaintextDb),
              vault: fakeVault,
              onExportBackup: () async {
                exportCalled = true;
              },
              onContinueWithPlaintext: () {
                continueCalled = true;
              },
            ),
          ),
        );

        expect(find.text('Falha na segurança do banco'), findsOneWidget);
        expect(
          find.byKey(const Key('recovery_export_backup_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recovery_continue_button')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('recovery_export_backup_button')),
        );
        await tester.pump();
        expect(exportCalled, isTrue);

        await tester.tap(find.byKey(const Key('recovery_continue_button')));
        await tester.pump();
        expect(continueCalled, isTrue);
      },
    );
  });
}
