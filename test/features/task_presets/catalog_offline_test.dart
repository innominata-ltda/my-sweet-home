import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/task_presets/data/asset_task_preset_catalog.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

class AirplaneModeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException(
      'Modo avião: nenhuma requisição de rede é permitida.',
    );
  }
}

class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = AirplaneModeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  test('CA-1.1 & RNF-005: Catalog loads offline without network with >= 25 items in 6 areas', () async {
    final catalogPort = AssetTaskPresetCatalog(bundle: FileAssetBundle());

    final result = await catalogPort.load();
    expect(result.isOk, isTrue);

    final catalog = result.valueOrNull!;
    expect(catalog.presets.length, greaterThanOrEqualTo(25));

    // Verify all 6 areas are represented
    final areas = catalog.presets.map((p) => p.area).toSet();
    expect(areas, contains(TaskPresetArea.kitchen));
    expect(areas, contains(TaskPresetArea.bathroom));
    expect(areas, contains(TaskPresetArea.bedroom));
    expect(areas, contains(TaskPresetArea.laundry));
    expect(areas, contains(TaskPresetArea.generalCleaning));
    expect(areas, contains(TaskPresetArea.shopping));
    expect(areas.length, 6);

    // Verify each item has frequency and rationale populated
    for (final preset in catalog.presets) {
      expect(preset.id.isNotEmpty, isTrue);
      expect(preset.title.isNotEmpty, isTrue);
      expect(preset.recommendedRrule.isNotEmpty, isTrue);
      expect(preset.rationale.isNotEmpty, isTrue);
      expect(preset.rationale.length, lessThanOrEqualTo(120));
    }
  });
}
