library;

import 'dart:async';

import 'package:my_sweet_home/core/concurrency/background_runner_port.dart';

/// Fake for tests that records [BackgroundRunnerPort] invocations and executes inline.
final class RecordingBackgroundRunner implements BackgroundRunnerPort {
  int runCount = 0;
  final List<String> labels = [];

  @override
  Future<R> run<R>(FutureOr<R> Function() task) async {
    runCount++;
    return await task();
  }
}
