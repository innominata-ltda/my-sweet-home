import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/features/task_presets/data/asset_task_preset_catalog.dart';
import 'package:my_sweet_home/features/task_presets/data/drift_task_from_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_from_preset_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';

final taskPresetCatalogProvider = Provider<TaskPresetCatalogPort>((ref) {
  return AssetTaskPresetCatalog();
});

final taskFromPresetPortProvider = Provider<TaskFromPresetPort>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final idGen = ref.watch(idGeneratorProvider);
  return DriftTaskFromPreset(
    db: db,
    clock: clock,
    idGenerator: idGen,
    trashPolicy: DriftTrashPolicy.system(db: db),
  );
});
