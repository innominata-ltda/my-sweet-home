import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot.dart';

void main() {
  group('FakeMascotRepository', () {
    late FakeMascotRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeMascotRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('inicializa com defaultMomo e permite carregar', () async {
      final res = await fakeRepo.loadConfig();
      expect(res.isOk, isTrue);
      expect(res.valueOrNull, equals(MascotConfig.defaultMomo));
    });

    test('allows customizing initial configuration in constructor', () async {
      final customFake = FakeMascotRepository(
        initialConfig: const MascotConfig(
          animal: MascotAnimal.dog,
          palette: MascotPalette.lavender,
          accessory: MascotAccessory.collar,
          name: 'Rex',
        ),
      );
      final res = await customFake.loadConfig();
      expect(res.valueOrNull?.name, 'Rex');
      customFake.dispose();
    });

    test('saveConfig updates in-memory state', () async {
      const newConfig = MascotConfig(
        animal: MascotAnimal.bunny,
        palette: MascotPalette.mint,
        accessory: MascotAccessory.bow,
        name: 'Florzinha',
      );

      final saveRes = await fakeRepo.saveConfig(newConfig);
      expect(saveRes.isOk, isTrue);

      final loadRes = await fakeRepo.loadConfig();
      expect(loadRes.valueOrNull, equals(newConfig));
    });

    test('watchConfig emits current value and subsequent changes', () async {
      final emitted = <MascotConfig>[];
      final sub = fakeRepo.watchConfig().listen(emitted.add);

      await pumpEventQueue();

      const updated = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.rose,
        accessory: MascotAccessory.none,
        name: 'Bidu',
      );
      await fakeRepo.saveConfig(updated);
      await pumpEventQueue();

      expect(emitted, [MascotConfig.defaultMomo, updated]);

      await sub.cancel();
    });

    test(
      'simulates configurable failure in loadConfig and saveConfig',
      () async {
        fakeRepo.shouldFail = true;

        final loadRes = await fakeRepo.loadConfig();
        expect(loadRes.isErr, isTrue);
        expect(loadRes.failureOrNull, isA<StorageFailure>());

        final saveRes = await fakeRepo.saveConfig(MascotConfig.defaultMomo);
        expect(saveRes.isErr, isTrue);
        expect(saveRes.failureOrNull, isA<StorageFailure>());
      },
    );

    test('watchConfig deduplicates consecutive identical emissions', () async {
      final emitted = <MascotConfig>[];
      final sub = fakeRepo.watchConfig().listen(emitted.add);

      await pumpEventQueue();

      // Saves same current configuration
      await fakeRepo.saveConfig(MascotConfig.defaultMomo);
      await pumpEventQueue();

      expect(emitted, [MascotConfig.defaultMomo]);

      await sub.cancel();
    });

    test('saveConfig after dispose does not throw exception', () async {
      final repo = FakeMascotRepository();
      repo.dispose();

      expect(
        () async => await repo.saveConfig(
          MascotConfig.defaultMomo.copyWith(name: 'Após dispose'),
        ),
        returnsNormally,
      );
    });

    test('saveConfig normaliza nome em branco no fake', () async {
      await fakeRepo.saveConfig(MascotConfig.defaultMomo.copyWith(name: '   '));
      final res = await fakeRepo.loadConfig();
      expect(res.valueOrNull?.name, 'Momo');
    });
  });
}
