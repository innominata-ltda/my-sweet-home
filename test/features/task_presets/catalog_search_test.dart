import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset.dart';
import 'package:my_sweet_home/features/task_presets/domain/task_preset_search.dart';

void main() {
  const search = TaskPresetSearch();

  final presets = [
    const TaskPreset(
      id: 'wash-dishes',
      area: TaskPresetArea.kitchen,
      title: 'Lavar louça',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=1',
      rationale: 'Louça parada atrai insetos.',
    ),
    const TaskPreset(
      id: 'clean-stove',
      area: TaskPresetArea.kitchen,
      title: 'Limpar fogão',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
      rationale: 'Gordura acumulada endurece.',
    ),
    const TaskPreset(
      id: 'clean-toilet',
      area: TaskPresetArea.bathroom,
      title: 'Limpar vaso sanitário e pia',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
      rationale: 'Higiene básica.',
    ),
    const TaskPreset(
      id: 'wash-clothes',
      area: TaskPresetArea.laundry,
      title: 'Lavar roupa',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=7',
      rationale: 'Evita acúmulo de roupa.',
    ),
    const TaskPreset(
      id: 'sweep-floor',
      area: TaskPresetArea.generalCleaning,
      title: 'Varrer o chão',
      recommendedRrule: 'FREQ=DAILY;INTERVAL=3',
      rationale: 'Poeira se espalha rápido.',
    ),
  ];

  group('CA-2.1 & RN-359: TaskPresetSearch', () {
    test(
      'Busca "LOUCA" encontra "Lavar louça" ignorando maiúsculas e acentos',
      () {
        final results = search.filter(presets: presets, query: 'LOUCA');
        expect(results.length, 1);
        expect(results.first.id, 'wash-dishes');
      },
    );

    test('Search "cozinha" returns only items from Cozinha area', () {
      final results = search.filter(presets: presets, query: 'cozinha');
      expect(results.length, 2);
      expect(results.every((p) => p.area == TaskPresetArea.kitchen), isTrue);
      expect(
        results.map((p) => p.id),
        containsAll(['wash-dishes', 'clean-stove']),
      );
    });

    test('Search "fogao" with accents and lowercase finds "Limpar fogao"', () {
      final results = search.filter(presets: presets, query: 'fogão');
      expect(results.length, 1);
      expect(results.first.id, 'clean-stove');
    });

    test('Search without match returns empty list', () {
      final results = search.filter(presets: presets, query: 'limpar aquário');
      expect(results, isEmpty);
    });

    test('Empty or whitespace search returns all presets', () {
      expect(search.filter(presets: presets, query: ''), presets);
      expect(search.filter(presets: presets, query: '   '), presets);
    });
  });
}
