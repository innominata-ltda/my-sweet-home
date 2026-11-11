import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_warning_service.dart';

import '../../fakes/fake_battery_optimization.dart';
import '../../fakes/fake_battery_warning_storage.dart';

void main() {
  group('BatteryWarningService', () {
    test('Android: should show warning on first save', () async {
      final opt = FakeBatteryOptimization(isAndroid: true);
      final storage = FakeBatteryWarningStorage(hasSeen: false);
      final service = BatteryWarningService(opt, storage);

      final shouldShow = await service.shouldShowWarningOnSave();
      expect(shouldShow, isTrue);
      expect(storage.hasSeen, isTrue);
    });

    test('Android: should not show warning on second save', () async {
      final opt = FakeBatteryOptimization(isAndroid: true);
      final storage = FakeBatteryWarningStorage(hasSeen: true);
      final service = BatteryWarningService(opt, storage);

      final shouldShow = await service.shouldShowWarningOnSave();
      expect(shouldShow, isFalse);
    });

    test('iOS: should not show warning on first save', () async {
      final opt = FakeBatteryOptimization(isAndroid: false);
      final storage = FakeBatteryWarningStorage(hasSeen: false);
      final service = BatteryWarningService(opt, storage);

      final shouldShow = await service.shouldShowWarningOnSave();
      expect(shouldShow, isFalse);
      expect(storage.hasSeen, isFalse);
    });

    test('Android: should show persistent hint if warning dismissed', () async {
      final opt = FakeBatteryOptimization(isAndroid: true);
      final storage = FakeBatteryWarningStorage(hasSeen: true);
      final service = BatteryWarningService(opt, storage);

      final shouldShow = await service.shouldShowPersistentHint();
      expect(shouldShow, isTrue);
    });

    test(
      'Android: should not show persistent hint if warning never seen',
      () async {
        final opt = FakeBatteryOptimization(isAndroid: true);
        final storage = FakeBatteryWarningStorage(hasSeen: false);
        final service = BatteryWarningService(opt, storage);

        final shouldShow = await service.shouldShowPersistentHint();
        expect(shouldShow, isFalse);
      },
    );

    test('iOS: should not show persistent hint', () async {
      final opt = FakeBatteryOptimization(isAndroid: false);
      final storage = FakeBatteryWarningStorage(hasSeen: true);
      final service = BatteryWarningService(opt, storage);

      final shouldShow = await service.shouldShowPersistentHint();
      expect(shouldShow, isFalse);
    });
  });
}
