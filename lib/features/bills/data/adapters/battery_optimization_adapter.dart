import 'dart:io';

import 'package:flutter/services.dart';
import 'package:my_sweet_home/features/bills/domain/battery_warning/battery_optimization_port.dart';

class BatteryOptimizationAdapter implements BatteryOptimizationPort {
  static const _channel = MethodChannel(
    'br.com.innominata.mysweethome/battery',
  );

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      // Failure opening settings, silently ignored
    }
  }
}
