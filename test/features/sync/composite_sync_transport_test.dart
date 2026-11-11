import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/data/composite_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/lan_sync_transport.dart';
import 'package:my_sweet_home/features/sync/data/remote_sync_transport.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';

import '../../fakes/fake_settings_repository.dart';

class MockLanSyncTransport extends Mock implements LanSyncTransport {}

class MockRemoteSyncTransport extends Mock implements RemoteSyncTransport {}

void main() {
  group('CompositeSyncTransport (ADR-0011, RF-122, RF-127)', () {
    late MockLanSyncTransport mockLan;
    late MockRemoteSyncTransport mockRemote;
    late FakeSettingsRepository fakeSettings;
    late CompositeSyncTransport transport;

    setUp(() {
      mockLan = MockLanSyncTransport();
      mockRemote = MockRemoteSyncTransport();
      fakeSettings = FakeSettingsRepository();

      transport = CompositeSyncTransport(
        lanTransport: mockLan,
        remoteTransport: mockRemote,
        settingsRepository: fakeSettings,
      );
    });

    test(
      'syncNow executa apenas LAN quando sincronização remota estiver negada',
      () async {
        await fakeSettings.setHouseholdSyncRemoteAllowed(false);

        when(() => mockLan.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 3,
              appliedChangesCount: 2,
              peersContactedCount: 1,
            ),
          ),
        );

        final result = await transport.syncNow();

        expect(result.isOk, isTrue);
        expect(result.valueOrNull!.sentChangesCount, 3);
        expect(result.valueOrNull!.appliedChangesCount, 2);
        expect(result.valueOrNull!.peersContactedCount, 1);

        verify(() => mockLan.syncNow()).called(1);
        verifyNever(() => mockRemote.syncNow());
      },
    );

    test(
      'syncNow combines LAN and Cloud reports when remote consent is permitted',
      () async {
        await fakeSettings.setHouseholdSyncRemoteAllowed(true);

        when(() => mockLan.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 2,
              appliedChangesCount: 1,
              peersContactedCount: 1,
            ),
          ),
        );

        when(() => mockRemote.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 5,
              appliedChangesCount: 4,
              peersContactedCount: 1,
            ),
          ),
        );

        final result = await transport.syncNow();

        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;
        expect(report.sentChangesCount, 7); // 2 LAN + 5 Remoto
        expect(report.appliedChangesCount, 5); // 1 LAN + 4 Remoto
        expect(report.peersContactedCount, 2); // 1 LAN + 1 Remoto

        verify(() => mockLan.syncNow()).called(1);
        verify(() => mockRemote.syncNow()).called(1);
      },
    );

    test(
      'syncNow works via Cloud even when LAN finds no peers on local network',
      () async {
        await fakeSettings.setHouseholdSyncRemoteAllowed(true);

        // LAN found no peers (0 peers, 0 changes)
        when(() => mockLan.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 0,
              appliedChangesCount: 0,
              peersContactedCount: 0,
            ),
          ),
        );

        // Cloud finds remote batch and sends changes
        when(() => mockRemote.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 3,
              appliedChangesCount: 3,
              peersContactedCount: 1,
            ),
          ),
        );

        final result = await transport.syncNow();

        expect(result.isOk, isTrue);
        final report = result.valueOrNull!;
        expect(report.sentChangesCount, 3);
        expect(report.appliedChangesCount, 3);
        expect(report.peersContactedCount, 1);
      },
    );

    test('start e stop delegam para lanTransport e remoteTransport', () async {
      when(() => mockLan.start()).thenAnswer((_) async => const Ok(null));
      when(() => mockLan.stop()).thenAnswer((_) async => const Ok(null));
      when(() => mockRemote.stop()).thenAnswer((_) async => const Ok(null));

      final startRes = await transport.start();
      expect(startRes.isOk, isTrue);
      verify(() => mockLan.start()).called(1);

      final stopRes = await transport.stop();
      expect(stopRes.isOk, isTrue);
      verify(() => mockRemote.stop()).called(1);
      verify(() => mockLan.stop()).called(1);
    });

    test(
      'syncNow propagates remote transport failure when LAN finds no peers',
      () async {
        await fakeSettings.setHouseholdSyncRemoteAllowed(true);

        when(() => mockLan.syncNow()).thenAnswer(
          (_) async => const Ok(
            SyncReport(
              sentChangesCount: 0,
              appliedChangesCount: 0,
              peersContactedCount: 0,
            ),
          ),
        );

        when(() => mockRemote.syncNow()).thenAnswer(
          (_) async =>
              const Err(StorageFailure(detail: 'Drive sem autorização')),
        );

        final result = await transport.syncNow();
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<StorageFailure>());
      },
    );
  });
}
