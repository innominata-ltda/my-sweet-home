import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/join_household_usecase.dart';
import 'package:my_sweet_home/features/sync/presentation/join_preview.dart';

import '../../fakes/fake_household_backup_port.dart';
import '../../fakes/fake_household_repository.dart';

void main() {
  group('T-10 / RF-121 / RN-314 — Join Household and Preview', () {
    late FakeHouseholdRepository repository;
    late FakeHouseholdBackupPort backupPort;
    late JoinHouseholdUseCase useCase;
    const testKey = HouseholdKey([
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
    ]);

    setUp(() {
      repository = FakeHouseholdRepository();
      backupPort = FakeHouseholdBackupPort();
      useCase = JoinHouseholdUseCase(
        repository: repository,
        backupPort: backupPort,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('getPreview retorna contagem de registros locais', () async {
      final preview = await useCase.getPreview();
      expect(preview.isOk, isTrue);
      expect(preview.valueOrNull!.homeRecordsCount, 5);
      expect(preview.valueOrNull!.financeRecordsCount, 10);
      expect(preview.valueOrNull!.catalogRecordsCount, 20);
      expect(preview.valueOrNull!.totalRecordsCount, 35);
    });

    test(
      'execute generates automatic backup before joining (RN-314)',
      () async {
        expect(backupPort.exportCallCount, 0);

        final result = await useCase.execute(
          householdId: 'h-100',
          householdName: 'Casa Teste',
          deviceName: 'Pixel 8',
          sharedAreas: {SyncArea.home, SyncArea.finance},
          key: testKey,
          existingMembers: [
            Member(
              id: 'm-host',
              householdId: 'h-100',
              siteId: 'site-host',
              name: 'Anfitrião',
              joinedAt: DateTime.utc(2026, 10, 1),
            ),
          ],
        );

        expect(result.isOk, isTrue);
        expect(backupPort.exportCallCount, 1);
        expect(repository.household, isNotNull);
        expect(repository.household!.name, 'Casa Teste');
        expect(repository.members.length, 2);
        expect(repository.members.first.name, 'Pixel 8');
      },
    );

    test(
      'se o backup falhar, a adesão é abortada sem alterar a casa',
      () async {
        backupPort.shouldFail = true;

        final result = await useCase.execute(
          householdId: 'h-100',
          householdName: 'Casa Teste',
          deviceName: 'Pixel 8',
          sharedAreas: {SyncArea.home},
          key: testKey,
        );

        expect(result.isErr, isTrue);
        expect(repository.household, isNull);
      },
    );

    testWidgets(
      'JoinPreviewDialog exibe contagens e executa adesão ao confirmar',
      (tester) async {
        var joinedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => JoinPreviewDialog(
                          householdId: 'h-200',
                          householdName: 'República Verde',
                          sharedAreas: const {SyncArea.home},
                          householdKey: testKey,
                          useCase: useCase,
                          onJoined: () => joinedCalled = true,
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

        expect(find.text('Entrar em "República Verde"'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(
          find.textContaining('backup automático de segurança'),
          findsOneWidget,
        );

        await tester.tap(find.text('Entrar na casa'));
        await tester.pumpAndSettle();

        expect(joinedCalled, isTrue);
        expect(backupPort.exportCallCount, 1);
        expect(find.byType(JoinPreviewDialog), findsNothing);
      },
    );
  });
}
