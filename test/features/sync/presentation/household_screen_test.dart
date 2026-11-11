import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/design_system/theme/app_theme.dart';
import 'package:my_sweet_home/features/sync/data/household_repository_provider.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/create_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/join_household_usecase.dart';
import 'package:my_sweet_home/features/sync/domain/usecases/sync_now_usecase.dart';
import 'package:my_sweet_home/features/sync/presentation/household_screen.dart';
import 'package:my_sweet_home/features/sync/presentation/join_preview.dart';
import 'package:my_sweet_home/features/sync/presentation/providers/household_providers.dart';

import '../../../../test/fakes/fake_household_key_store.dart';
import '../../../../test/fakes/fake_household_repository.dart';
import '../../../../test/fakes/fake_settings_repository.dart';

class MockSyncNowUseCase extends Mock implements SyncNowUseCase {}

class DelayedCreateHouseholdUseCase extends CreateHouseholdUseCase {
  final Completer<Result<Household, Failure>> completer;
  DelayedCreateHouseholdUseCase({
    required super.repository,
    required this.completer,
  });

  @override
  Future<Result<Household, Failure>> execute({
    required String householdName,
    required String deviceName,
    Set<SyncArea> sharedAreas = const {SyncArea.home, SyncArea.finance},
  }) {
    return completer.future;
  }
}

class FailingCreateHouseholdUseCase extends CreateHouseholdUseCase {
  final Failure failure;
  FailingCreateHouseholdUseCase({
    required super.repository,
    required this.failure,
  });

  @override
  Future<Result<Household, Failure>> execute({
    required String householdName,
    required String deviceName,
    Set<SyncArea> sharedAreas = const {SyncArea.home, SyncArea.finance},
  }) async {
    return Err(failure);
  }
}

