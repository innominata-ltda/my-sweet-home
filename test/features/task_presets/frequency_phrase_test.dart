import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/task_presets/domain/recommended_frequency_phrase.dart';

void main() {
  const converter = RecommendedFrequencyPhrase();

  group('CA-1.5 & RN-353: RecommendedFrequencyPhrase', () {
    test('FREQ=DAILY;INTERVAL=7 vira "toda semana"', () {
      expect(converter.toPtBr('FREQ=DAILY;INTERVAL=7'), 'toda semana');
    });

    test('FREQ=DAILY;INTERVAL=1 vira "todo dia"', () {
      expect(converter.toPtBr('FREQ=DAILY;INTERVAL=1'), 'todo dia');
    });

    test('FREQ=DAILY;INTERVAL=3 vira "a cada 3 dias"', () {
      expect(converter.toPtBr('FREQ=DAILY;INTERVAL=3'), 'a cada 3 dias');
    });

    test('FREQ=DAILY;INTERVAL=14 vira "a cada 14 dias"', () {
      expect(converter.toPtBr('FREQ=DAILY;INTERVAL=14'), 'a cada 14 dias');
    });

    test('FREQ=DAILY;INTERVAL=30 vira "a cada 30 dias"', () {
      expect(converter.toPtBr('FREQ=DAILY;INTERVAL=30'), 'a cada 30 dias');
    });
  });

  group('CA-1.5: JSON catalog rationales without nagging tone', () {
    test('All seed rationales have welcoming tone and <= 120 characters', () {
      final file = File('assets/seed/task_presets.json');
      expect(file.existsSync(), isTrue);

      final jsonMap =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final presets = jsonMap['presets'] as List<dynamic>;

      final forbiddenGuiltWords = [
        'obrigatorio',
        'obrigatório',
        'preguiça',
        'preguica',
        'culpa',
        'vergonha',
        'desleixo',
        'você deve',
        'voce deve',
      ];

      for (final item in presets) {
        final p = item as Map<String, dynamic>;
        final rationale = p['rationale'] as String;

        expect(
          rationale.length,
          lessThanOrEqualTo(120),
          reason: 'Justificativa do preset ${p['id']} excede 120 caracteres',
        );

        final lower = rationale.toLowerCase();
        for (final word in forbiddenGuiltWords) {
          expect(
            lower.contains(word),
            isFalse,
            reason:
                'Justificativa do preset ${p['id']} contém palavra com tom de cobrança: "$word"',
          );
        }
      }
    });
  });
}
