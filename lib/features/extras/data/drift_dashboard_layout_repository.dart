import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout.dart';
import 'package:my_sweet_home/features/extras/domain/dashboard_layout_repository.dart';

/// Drift implementation of Dashboard layout persistence using transversal `settings` table (RN-375).
class DriftDashboardLayoutRepository implements DashboardLayoutRepository {
  DriftDashboardLayoutRepository(this._db);

  final AppDatabase _db;

  /// Canonical persistence key in settings table (RN-375).
  static const String settingsKey = 'dashboard_layout_v1';

  @override
  Future<Result<DashboardLayoutConfig, Failure>> load() async {
    try {
      final setting = await (_db.select(
        _db.settings,
      )..where((tbl) => tbl.key.equals(settingsKey))).getSingleOrNull();

      if (setting == null || setting.value.trim().isEmpty) {
        return const Ok(
          DashboardLayoutConfig(
            visibleItems: DashboardLayoutConfig.defaultOrder,
          ),
        );
      }

      try {
        final decoded = jsonDecode(setting.value);
        if (decoded is! List) {
          return const Ok(
            DashboardLayoutConfig(
              visibleItems: DashboardLayoutConfig.defaultOrder,
            ),
          );
        }
        final config = DashboardLayoutConfig.fromJson(decoded);
        return Ok(config);
      } on FormatException {
        // Fallback para defaultOrder se JSON corrompido (RN-375).
        return const Ok(
          DashboardLayoutConfig(
            visibleItems: DashboardLayoutConfig.defaultOrder,
          ),
        );
      }
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao carregar layout do dashboard: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<DashboardLayoutConfig, Failure>> save(
    DashboardLayoutConfig config,
  ) async {
    try {
      final jsonStr = jsonEncode(config.toJson());
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion(
              key: const Value(settingsKey),
              value: Value(jsonStr),
            ),
          );
      return Ok(config);
    } catch (e) {
      return Err(
        StorageFailure(
          detail: 'Erro ao salvar layout do dashboard: $e',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<DashboardLayoutConfig, Failure>> resetToDefault() async {
    const defaultConfig = DashboardLayoutConfig(
      visibleItems: DashboardLayoutConfig.defaultOrder,
    );
    return save(defaultConfig);
  }
}
