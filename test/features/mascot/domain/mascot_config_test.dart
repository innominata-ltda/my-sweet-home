import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot.dart';

void main() {
  group('MascotConfig & Enums (RF-110, RN-258..RN-262, RN-266)', () {
    test(
      'CA-110.1: primeiro acesso carrega padrão gata Momo Rose sem acessório',
      () {
        const defaultMomo = MascotConfig.defaultMomo;

        expect(defaultMomo.animal, MascotAnimal.cat);
        expect(defaultMomo.palette, MascotPalette.rose);
        expect(defaultMomo.accessory, MascotAccessory.none);
        expect(defaultMomo.name, 'Momo');
      },
    );

    test('aliases Mascot and MascotType are equivalent', () {
      const Mascot mascot = MascotConfig.defaultMomo;
      const MascotType type = MascotAnimal.cat;

      expect(mascot.animal, type);
    });

    test('copyWith altera apenas os campos especificados', () {
      const original = MascotConfig.defaultMomo;
      final updated = original.copyWith(
        animal: MascotAnimal.dog,
        name: 'Pipoca',
      );

      expect(updated.animal, MascotAnimal.dog);
      expect(updated.palette, MascotPalette.rose);
      expect(updated.accessory, MascotAccessory.none);
      expect(updated.name, 'Pipoca');
    });

    test('toJson e fromJson serializam e desserializam com integridade', () {
      const config = MascotConfig(
        animal: MascotAnimal.bunny,
        palette: MascotPalette.mint,
        accessory: MascotAccessory.scarf,
        name: 'Luna',
      );

      final json = config.toJson();
      expect(json, {
        'animal': 'bunny',
        'palette': 'mint',
        'accessory': 'scarf',
        'name': 'Luna',
      });

      final reconstructed = MascotConfig.fromJson(json);
      expect(reconstructed, equals(config));
    });

    test('fromJson applies fallback for missing or invalid fields', () {
      final fallback = MascotConfig.fromJson({
        'animal': 'unknown_dragon',
        'palette': 'neon_cyan',
        'accessory': 'hat',
        'name': '   ',
      });

      expect(fallback.animal, MascotAnimal.cat);
      expect(fallback.palette, MascotPalette.rose);
      expect(fallback.accessory, MascotAccessory.none);
      expect(fallback.name, 'Momo');
    });

    test('igualdade e hashCode respeitam todos os atributos', () {
      const c1 = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.lavender,
        accessory: MascotAccessory.bow,
        name: 'Bob',
      );
      const c2 = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.lavender,
        accessory: MascotAccessory.bow,
        name: 'Bob',
      );
      const c3 = MascotConfig(
        animal: MascotAnimal.dog,
        palette: MascotPalette.lavender,
        accessory: MascotAccessory.collar,
        name: 'Bob',
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
      expect(c1.toString(), contains('Bob'));
    });

    group('MascotAnimal', () {
      test('suporta os 3 animais da v1 (RN-259)', () {
        expect(MascotAnimal.values, [
          MascotAnimal.cat,
          MascotAnimal.dog,
          MascotAnimal.bunny,
        ]);
        expect(MascotAnimal.cat.label, 'Gato');
        expect(MascotAnimal.dog.label, 'Cachorro');
        expect(MascotAnimal.bunny.label, 'Coelho');
      });

      test('parse is case-insensitive and applies fallback', () {
        expect(MascotAnimal.parse('DOG'), MascotAnimal.dog);
        expect(MascotAnimal.parse('Bunny'), MascotAnimal.bunny);
        expect(MascotAnimal.parse('invalid'), MascotAnimal.cat);
        expect(MascotAnimal.parse(null), MascotAnimal.cat);
      });
    });

    group('MascotExpression', () {
      test('supports 10 required expressions (RN-260)', () {
        expect(MascotExpression.values.length, 10);
        expect(MascotExpression.values, contains(MascotExpression.neutral));
        expect(MascotExpression.values, contains(MascotExpression.happy));
        expect(MascotExpression.values, contains(MascotExpression.worried));
        expect(MascotExpression.values, contains(MascotExpression.sleepy));
        expect(MascotExpression.values, contains(MascotExpression.pointing));
        expect(MascotExpression.values, contains(MascotExpression.waving));
        expect(MascotExpression.values, contains(MascotExpression.thinking));
        expect(MascotExpression.values, contains(MascotExpression.relaxed));
        expect(MascotExpression.values, contains(MascotExpression.shopping));
        expect(MascotExpression.values, contains(MascotExpression.budget));
      });

      test('parse is case-insensitive and applies fallback', () {
        expect(MascotExpression.parse('HAPPY'), MascotExpression.happy);
        expect(MascotExpression.parse('pointing'), MascotExpression.pointing);
        expect(MascotExpression.parse(null), MascotExpression.neutral);
        expect(MascotExpression.parse('xyz'), MascotExpression.neutral);
      });

      test('defaultSemanticDescription gera textos contextuais em pt-BR (RN-289, A11Y-3)', () {
        for (final exp in MascotExpression.values) {
          final desc = exp.defaultSemanticDescription('Momo');
          expect(desc, contains('Momo'));
          expect(desc.isNotEmpty, isTrue);
          expect(desc, isNot(contains('desenho')));
          expect(desc, isNot(contains('imagem')));
        }
      });
    });

    group('MascotAccessory', () {
      test('supports 4 required accessories (RN-261)', () {
        expect(MascotAccessory.values, [
          MascotAccessory.none,
          MascotAccessory.bow,
          MascotAccessory.collar,
          MascotAccessory.scarf,
        ]);
        expect(MascotAccessory.none.label, 'Nenhum');
        expect(MascotAccessory.bow.label, 'Lacinho');
        expect(MascotAccessory.collar.label, 'Coleira');
        expect(MascotAccessory.scarf.label, 'Lenço');
      });

      test('parse is case-insensitive and applies fallback', () {
        expect(MascotAccessory.parse('BOW'), MascotAccessory.bow);
        expect(MascotAccessory.parse('collar'), MascotAccessory.collar);
        expect(MascotAccessory.parse(null), MascotAccessory.none);
        expect(MascotAccessory.parse('xyz'), MascotAccessory.none);
      });
    });

    group('MascotPalette', () {
      test('suporta as 3 paletas requeridas (RN-266)', () {
        expect(MascotPalette.values, [
          MascotPalette.rose,
          MascotPalette.lavender,
          MascotPalette.mint,
        ]);
        expect(MascotPalette.rose.label, 'Rose');
        expect(MascotPalette.lavender.label, 'Lavender');
        expect(MascotPalette.mint.label, 'Mint');
      });

      test('parse is case-insensitive and applies fallback', () {
        expect(MascotPalette.parse('ROSE'), MascotPalette.rose);
        expect(MascotPalette.parse('mint'), MascotPalette.mint);
        expect(MascotPalette.parse(null), MascotPalette.rose);
        expect(MascotPalette.parse('xyz'), MascotPalette.rose);
      });

      test('parse tolerates spaces and accepts portuguese labels', () {
        expect(MascotPalette.parse('  Lavender  '), MascotPalette.lavender);
        expect(MascotPalette.parse('rose'), MascotPalette.rose);
        expect(MascotPalette.parse('Mint'), MascotPalette.mint);
      });
    });

    test(
      'displayName guarantees safe fallback when name is empty or whitespace',
      () {
        const c1 = MascotConfig(
          animal: MascotAnimal.cat,
          palette: MascotPalette.rose,
          accessory: MascotAccessory.none,
          name: '   ',
        );
        expect(c1.displayName, 'Momo');

        const c2 = MascotConfig(
          animal: MascotAnimal.cat,
          palette: MascotPalette.rose,
          accessory: MascotAccessory.none,
          name: '  Amora  ',
        );
        expect(c2.displayName, 'Amora');
      },
    );

    test('fromJson processes non-string values without throwing TypeError', () {
      final config = MascotConfig.fromJson({
        'animal': 123,
        'palette': true,
        'accessory': null,
        'name': 456,
      });

      expect(config.animal, MascotAnimal.cat);
      expect(config.palette, MascotPalette.rose);
      expect(config.accessory, MascotAccessory.none);
      expect(config.name, '456');
    });

    test(
      'defaultSemanticDescription aplica fallback para Momo se nome for vazio',
      () {
        final desc = MascotExpression.happy.defaultSemanticDescription('   ');
        expect(desc, contains('Momo'));
        expect(desc, startsWith('Momo'));
      },
    );

    test('MascotAnimal.parse accepts pt-BR labels and tolerates spaces', () {
      expect(MascotAnimal.parse('  Gato  '), MascotAnimal.cat);
      expect(MascotAnimal.parse('Cachorro'), MascotAnimal.dog);
      expect(MascotAnimal.parse('coelho'), MascotAnimal.bunny);
      expect(MascotAnimal.parse('   '), MascotAnimal.cat);
    });

    test(
      'MascotAccessory.parse aceita labels pt-BR e tolera lenco sem cedilha',
      () {
        expect(MascotAccessory.parse('  Lacinho  '), MascotAccessory.bow);
        expect(MascotAccessory.parse('Coleira'), MascotAccessory.collar);
        expect(MascotAccessory.parse('lenco'), MascotAccessory.scarf);
        expect(MascotAccessory.parse('lenço'), MascotAccessory.scarf);
      },
    );
  });
}
