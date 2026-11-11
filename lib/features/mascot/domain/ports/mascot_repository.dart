import 'dart:async';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';

/// Unit type compatible with `void` for results of operations returning no value.
typedef Unit = void;

/// Abstract repository port to load, save and observe mascot configuration (SPEC-012, RF-110).
abstract interface class MascotRepository {
  /// Loads active mascot configuration.
  ///
  /// If no configuration was previously persisted, returns
  /// [MascotConfig.defaultMomo] com sucesso (CA-110.1).
  Future<Result<MascotConfig, Failure>> loadConfig();

  /// Saves updated mascot configuration and notifies observers (CA-110.3).
  Future<Result<Unit, Failure>> saveConfig(MascotConfig config);

  /// Emits mascot configuration and any subsequent changes in real time.
  Stream<MascotConfig> watchConfig();
}
