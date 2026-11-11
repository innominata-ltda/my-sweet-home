import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/ports/keep_screen_on_port.dart';
import 'wakelock_keep_screen_on_adapter.dart';

part 'keep_screen_on_provider.g.dart';

@riverpod
KeepScreenOnPort keepScreenOn(Ref ref) {
  return WakelockKeepScreenOnAdapter();
}
