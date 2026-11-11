import 'dart:async';

import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';

/// [MascotRepository] implementation persisted in `settings` table via Drift/SQLite (SPEC-012, RF-110).
class DriftMascotRepository implements MascotRepository {
  final AppDatabase db;
  final Clock clock;

  static const keyAnimal = 'mascot.animal';
  static const keyPalette = 'mascot.palette';
  static const keyAccessory = 'mascot.accessory';
  static const keyName = 'mascot.name';

  static const _mascotKeys = [keyAnimal, keyPalette, keyAccessory, keyName];

  DriftMascotRepository({required this.db, this.clock = const SystemClock()});

  @override
  Future<Result<MascotConfig, Failure>> loadConfig() async {
    try {
      final rows = await (db.select(
        db.settings,
      )..where((tbl) => tbl.key.isIn(_mascotKeys))).get();
      return Ok(_parseRows(rows));
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao carregar configurações da mascote: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<Unit, Failure>> saveConfig(MascotConfig config) async {
    try {
      final nowIso = clock.nowUtc().toIso8601String();
      final effectiveName = config.name.trim().isEmpty
          ? MascotConfig.defaultMomo.name
          : config.name.trim();
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.settings, [
          SettingsCompanion(
            key: const Value(keyAnimal),
            value: Value(config.animal.name),
            updatedAt: Value(nowIso),
          ),
          SettingsCompanion(
            key: const Value(keyPalette),
            value: Value(config.palette.name),
            updatedAt: Value(nowIso),
          ),
          SettingsCompanion(
            key: const Value(keyAccessory),
            value: Value(config.accessory.name),
            updatedAt: Value(nowIso),
          ),
          SettingsCompanion(
            key: const Value(keyName),
            value: Value(effectiveName),
            updatedAt: Value(nowIso),
          ),
        ]);
      });
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Falha ao persistir configurações da mascote: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Stream<MascotConfig> watchConfig() {
    return (db.select(db.settings)..where((tbl) => tbl.key.isIn(_mascotKeys)))
        .watch()
        .map(_parseRows)
        .distinct();
  }

  MascotConfig _parseRows(List<Setting> rows) {
    if (rows.isEmpty) {
      return MascotConfig.defaultMomo;
    }
    final map = {for (final row in rows) row.key: row.value};
    return MascotConfig(
      animal: MascotAnimal.parse(
        map[keyAnimal],
        fallback: MascotConfig.defaultMomo.animal,
      ),
      palette: MascotPalette.parse(
        map[keyPalette],
        fallback: MascotConfig.defaultMomo.palette,
      ),
      accessory: MascotAccessory.parse(
        map[keyAccessory],
        fallback: MascotConfig.defaultMomo.accessory,
      ),
      name: map[keyName]?.trim().isNotEmpty == true
          ? map[keyName]!.trim()
          : MascotConfig.defaultMomo.name,
    );
  }
}
