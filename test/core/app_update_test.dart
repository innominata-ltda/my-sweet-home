import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/update/app_update_adapter.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';
import 'package:my_sweet_home/core/update/app_update_service.dart';
import 'package:my_sweet_home/data/database/database.dart';

import '../fakes/fake_clock.dart';

import '../fakes/fake_app_update_port.dart';

void main() {
  group('SPEC-001 / T-G05 — AppUpdateService Unit Tests', () {
    late AppDatabase db;
    late FakeClock clock;
    late FakeAppUpdatePort fakePort;
    late AppUpdateService service;

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(DateTime.utc(2026, 10, 24, 12));
      fakePort = FakeAppUpdatePort(
        updateAvailable: true,
        availableVersionLabel: '0.2.0',
        availableVersionCode: 20,
      );
      service = AppUpdateService(port: fakePort, clock: clock, db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('checkSilentlyForDashboard returns info when update is available and without cooldown', () async {
      final info = await service.checkSilentlyForDashboard();

      expect(info, isNotNull);
      expect(info?.updateAvailable, isTrue);
      expect(info?.availableVersionLabel, '0.2.0');
      expect(info?.availableVersionCode, 20);
      expect(fakePort.checkForUpdateCallCount, 1);
    });

    test(
      'checkSilentlyForDashboard returns null when no update is available',
      () async {
        fakePort.updateAvailable = false;

        final info = await service.checkSilentlyForDashboard();

        expect(info, isNull);
        expect(fakePort.checkForUpdateCallCount, 1);
      },
    );

    test('checkSilentlyForDashboard silently ignores store unavailable / offline failure (RN-041)', () async {
      fakePort.failure = const AppUpdateStoreUnavailable();

      final info = await service.checkSilentlyForDashboard();

      expect(info, isNull);
      expect(fakePort.checkForUpdateCallCount, 1);
    });

    test('24h cooldown: after dismissing, does not query store before 24 hours (RN-041, RN-042)', () async {
      // First query: update is available
      final firstCheck = await service.checkSilentlyForDashboard();
      expect(firstCheck, isNotNull);
      expect(fakePort.checkForUpdateCallCount, 1);

      // User dismisses dialog
      await service.recordDismissedFor24Hours();

      // Advances 12 hours in time
      clock.advance(const Duration(hours: 12));

      // Second query before 24h: must return null WITHOUT calling port
      final secondCheck = await service.checkSilentlyForDashboard();
      expect(secondCheck, isNull);
      expect(fakePort.checkForUpdateCallCount, 1); // Count did not increase

      // Advances another 13 hours (total 25 hours)
      clock.advance(const Duration(hours: 13));

      // Third query after 24h: cooldown expired, should query again
      final thirdCheck = await service.checkSilentlyForDashboard();
      expect(thirdCheck, isNotNull);
      expect(fakePort.checkForUpdateCallCount, 2); // Chamou novamente
    });

    test(
      'startUpdate registra cooldown e dispara startUpdate na porta (RN-042)',
      () async {
        final result = await service.startUpdate();

        expect(result.isOk, isTrue);
        expect(fakePort.startUpdateCallCount, 1);

        // Cooldown registrado
        final lastPrompt = await service.getLastPromptTimestamp();
        expect(lastPrompt, clock.nowUtc());
      },
    );

    test(
      'checkManually ignora cooldown e consulta a porta sob demanda (RN-043)',
      () async {
        await service.recordDismissedFor24Hours();

        // Manual check immediately after dismissing
        final result = await service.checkManually();

        expect(result.isOk, isTrue);
        expect(result.valueOrNull?.updateAvailable, isTrue);
        expect(fakePort.checkForUpdateCallCount, 1);
      },
    );

    test('checkSilentlyForDashboard returns null when not installed from Play Store', () async {
      fakePort.installedFromPlayStore = false;
      fakePort.updateAvailable = true;

      final info = await service.checkSilentlyForDashboard();

      expect(info, isNull);
      expect(await service.isInstalledFromPlayStore(), isFalse);
    });

    test('isInstalledFromPlayStore returns false on failure and true for Play installs', () async {
      expect(await service.isInstalledFromPlayStore(), isTrue);

      fakePort.failure = const AppUpdateStoreUnavailable();
      expect(await service.isInstalledFromPlayStore(), isFalse);
    });

    test('openExternalUrl delegates to port', () async {
      const url = 'https://github.com/innominata-ltda/my-sweet-home';
      final result = await service.openExternalUrl(url);

      expect(result.isOk, isTrue);
      expect(fakePort.openedUrls, [url]);
    });
  });

  group('MethodChannelAppUpdateAdapter Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('br.com.innominata.mysweethome/app_update');
    late MethodChannelAppUpdateAdapter adapter;

    setUp(() {
      adapter = const MethodChannelAppUpdateAdapter(channel: channel);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'checkForUpdate converts successful response with available version',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'checkForUpdate') {
                return {
                  'updateAvailable': true,
                  'availableVersionLabel': '1.0.1',
                  'availableVersionCode': 101,
                };
              }
              return null;
            });

        final result = await adapter.checkForUpdate();

        expect(result.isOk, isTrue);
        final info = result.valueOrNull!;
        expect(info.updateAvailable, isTrue);
        expect(info.availableVersionLabel, '1.0.1');
        expect(info.availableVersionCode, 101);
      },
    );

    test(
      'checkForUpdate mapeia STORE_UNAVAILABLE para AppUpdateStoreUnavailable',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(
                code: 'STORE_UNAVAILABLE',
                message: 'Play Store offline',
              );
            });

        final result = await adapter.checkForUpdate();

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<AppUpdateStoreUnavailable>());
      },
    );

    test(
      'startUpdate mapeia USER_CANCELLED para AppUpdateUserCancelled',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(code: 'USER_CANCELLED');
            });

        final result = await adapter.startUpdate();

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<AppUpdateUserCancelled>());
      },
    );

    test('openExternalUrl invokes channel and maps errors', () async {
      const url = 'https://github.com/innominata-ltda/my-sweet-home';
      String? invokedMethod;
      dynamic invokedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            invokedMethod = call.method;
            invokedArgs = call.arguments;
            return null;
          });

      final okResult = await adapter.openExternalUrl(url);
      expect(okResult.isOk, isTrue);
      expect(invokedMethod, 'openExternalUrl');
      expect(invokedArgs, {'url': url});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'UNAVAILABLE', message: 'No browser');
          });

      final errResult = await adapter.openExternalUrl(url);
      expect(errResult.isErr, isTrue);
      expect(errResult.failureOrNull, isA<AppUpdateFailed>());
    });
  });
}
