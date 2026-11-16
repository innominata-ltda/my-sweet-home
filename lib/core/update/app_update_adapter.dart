import 'package:flutter/services.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';

/// Native [AppUpdatePort] adapter communicating via [MethodChannel]
/// with the official platform store (Google Play In-App Updates / intent).
class MethodChannelAppUpdateAdapter implements AppUpdatePort {
  const MethodChannelAppUpdateAdapter({
    this.channel = const MethodChannel(
      'br.com.innominata.mysweethome/app_update',
    ),
  });

  final MethodChannel channel;

  @override
  Future<Result<AppUpdateInfo, AppUpdateFailure>> checkForUpdate() async {
    try {
      final res = await channel.invokeMapMethod<String, dynamic>(
        'checkForUpdate',
      );
      if (res == null) {
        return const Err(
          AppUpdateStoreUnavailable(message: 'Empty store response'),
        );
      }

      final updateAvailable = res['updateAvailable'] as bool? ?? false;
      final installedFromPlayStore =
          res['installedFromPlayStore'] as bool? ?? true;
      final availableVersionLabel = res['availableVersionLabel'] as String?;
      final availableVersionCode = res['availableVersionCode'] as int?;

      return Ok(
        AppUpdateInfo(
          updateAvailable: updateAvailable,
          installedFromPlayStore: installedFromPlayStore,
          availableVersionLabel: availableVersionLabel,
          availableVersionCode: availableVersionCode,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'STORE_UNAVAILABLE' || e.code == 'UNAVAILABLE') {
        return Err(
          AppUpdateStoreUnavailable(
            message: e.message ?? 'App store unavailable',
          ),
        );
      }
      return Err(AppUpdateFailed(e.message ?? 'Failed to query store'));
    } catch (e) {
      return Err(AppUpdateFailed(e.toString()));
    }
  }

  @override
  Future<Result<void, AppUpdateFailure>> startUpdate() async {
    try {
      await channel.invokeMethod<void>('startUpdate');
      return const Ok(null);
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        return const Err(AppUpdateUserCancelled());
      }
      if (e.code == 'STORE_UNAVAILABLE' || e.code == 'UNAVAILABLE') {
        return Err(
          AppUpdateStoreUnavailable(
            message: e.message ?? 'App store unavailable',
          ),
        );
      }
      return Err(AppUpdateFailed(e.message ?? 'Failed to start update'));
    } catch (e) {
      return Err(AppUpdateFailed(e.toString()));
    }
  }

  @override
  Future<Result<void, AppUpdateFailure>> openExternalUrl(String url) async {
    try {
      await channel.invokeMethod<void>('openExternalUrl', {'url': url});
      return const Ok(null);
    } on PlatformException catch (e) {
      return Err(AppUpdateFailed(e.message ?? 'Failed to open URL'));
    } catch (e) {
      return Err(AppUpdateFailed(e.toString()));
    }
  }
}
