import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

/// Port for loading task presets catalog on demand.
/// Never makes HTTP requests (RNF-005, CA-1.1).
abstract interface class TaskPresetCatalogPort {
  Future<Result<TaskPresetCatalog, Failure>> load();
}
