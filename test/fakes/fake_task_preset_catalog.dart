import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

/// In-memory fake of [TaskPresetCatalogPort] for tests.
class FakeTaskPresetCatalog implements TaskPresetCatalogPort {
  TaskPresetCatalog? catalog;
  bool shouldFail;

  FakeTaskPresetCatalog({this.catalog, this.shouldFail = false});

  factory FakeTaskPresetCatalog.failing() {
    return FakeTaskPresetCatalog(shouldFail: true);
  }

  factory FakeTaskPresetCatalog.defaultFixture({
    int version = 1,
    List<TaskPreset>? presets,
  }) {
    return FakeTaskPresetCatalog(
      catalog: TaskPresetCatalog(
        version: version,
        presets: presets ?? _defaultPresets,
      ),
    );
  }

  @override
  Future<Result<TaskPresetCatalog, Failure>> load() async {
    if (shouldFail) {
      return const Err(StorageFailure(detail: 'Fake catalog failure'));
    }
    return Ok(
      catalog ?? TaskPresetCatalog(version: 1, presets: _defaultPresets),
    );
  }

  static const List<TaskPreset> _defaultPresets = [
    TaskPreset(
      id: 'sweep-floor',
      area: TaskPresetArea.generalCleaning,
      title: 'Varrer o chão',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=3',
      rationale: 'Poeira e cabelo se espalham rápido.',
    ),
    TaskPreset(
      id: 'wash-clothes',
      area: TaskPresetArea.laundry,
      title: 'Lavar roupa',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
      rationale: 'Evita acúmulo e falta de roupa limpa.',
    ),
    TaskPreset(
      id: 'wash-dishes',
      area: TaskPresetArea.kitchen,
      title: 'Lavar louça',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=1',
      rationale: 'Louça parada atrai insetos e fica mais difícil de limpar.',
    ),
    TaskPreset(
      id: 'clean-stove',
      area: TaskPresetArea.kitchen,
      title: 'Limpar fogão',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
      rationale: 'Gordura acumulada endurece e vira risco de fogo.',
    ),
  ];
}
