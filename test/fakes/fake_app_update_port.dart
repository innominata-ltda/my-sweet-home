import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';

/// Deterministic fake implementation of [AppUpdatePort] for tests (RN-040).
class FakeAppUpdatePort implements AppUpdatePort {
  FakeAppUpdatePort({
    this.updateAvailable = false,
    this.installedFromPlayStore = true,
    this.availableVersionLabel,
    this.availableVersionCode,
    this.failure,
    this.openExternalUrlFailure,
  });

  bool updateAvailable;
  bool installedFromPlayStore;
  String? availableVersionLabel;
  int? availableVersionCode;
  AppUpdateFailure? failure;
  AppUpdateFailure? openExternalUrlFailure;

  int checkForUpdateCallCount = 0;
  int startUpdateCallCount = 0;
  final List<String> openedUrls = [];

  @override
  Future<Result<AppUpdateInfo, AppUpdateFailure>> checkForUpdate() async {
    checkForUpdateCallCount++;
    if (failure != null) {
      return Err(failure!);
    }
    return Ok(
      AppUpdateInfo(
        updateAvailable: updateAvailable,
        installedFromPlayStore: installedFromPlayStore,
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

  @override
  Future<Result<void, AppUpdateFailure>> openExternalUrl(String url) async {
    openedUrls.add(url);
    if (openExternalUrlFailure != null) {
      return Err(openExternalUrlFailure!);
    }
    return const Ok(null);
  }
}
