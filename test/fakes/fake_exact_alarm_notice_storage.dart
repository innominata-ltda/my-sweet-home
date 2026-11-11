import 'package:my_sweet_home/features/bills/domain/exact_alarm_notice_service.dart';

/// Fake de [ExactAlarmNoticeStoragePort] para testes (RN-423, CA-4.5).
class FakeExactAlarmNoticeStorage implements ExactAlarmNoticeStoragePort {
  bool seen;

  FakeExactAlarmNoticeStorage({this.seen = false});

  @override
  Future<bool> hasSeenNotice() async => seen;

  @override
  Future<void> markNoticeAsSeen() async {
    seen = true;
  }
}
