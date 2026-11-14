import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/update/app_update_adapter.dart';
import 'package:my_sweet_home/core/update/app_update_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('br.com.innominata.mysweethome/app_update');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('checkForUpdate maps iOS non-Play-Store response cleanly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkForUpdate') {
            return <String, dynamic>{
              'updateAvailable': false,
              'installedFromPlayStore': false,
            };
          }
          return null;
        });

    const adapter = MethodChannelAppUpdateAdapter();
    final result = await adapter.checkForUpdate();

    expect(result.isOk, isTrue);
    final info = (result as Ok<AppUpdateInfo, AppUpdateFailure>).value;
    expect(info.updateAvailable, isFalse);
    expect(info.installedFromPlayStore, isFalse);
  });

  test('openExternalUrl forwards url argument to MethodChannel', () async {
    String? openedUrl;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'openExternalUrl') {
            openedUrl = (call.arguments as Map)['url'] as String?;
            return true;
          }
          return null;
        });

    const adapter = MethodChannelAppUpdateAdapter();
    final result = await adapter.openExternalUrl(
      'https://github.com/innominata-ltda/my-sweet-home',
    );

    expect(result.isOk, isTrue);
    expect(openedUrl, 'https://github.com/innominata-ltda/my-sweet-home');
  });
}
