import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/recipes/domain/services/pasted_recipe_parser.dart';

void main() {
  late PastedRecipeParser parser;

  setUp(() {
    parser = PastedRecipeParserImpl();
  });

  test('Receita vazia', () {
    final draft = parser.parse('   \n  ');
    expect(draft.title, isEmpty);
    expect(draft.ingredients, isEmpty);
    expect(draft.prepText, isEmpty);
  });

  test(
    'Simple recipe with title, ingredients with numbers and preparation',
    () {
      const text = '''
Bolo de Fubá

Ingredientes:
3 ovos
1 xícara de óleo
2 xícaras de açúcar
2 xícaras de fubá
1 colher de fermento

Modo de preparo:
Bata tudo no liquidificador.
Asse por 40 minutos em forno médio.
''';
      final draft = parser.parse(text);

      expect(draft.title, 'Bolo de Fubá');
      expect(draft.ingredients, [
        '3 ovos',
        '1 xícara de óleo',
        '2 xícaras de açúcar',
        '2 xícaras de fubá',
        '1 colher de fermento',
      ]);
      expect(
        draft.prepText,
        'Bata tudo no liquidificador.\n\nAsse por 40 minutos em forno médio.',
      );
    },
  );

  test(
    'Ingredientes com frações e caracteres especiais, e itens "a gosto"',
    () {
      const text = '''
- ½ xícara de leite
- 1/4 de colher de chá de sal
- sal a gosto
- pimenta a gosto

Misture os líquidos.
Adicione o sal e a pimenta.
''';
      final draft = parser.parse(text);

      expect(draft.title, isEmpty);
      expect(draft.ingredients, [
        '½ xícara de leite',
        '1/4 de colher de chá de sal',
        'sal a gosto',
        'pimenta a gosto',
      ]);
      expect(
        draft.prepText,
        'Misture os líquidos.\n\nAdicione o sal e a pimenta.',
      );
    },
  );

  test('Items with common terms and no numbers', () {
    const text = '''
* Pitada de sal
* Folha de louro
* Fio de óleo

Frite os temperos.
''';
    final draft = parser.parse(text);

    expect(draft.title, isEmpty);
    expect(draft.ingredients, [
      'Pitada de sal',
      'Folha de louro',
      'Fio de óleo',
    ]);
    expect(draft.prepText, 'Frite os temperos.');
  });
}