void main() {
  group('HouseholdScreen (T-08, RF-120..127, CA-4.1..4.4, CA-6.1)', () {
    late FakeHouseholdRepository fakeRepo;
    late FakeSettingsRepository fakeSettingsRepo;
    late FakeHouseholdKeyStore fakeKeyStore;

    setUp(() {
      fakeRepo = FakeHouseholdRepository();
      fakeSettingsRepo = FakeSettingsRepository();
      fakeKeyStore = FakeHouseholdKeyStore(
        HouseholdKey(List.generate(32, (i) => i)),
      );
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    Widget buildSubject({
      CreateHouseholdUseCase? customCreateUseCase,
      SyncNowUseCase? customSyncNowUseCase,
    }) {
      return ProviderScope(
        overrides: [
          householdRepositoryProvider.overrideWithValue(fakeRepo),
          householdKeyStoreProvider.overrideWithValue(fakeKeyStore),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          createHouseholdUseCaseProvider.overrideWithValue(
            customCreateUseCase ??
                CreateHouseholdUseCase(
                  repository: fakeRepo,
                  keyGenerator: () => List.generate(32, (i) => i),
                ),
          ),
          joinHouseholdUseCaseProvider.overrideWithValue(
            JoinHouseholdUseCase(repository: fakeRepo),
          ),
          if (customSyncNowUseCase != null)
            syncNowUseCaseProvider.overrideWithValue(customSyncNowUseCase),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: lightTheme(),
          home: const HouseholdScreen(),
        ),
      );
    }

    testWidgets(
      'displays empty state with create household button when there is no active household',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Compartilhe a sua casa'), findsOneWidget);
        expect(
          find.byKey(const Key('create_household_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('join_household_button')), findsOneWidget);
      },
    );

    testWidgets(
      'creates household via dialog and updates screen with members and status',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Tap Create household
        await tester.tap(find.byKey(const Key('create_household_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('household_name_input')), findsOneWidget);
        expect(find.byKey(const Key('device_name_input')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('household_name_input')),
          'Casa da Duda',
        );
        await tester.enterText(
          find.byKey(const Key('device_name_input')),
          'Celular da Duda',
        );

        await tester.tap(
          find.byKey(const Key('confirm_create_household_button')),
        );
        await tester.pumpAndSettle();

        // Screen now displays created household
        expect(find.text('Casa da Duda'), findsOneWidget);
        expect(find.text('Celular da Duda'), findsOneWidget);
        expect(find.text('Este aparelho'), findsOneWidget);
        expect(find.byKey(const Key('sync_now_button')), findsOneWidget);
        expect(find.byKey(const Key('invite_device_button')), findsOneWidget);
      },
    );

    testWidgets(
      'CA-4.1: Joining a household opens JoinPreviewDialog preview and confirms link creation',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Tap Join household
        final joinBtn = find.byKey(const Key('join_household_button'));
        expect(joinBtn, findsOneWidget);
        await tester.tap(joinBtn);
        await tester.pumpAndSettle();

        // Enter invite code and device name
        expect(find.byKey(const Key('join_invite_code_input')), findsOneWidget);
        expect(find.byKey(const Key('join_device_name_input')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('join_invite_code_input')),
          'mshsync://invite?code=123',
        );
        await tester.enterText(
          find.byKey(const Key('join_device_name_input')),
          'Tablet da Sala',
        );

        // Tap Continue to open JoinPreviewDialog
        await tester.tap(find.byKey(const Key('confirm_join_preview_button')));
        await tester.pumpAndSettle();

        // Verify preview dialog is open
        expect(find.byType(JoinPreviewDialog), findsOneWidget);

        // Confirm in JoinPreviewDialog
        final confirmJoinBtn = find.text('Entrar na casa');
        await tester.ensureVisible(confirmJoinBtn);
        await tester.tap(confirmJoinBtn);
        await tester.pumpAndSettle();

        // Household is now active and member was created
        expect(fakeRepo.household, isNotNull);
        expect(fakeRepo.members.any((m) => m.name == 'Tablet da Sala'), isTrue);
      },
    );

    testWidgets(
      'CA-4.2: Invite device opens modal with QR code and 6-digit SAS code',
      (tester) async {
        final now = DateTime.utc(2026, 3, 15);
        final household = Household(
          id: 'h-1',
          name: 'Casa da Duda',
          localSiteId: 's-1',
          sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
          createdAt: now,
          joinedAt: now,
          active: true,
        );
        fakeRepo.setHousehold(household);
        fakeRepo.setMembers([
          Member(
            id: 'm-1',
            householdId: 'h-1',
            siteId: 's-1',
            name: 'Celular da Duda',
            joinedAt: now,
            active: true,
          ),
        ]);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Tap Invite device
        final inviteBtn = find.byKey(const Key('invite_device_button'));
        expect(inviteBtn, findsOneWidget);
        await tester.tap(inviteBtn);
        await tester.pumpAndSettle();

        // Pairing modal open with real QrImageView, copy/share buttons and dynamic SAS
        expect(find.byKey(const Key('pairing_invite_dialog')), findsOneWidget);
        expect(find.byKey(const Key('pairing_qr_image')), findsOneWidget);
        expect(find.byKey(const Key('pairing_invite_code')), findsOneWidget);
        expect(
          find.byKey(const Key('copy_invite_link_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('share_invite_link_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pairing_sas_code')), findsOneWidget);
        final sasText = tester.widget<Text>(
          find.byKey(const Key('pairing_sas_code')),
        );
        expect(sasText.data, isNot(equals('123456')));

        // Close modal
        await tester.tap(find.text('Fechar'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pairing_invite_dialog')), findsNothing);
      },
    );

    testWidgets(
      'Household tutorial opens automatically on first creation, asks about remote sync and can be repeated',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(await fakeSettingsRepo.isHouseholdTutorialCompleted(), isFalse);
        expect(await fakeSettingsRepo.isHouseholdSyncRemoteAllowed(), isFalse);

        // Create household for the first time
        await tester.tap(find.byKey(const Key('create_household_button')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('confirm_create_household_button')),
        );
        await tester.pumpAndSettle();

        // Tutorial opened automatically
        expect(
          find.byKey(const Key('household_tutorial_dialog')),
          findsOneWidget,
        );

        // Advance to Step 4 (question about remote sync)
        await tester.tap(find.byKey(const Key('tutorial_next_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tutorial_next_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tutorial_next_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Deseja habilitar a sincronização remota agora?'),
          findsOneWidget,
        );

        // Choose to enable remote sync and complete
        await tester.tap(
          find.byKey(const Key('tutorial_remote_sync_enable_option')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tutorial_finish_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('household_tutorial_dialog')),
          findsNothing,
        );
        expect(await fakeSettingsRepo.isHouseholdTutorialCompleted(), isTrue);
        expect(await fakeSettingsRepo.isHouseholdSyncRemoteAllowed(), isTrue);

        // Repeat tutorial via AppBar button
        await tester.tap(find.byKey(const Key('household_tutorial_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('household_tutorial_dialog')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('tutorial_close_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('household_tutorial_dialog')),
          findsNothing,
        );
      },
    );

    testWidgets('CA-4.3: Sync now, toggle remote sync and import bundle work', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.utc(2026, 3, 15);
      final household = Household(
        id: 'h-1',
        name: 'Casa da Duda',
        localSiteId: 's-1',
        sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
        createdAt: now,
        joinedAt: now,
        active: true,
      );
      fakeRepo.setHousehold(household);
      fakeRepo.setMembers([
        Member(
          id: 'm-1',
          householdId: 'h-1',
          siteId: 's-1',
          name: 'Celular da Duda',
          joinedAt: now,
          active: true,
        ),
      ]);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // 1. Sync now
      final syncBtn = find.byKey(const Key('sync_now_button'));
      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // 2. Toggle remote sync
      final remoteSyncSwitch = find.byKey(
        const Key('household_sync_remote_switch'),
      );
      await tester.ensureVisible(remoteSyncSwitch);
      await tester.pumpAndSettle();
      expect(remoteSyncSwitch, findsOneWidget);
      expect(await fakeSettingsRepo.isHouseholdSyncRemoteAllowed(), isFalse);

      await tester.tap(remoteSyncSwitch);
      await tester.pumpAndSettle();
      expect(await fakeSettingsRepo.isHouseholdSyncRemoteAllowed(), isTrue);

      // 3. Import bundle
      final importBtn = find.byKey(const Key('import_bundle_button'));
      expect(importBtn, findsOneWidget);
      await tester.tap(importBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_bundle_dialog')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('bundle_input_field')),
        'sample-sync-bundle-data',
      );
      await tester.tap(find.byKey(const Key('confirm_import_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_bundle_dialog')), findsNothing);
    });

    testWidgets(
      'CA-4.4: Displays member last seen, calendar owner switch and secondary member removal',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.utc(2026, 3, 15, 10, 30);
        final household = Household(
          id: 'h-1',
          name: 'Casa da Duda',
          localSiteId: 's-1',
          sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
          createdAt: now,
          joinedAt: now,
          active: true,
        );
        final selfMember = Member(
          id: 'm-1',
          householdId: 'h-1',
          siteId: 's-1',
          name: 'Celular da Duda (Host)',
          joinedAt: now,
          active: true,
        );
        final otherMember = Member(
          id: 'm-2',
          householdId: 'h-1',
          siteId: 's-2',
          name: 'Celular do Pedro',
          joinedAt: now,
          lastSeenAt: now,
          active: true,
        );

        fakeRepo.setHousehold(household);
        fakeRepo.setMembers([selfMember, otherMember]);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Verify last seen display
        expect(find.text('Este aparelho'), findsOneWidget);
        expect(
          find.text('Visto por último: 2026-03-15T10:30:00.000Z'),
          findsOneWidget,
        );

        // Calendar owner switch present
        final calendarSwitch = find.byKey(const Key('calendar_owner_switch'));
        expect(calendarSwitch, findsOneWidget);

        // Secondary member removal button present
        final removeBtn = find.byKey(const Key('remove_member_button_m-2'));
        expect(removeBtn, findsOneWidget);

        // Tap remove member
        await tester.tap(removeBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('confirm_remove_member_dialog')),
          findsOneWidget,
        );

        // Confirm removal
        await tester.tap(find.byKey(const Key('confirm_remove_member_button')));
        await tester.pumpAndSettle();

        // Secondary member was removed from repository
        expect(fakeRepo.members.any((m) => m.id == 'm-2'), isFalse);
      },
    );

    testWidgets(
      'T-B01: displays loading indicator, progress text and disabled buttons during creation',
      (tester) async {
        final completer = Completer<Result<Household, Failure>>();
        final delayedUseCase = DelayedCreateHouseholdUseCase(
          repository: fakeRepo,
          completer: completer,
        );

        await tester.pumpWidget(
          buildSubject(customCreateUseCase: delayedUseCase),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_household_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('household_name_input')),
          'Casa Nova',
        );
        await tester.enterText(
          find.byKey(const Key('device_name_input')),
          'Meu Celular',
        );

        // Trigger submission
        await tester.tap(
          find.byKey(const Key('confirm_create_household_button')),
        );
        await tester.pump(); // Start async state

        // Verify indicator and progress text
        expect(find.text('Criando casa e preparando dados...'), findsOneWidget);

        // Verify disabled buttons
        final cancelBtn = tester.widget<TextButton>(
          find.byKey(const Key('cancel_create_household_button')),
        );
        expect(cancelBtn.onPressed, isNull);

        final confirmBtn = tester.widget<FilledButton>(
          find.byKey(const Key('confirm_create_household_button')),
        );
        expect(confirmBtn.onPressed, isNull);

        // Verify PopScope blocks back button during submission
        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        expect(popScope.canPop, isFalse);

        // Complete creation
        final created = await fakeRepo.createHousehold(
          name: 'Casa Nova',
          deviceName: 'Meu Celular',
          sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
          key: HouseholdKey(List.generate(32, (i) => i)),
        );
        completer.complete(created);
        await tester.pumpAndSettle();

        // Dialog closed and household was created
        expect(find.text('Casa Nova'), findsOneWidget);
      },
    );

    testWidgets(
      'T-B01: creation failure keeps dialog open, displays error and clears on field edit',
      (tester) async {
        final failingUseCase = FailingCreateHouseholdUseCase(
          repository: fakeRepo,
          failure: const HouseholdFailure('Chave de criptografia inválida.'),
        );

        await tester.pumpWidget(
          buildSubject(customCreateUseCase: failingUseCase),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_household_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('household_name_input')),
          'Casa com Erro',
        );
        await tester.enterText(
          find.byKey(const Key('device_name_input')),
          'Aparelho',
        );

        await tester.tap(
          find.byKey(const Key('confirm_create_household_button')),
        );
        await tester.pumpAndSettle();

        // Dialog remains open and error message is displayed
        expect(
          find.byKey(const Key('create_household_error_text')),
          findsOneWidget,
        );
        expect(find.text('Chave de criptografia inválida.'), findsOneWidget);

        // Typing new text clears error message
        await tester.enterText(
          find.byKey(const Key('household_name_input')),
          'Casa Corrigida',
        );
        await tester.pump();
        expect(
          find.byKey(const Key('create_household_error_text')),
          findsNothing,
        );

        // Buttons are re-enabled for a retry
        final cancelBtn = tester.widget<TextButton>(
          find.byKey(const Key('cancel_create_household_button')),
        );
        expect(cancelBtn.onPressed, isNotNull);
      },
    );

    testWidgets(
      'T-B02: displays message in SnackBar when remote is active and there are no pending changes',
      (tester) async {
        final now = DateTime.utc(2026, 3, 15, 10, 0);
        final household = Household(
          id: 'h-sync',
          name: 'Casa Sync',
          localSiteId: 's-1',
          sharedAreas: {SyncArea.home},
          createdAt: now,
          joinedAt: now,
          active: true,
        );
        fakeRepo.setHousehold(household);
        fakeRepo.setMembers([
          Member(
            id: 'm-1',
            householdId: 'h-sync',
            siteId: 's-1',
            name: 'Celular 1',
            joinedAt: now,
            active: true,
          ),
        ]);
        await fakeSettingsRepo.setHouseholdSyncRemoteAllowed(true);

        final mockSync = MockSyncNowUseCase();
        when(mockSync.execute).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 0,
              appliedChangesCount: 0,
              peersContactedCount: 0,
            ),
          ),
        );

        await tester.pumpWidget(buildSubject(customSyncNowUseCase: mockSync));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('sync_now_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Sincronização em nuvem concluída. Nenhuma alteração pendente.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('T-B02: displays error in SnackBar when sync fails', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 3, 15, 10, 0);
      final household = Household(
        id: 'h-sync-err',
        name: 'Casa Sync Erro',
        localSiteId: 's-1',
        sharedAreas: {SyncArea.home},
        createdAt: now,
        joinedAt: now,
        active: true,
      );
      fakeRepo.setHousehold(household);
      fakeRepo.setMembers([
        Member(
          id: 'm-1',
          householdId: 'h-sync-err',
          siteId: 's-1',
          name: 'Celular 1',
          joinedAt: now,
          active: true,
        ),
      ]);

      final mockSync = MockSyncNowUseCase();
      when(mockSync.execute).thenAnswer(
        (_) async => const Err(
          StorageFailure(detail: 'Sem autorização no Google Drive'),
        ),
      );

      await tester.pumpWidget(buildSubject(customSyncNowUseCase: mockSync));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sync_now_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Falha na sincronização: Sem autorização no Google Drive'),
        findsOneWidget,
      );
    });

    testWidgets(
      'T-B02: displays device count and applied changes in SnackBar',
      (tester) async {
        final now = DateTime.utc(2026, 3, 15, 10, 0);
        final household = Household(
          id: 'h-sync-applied',
          name: 'Casa Sync Aplicada',
          localSiteId: 's-1',
          sharedAreas: {SyncArea.home},
          createdAt: now,
          joinedAt: now,
          active: true,
        );
        fakeRepo.setHousehold(household);
        fakeRepo.setMembers([
          Member(
            id: 'm-1',
            householdId: 'h-sync-applied',
            siteId: 's-1',
            name: 'Celular 1',
            joinedAt: now,
            active: true,
          ),
        ]);

        final mockSync = MockSyncNowUseCase();
        when(mockSync.execute).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 2,
              appliedChangesCount: 3,
              peersContactedCount: 1,
            ),
          ),
        );

        await tester.pumpWidget(buildSubject(customSyncNowUseCase: mockSync));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('sync_now_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Sincronizado com 1 aparelho(s) (2 enviadas, 3 aplicadas).',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
