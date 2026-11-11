import 'dart:async';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';

/// Deterministic in-memory fake of [MascotRepository] for unit and integration tests.
class FakeMascotRepository implements MascotRepository {
  MascotConfig _config;
  final StreamController<MascotConfig> _controller =
      StreamController<MascotConfig>.broadcast();

  bool shouldFail = false;
  Failure? failure;

  FakeMascotRepository({MascotConfig initialConfig = MascotConfig.defaultMomo})
    : _config = initialConfig;

  @override
  Future<Result<MascotConfig, Failure>> loadConfig() async {
    if (shouldFail) {
      return Err(
        failure ??
            const StorageFailure(detail: 'Simulated load failure in fake'),
      );
    }
    return Ok(_config);
  }

  @override
  Future<Result<Unit, Failure>> saveConfig(MascotConfig config) async {
    if (shouldFail) {
      return Err(
        failure ??
            const StorageFailure(detail: 'Simulated save failure in fake'),
      );
    }
    final effectiveName = config.name.trim().isEmpty
        ? MascotConfig.defaultMomo.name
        : config.name.trim();
    final sanitizedConfig = config.copyWith(name: effectiveName);
    final changed = _config != sanitizedConfig;
    _config = sanitizedConfig;
    if (changed && !_controller.isClosed) {
      _controller.add(sanitizedConfig);
    }
    return const Ok(null);
  }

  @override
  Stream<MascotConfig> watchConfig() {
    return _watchStream().distinct();
  }

  Stream<MascotConfig> _watchStream() async* {
    yield _config;
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
