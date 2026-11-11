import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/drift_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot.dart';

import '../../../fakes/fake_clock.dart';

void main() {
  late AppDatabase db;
  late DriftMascotRepository repo;
  final fixedClock = FakeClock(DateTime.utc(2026, 10, 20, 12, 0, 0));

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftMascotRepository(db: db, clock: fixedClock);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftMascotRepository (RF-110, CA-110.1, CA-110.3)', () {
    test('CA-110.1: carga inicial em banco limpo devolve defaultMomo (gata Momo Rose)', () async {
      final result = await repo.loadConfig();

      expect(result.isOk, isTrue);
      final config = result.valueOrNull!;
      expect(config, equals(MascotConfig.defaultMomo));
      expect(config.animal, MascotAnimal.cat);
      expect(config.palette, MascotPalette.rose);
      expect(config.accessory, MascotAccessory.none);
      expect(config.name, 'Momo');
    });

    test(
      'CA-110.3: saveConfig persiste preferências e reflete no loadConfig',
      () async {
        const customConfig = MascotConfig(
          animal: MascotAnimal.bunny,
          palette: MascotPalette.mint,
          accessory: MascotAccessory.scarf,
          name: 'Luna',
        );

        final saveResult = await repo.saveConfig(customConfig);
        expect(saveResult.isOk, isTrue);

        final loadResult = await repo.loadConfig();
        expect(loadResult.isOk, isTrue);
        expect(loadResult.valueOrNull, equals(customConfig));

        // Verifica registros reais persistidos na tabela settings
        final rows = await db.select(db.settings).get();
        final map = {for (final r in rows) r.key: r.value};
        expect(map[DriftMascotRepository.keyAnimal], 'bunny');
        expect(map[DriftMascotRepository.keyPalette], 'mint');
        expect(map[DriftMascotRepository.keyAccessory], 'scarf');
        expect(map[DriftMascotRepository.keyName], 'Luna');
      },
    );

    test(
      'saveConfig normaliza nome em branco para defaultMomo no banco',
      () async {
        final configWithBlankName = MascotConfig.defaultMomo.copyWith(
          name: '   ',
        );
        final saveResult = await repo.saveConfig(configWithBlankName);
        expect(saveResult.isOk, isTrue);

        final row =
            await (db.select(db.settings)..where(
                  (tbl) => tbl.key.equals(DriftMascotRepository.keyName),
                ))
                .getSingle();
        expect(row.value, 'Momo');

        final loaded = await repo.loadConfig();
        expect(loaded.valueOrNull?.name, 'Momo');
      },
    );

    test('gracefully recovers with fallback when table fields are corrupted or partial', () async {
      // Inserting partial and invalid keys directly in settings table
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(
              key: DriftMascotRepository.keyAnimal,
              value: 'cachorro_invalido',
            ),
          );
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(
              key: DriftMascotRepository.keyName,
              value: '   ',
            ),
          );

      final result = await repo.loadConfig();
      expect(result.isOk, isTrue);
      final config = result.valueOrNull!;

      // Valores corrompidos/em branco caem para o default
      expect(config.animal, MascotAnimal.cat);
      expect(config.name, 'Momo');
      expect(config.palette, MascotPalette.rose);
      expect(config.accessory, MascotAccessory.none);
    });

    test('CA-110.3: watchConfig reacts in real time to updates', () async {
      final emitted = <MascotConfig>[];
      final subscription = repo.watchConfig().listen(emitted.add);

      // Await first emission
      await pumpEventQueue();
      expect(emitted, [MascotConfig.defaultMomo]);

      // Save first change
      const step1 = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.lavender,
        accessory: MascotAccessory.bow,
        name: 'Pipoca',
      );
      await repo.saveConfig(step1);
      await pumpEventQueue();

      // Save second change
      final step2 = step1.copyWith(name: 'Pipoca Dourada');
      await repo.saveConfig(step2);
      await pumpEventQueue();

      expect(emitted, [MascotConfig.defaultMomo, step1, step2]);

      await subscription.cancel();
    });

    test('returns Err(StorageFailure) when database fails', () async {
      await db.customStatement('DROP TABLE settings;');

      final loadResult = await repo.loadConfig();
      expect(loadResult.isErr, isTrue);
      expect(loadResult.failureOrNull, isA<StorageFailure>());

      final saveResult = await repo.saveConfig(MascotConfig.defaultMomo);
      expect(saveResult.isErr, isTrue);
      expect(saveResult.failureOrNull, isA<StorageFailure>());
    });
  });
}
