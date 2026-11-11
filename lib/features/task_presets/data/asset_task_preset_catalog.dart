import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/task_presets/domain/ports/task_preset_catalog_port.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';

/// Implementation of [TaskPresetCatalogPort] reading local catalog from `assets/seed/task_presets.json`.
/// Makes no network calls (RNF-005, CA-1.1).
class AssetTaskPresetCatalog implements TaskPresetCatalogPort {
  final AssetBundle _bundle;
  final String _assetPath;

  AssetTaskPresetCatalog({
    AssetBundle? bundle,
    this._assetPath = 'assets/seed/task_presets.json',
  }) : _bundle = bundle ?? rootBundle;

  @override
  Future<Result<TaskPresetCatalog, Failure>> load() async {
    try {
      String jsonString;
      try {
        final file = File(_assetPath);
        if (file.existsSync()) {
          jsonString = file.readAsStringSync();
        } else {
          jsonString = await _bundle.loadString(_assetPath);
        }
      } catch (_) {
        jsonString = await _bundle.loadString(_assetPath);
      }
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final catalog = TaskPresetCatalog.fromJson(jsonMap);
      return Ok(catalog);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao carregar catálogo de predefinições: $e',
          cause: e,
        ),
      );
    }
  }
}
