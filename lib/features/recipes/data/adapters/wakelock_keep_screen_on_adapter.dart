import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/ports/keep_screen_on_port.dart';

class WakelockKeepScreenOnAdapter implements KeepScreenOnPort {
  @override
  Future<void> enable() async {
    await WakelockPlus.enable();
  }

  @override
  Future<void> disable() async {
    await WakelockPlus.disable();
  }
}
