import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/bills/data/adapters/exact_alarm_notice_storage_adapter.dart';
import 'package:my_sweet_home/features/bills/domain/exact_alarm_notice_service.dart';

import '../../fakes/fake_clock.dart';
import '../../fakes/fake_exact_alarm_permission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExactAlarmNoticeService (RN-423, CA-4.5)', () {
    late AppDatabase db;
    late FakeClock clock;
    late ExactAlarmNoticeStorageAdapter storage;
    final now = DateTime.utc(2026, 1, 1, 10, 0);

    setUp(() {
      db = AppDatabase.memory();
      clock = FakeClock(now);
      storage = ExactAlarmNoticeStorageAdapter(db, clock);
    });

    tearDown(() async {
      await db.close();
    });

    test('CA-4.5: shouldShowNotice() returns true once when exact alarm permission is missing, and false subsequently', () async {
      final permission = FakeExactAlarmPermission(false);
      final service = ExactAlarmNoticeService(
        permission: permission,
        storage: storage,
      );

      // 1ª vez: deve exibir o aviso
      final firstCall = await service.shouldShowNotice();
      expect(firstCall, isTrue);

      // 2nd time: should not display warning again (only once)
      final secondCall = await service.shouldShowNotice();
      expect(secondCall, isFalse);
    });

    test('shouldShowNotice() returns false if exact alarm permission is already granted', () async {
      final permission = FakeExactAlarmPermission(true);
      final service = ExactAlarmNoticeService(
        permission: permission,
        storage: storage,
      );

      final shouldShow = await service.shouldShowNotice();
      expect(shouldShow, isFalse);
    });

    test('openSettings() delega para a porta de permissao', () async {
      final permission = FakeExactAlarmPermission(false);
      final service = ExactAlarmNoticeService(
        permission: permission,
        storage: storage,
      );

      await service.openSettings();
      expect(permission.openSettingsCalls, 1);
    });
  });
}
