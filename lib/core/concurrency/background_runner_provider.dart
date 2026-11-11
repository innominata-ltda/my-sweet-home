library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_runner_port.dart';
import 'isolate_background_runner_adapter.dart';

final backgroundRunnerProvider = Provider<BackgroundRunnerPort>((ref) {
  return const IsolateBackgroundRunnerAdapter();
});
