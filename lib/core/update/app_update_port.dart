import 'package:my_sweet_home/core/result/result.dart';

/// Store version and update availability information.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateAvailable,
    this.installedFromPlayStore = true,
    this.availableVersionLabel,
    this.availableVersionCode,
  });

  /// Indicates whether a newer version is available in the official app store.
  final bool updateAvailable;

  /// Whether the app was installed from Google Play (`com.android.vending`).
  final bool installedFromPlayStore;

  /// Human-readable label of available version (e.g. "0.2.0"), if provided by store.
  final String? availableVersionLabel;

  /// Version code (versionCode) available in store, if provided.
  final int? availableVersionCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUpdateInfo &&
          runtimeType == other.runtimeType &&
          updateAvailable == other.updateAvailable &&
          installedFromPlayStore == other.installedFromPlayStore &&
          availableVersionLabel == other.availableVersionLabel &&
          availableVersionCode == other.availableVersionCode;

  @override
  int get hashCode => Object.hash(
    updateAvailable,
    installedFromPlayStore,
    availableVersionLabel,
    availableVersionCode,
  );

  @override
  String toString() =>
      'AppUpdateInfo(updateAvailable: $updateAvailable, installedFromPlayStore: $installedFromPlayStore, label: $availableVersionLabel, code: $availableVersionCode)';
}

/// Hierarchy of update verification or invocation failures.
sealed class AppUpdateFailure extends Failure {
  const AppUpdateFailure();
}

/// Store unavailable or device has no connection to the platform store.
final class AppUpdateStoreUnavailable extends AppUpdateFailure {
  const AppUpdateStoreUnavailable({this.message = 'App store unavailable'});

  final String message;

  @override
  String toString() => 'AppUpdateStoreUnavailable($message)';
}

/// User cancelled the interactive store update flow.
final class AppUpdateUserCancelled extends AppUpdateFailure {
  const AppUpdateUserCancelled();

  @override
  String toString() => 'AppUpdateUserCancelled()';
}

/// Generic failure checking or initiating the update flow.
final class AppUpdateFailed extends AppUpdateFailure {
  const AppUpdateFailed(this.detail);

  final String detail;

  @override
  String toString() => 'AppUpdateFailed($detail)';
}

/// Domain port for querying and triggering store updates (RN-040).
///
/// All queries must go through this port without opening raw HTTP connections
/// in Dart directly within the app (respecting RN-008 and RNF-005).
abstract class AppUpdatePort {
  /// Checks update availability in the platform store.
  Future<Result<AppUpdateInfo, AppUpdateFailure>> checkForUpdate();

  /// Triggers native store update flow (In-App Update or intent).
  Future<Result<void, AppUpdateFailure>> startUpdate();

  /// Opens an external `https://` URL using the host platform browser.
  Future<Result<void, AppUpdateFailure>> openExternalUrl(String url);
}
