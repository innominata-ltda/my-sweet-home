library;

import 'dart:async';
import 'dart:isolate';

import 'background_runner_port.dart';

/// Adaptador real que executa tarefas em um Isolate separado do Dart (RN-424).
final class IsolateBackgroundRunnerAdapter implements BackgroundRunnerPort {
  const IsolateBackgroundRunnerAdapter();

  @override
  Future<R> run<R>(FutureOr<R> Function() task) {
    return Isolate.run(task);
  }
}
