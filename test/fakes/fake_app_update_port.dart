import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';

/// Deterministic fake implementation of [AppUpdatePort] for tests (RN-040).
class FakeAppUpdatePort implements AppUpdatePort {
  FakeAppUpdatePort({
    this.updateAvailable = false,
    this.availableVersionLabel,
    this.availableVersionCode,
    this.failure,
  });

  bool updateAvailable;
  String? availableVersionLabel;
  int? availableVersionCode;
  AppUpdateFailure? failure;

  int checkForUpdateCallCount = 0;
  int startUpdateCallCount = 0;

  @override
  Future<Result<AppUpdateInfo, AppUpdateFailure>> checkForUpdate() async {
    checkForUpdateCallCount++;
    if (failure != null) {
      return Err(failure!);
    }
    return Ok(
      AppUpdateInfo(
        updateAvailable: updateAvailable,
        availableVersionLabel: availableVersionLabel,
        availableVersionCode: availableVersionCode,
      ),
    );
  }

  @override
  Future<Result<void, AppUpdateFailure>> startUpdate() async {
    startUpdateCallCount++;
    if (failure != null) {
      return Err(failure!);
    }
    return const Ok(null);
  }
}
