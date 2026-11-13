import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';

void main() {
  group('AppUpdateInfo', () {
    test('props, equality, and toString work correctly', () {
      const info1 = AppUpdateInfo(
        updateAvailable: true,
        availableVersionLabel: '1.2.0',
        availableVersionCode: 12,
      );
      const info2 = AppUpdateInfo(
        updateAvailable: true,
        availableVersionLabel: '1.2.0',
        availableVersionCode: 12,
      );
      const info3 = AppUpdateInfo(
        updateAvailable: false,
        availableVersionLabel: '1.1.0',
        availableVersionCode: 11,
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1 == info3, isFalse);

      const infoDiffLabel = AppUpdateInfo(
        updateAvailable: true,
        availableVersionLabel: '1.2.1',
        availableVersionCode: 12,
      );
      const infoDiffCode = AppUpdateInfo(
        updateAvailable: true,
        availableVersionLabel: '1.2.0',
        availableVersionCode: 13,
      );
      expect(info1 == infoDiffLabel, isFalse);
      expect(info1 == infoDiffCode, isFalse);

      const infoNonPlay = AppUpdateInfo(
        updateAvailable: true,
        installedFromPlayStore: false,
        availableVersionLabel: '1.2.0',
        availableVersionCode: 12,
      );
      expect(info1 == infoNonPlay, isFalse);
      expect(infoNonPlay.installedFromPlayStore, isFalse);

      expect(info1.toString(), contains('1.2.0'));
      expect(info1.updateAvailable, isTrue);
      expect(info1.availableVersionCode, 12);
    });
  });

  group('AppUpdateFailure', () {
    test('subclasses instantiate with default and custom messages', () {
      const unavailable = AppUpdateStoreUnavailable();
      expect(unavailable.message, 'App store unavailable');
      expect(unavailable.toString(), contains('App store unavailable'));

      const userCancelled = AppUpdateUserCancelled();
      expect(userCancelled.toString(), contains('AppUpdateUserCancelled'));

      const failed = AppUpdateFailed('Native error');
      expect(failed.detail, 'Native error');
      expect(failed.toString(), contains('Native error'));
    });
  });
}
