import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/mascot/data/mascot_repository_provider.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/drift_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/fake_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_controller.dart';
import 'package:my_sweet_home/features/mascot/presentation/controllers/mascot_customization_state.dart';

void main() {
  group('Mascot Persistence & Reactive Stream (CA-110.3, RF-110, RN-264)', () {
    late AppDatabase db;
    late Clock clock;
    late DriftMascotRepository repository;
    late ProviderContainer container;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase.memory();
      clock = const SystemClock();
      repository = DriftMascotRepository(db: db, clock: clock);
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          mascotRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('CA-110.1: First access without saved data loads default Momo Rose config', () async {
      final result = await repository.loadConfig();
      expect(result.isOk, isTrue);
      final config = (result as Ok<MascotConfig, Failure>).value;
      expect(config, equals(MascotConfig.defaultMomo));
      expect(config.animal, equals(MascotAnimal.cat));
      expect(config.palette, equals(MascotPalette.rose));
      expect(config.accessory, equals(MascotAccessory.none));
      expect(config.name, equals('Momo'));
    });

    test('CA-110.3: Saving new customization (rabbit, Mint, scarf, "Luna") persists in db and emits on stream immediately', () async {
      final streamHistory = <MascotConfig>[];
      final subscription = repository.watchConfig().listen(streamHistory.add);

      // Await initial emission
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(streamHistory, isNotEmpty);
      expect(streamHistory.first, equals(MascotConfig.defaultMomo));

      // Save new configuration
      const newConfig = MascotConfig(
        animal: MascotAnimal.bunny,
        palette: MascotPalette.mint,
        accessory: MascotAccessory.scarf,
        name: 'Luna',
      );

      final saveResult = await repository.saveConfig(newConfig);
      expect(saveResult.isOk, isTrue);

      // Await reactive stream notification
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(streamHistory.length, greaterThanOrEqualTo(2));
      final latest = streamHistory.last;
      expect(latest.animal, equals(MascotAnimal.bunny));
      expect(latest.palette, equals(MascotPalette.mint));
      expect(latest.accessory, equals(MascotAccessory.scarf));
      expect(latest.name, equals('Luna'));

      // Verify subsequent load reflects persistence
      final loaded = await repository.loadConfig();
      expect(loaded.isOk, isTrue);
      expect((loaded as Ok<MascotConfig, Failure>).value, equals(newConfig));

      await subscription.cancel();
    });

    test('CA-110.3: Riverpod mascotConfigStreamProvider emits new configuration reactively', () async {
      final emittedConfigs = <MascotConfig>[];
      final subscription = container.listen<AsyncValue<MascotConfig>>(
        mascotConfigStreamProvider,
        (previous, next) {
          next.whenData(emittedConfigs.add);
        },
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      const updatedConfig = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.lavender,
        accessory: MascotAccessory.bow,
        name: 'Pipoca',
      );

      final saveResult = await repository.saveConfig(updatedConfig);
      expect(saveResult.isOk, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedConfigs.last, equals(updatedConfig));
      subscription.close();
    });

    test(
      'Saving empty or whitespace-only name applies fallback to "Momo"',
      () async {
        const configWithBlankName = MascotConfig(
          animal: MascotAnimal.cat,
          palette: MascotPalette.rose,
          accessory: MascotAccessory.collar,
          name: '   ',
        );

        final saveResult = await repository.saveConfig(configWithBlankName);
        expect(saveResult.isOk, isTrue);

        final loadResult = await repository.loadConfig();
        expect(loadResult.isOk, isTrue);
        final loaded = (loadResult as Ok<MascotConfig, Failure>).value;
        expect(loaded.name, equals('Momo'));
        expect(loaded.displayName, equals('Momo'));
      },
    );

    test('MascotCustomizationController persists via repository and notifies observers', () async {
      final controller = MascotCustomizationController(repository: repository);
      // Aguarda carregamento inicial
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(controller.value, isA<MascotCustomizationData>());
      expect(controller.state, equals(MascotConfig.defaultMomo));

      controller.selectAnimal(MascotAnimal.dog);
      controller.selectPalette(MascotPalette.lavender);
      controller.selectAccessory(MascotAccessory.collar);
      controller.updateName('Bob');

      expect(controller.state.animal, equals(MascotAnimal.dog));
      expect(controller.state.palette, equals(MascotPalette.lavender));
      expect(controller.state.accessory, equals(MascotAccessory.collar));
      expect(controller.state.name, equals('Bob'));

      final saveResult = await controller.save();
      expect(saveResult.isOk, isTrue);

      final loaded = await repository.loadConfig();
      expect(loaded.isOk, isTrue);
      final config = (loaded as Ok<MascotConfig, Failure>).value;
      expect(config.animal, equals(MascotAnimal.dog));
      expect(config.palette, equals(MascotPalette.lavender));
      expect(config.accessory, equals(MascotAccessory.collar));
      expect(config.name, equals('Bob'));

      controller.dispose();
    });

    test('MascotCustomizationController handles persistence failure gracefully without crashing', () async {
      final fakeRepo = FakeMascotRepository();
      fakeRepo.shouldFail = true;

      final controller = MascotCustomizationController(
        repository: fakeRepo,
        initialConfig: MascotConfig.defaultMomo,
      );

      controller.selectAnimal(MascotAnimal.bunny);
      final saveResult = await controller.save();

      expect(saveResult.isErr, isTrue);
      expect(controller.value, isA<MascotCustomizationData>());
      final data = controller.value as MascotCustomizationData;
      expect(data.errorMessage, isNotNull);
      expect(data.isSaving, isFalse);

      fakeRepo.dispose();
      controller.dispose();
    });
  });
}
