import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_recipe_repository.dart';

import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';

import '../../fakes/fake_clock.dart';

void main() {
  late FakeClock clock;
  late FakeRecipeRepository repo;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 9, 23));
    repo = FakeRecipeRepository(clock);
  });

  test('upsert creates a new recipe', () async {
    final newRecipe = NewRecipe(
      title: 'Bolo',
      ingredients: [],
      prepText: 'Asse',
      timeMinutes: 40,
      servings: 8,
      tags: {'doce'},
    );

    final result = await repo.upsert(newRecipe);
    expect(result.isOk, isTrue);
    final recipe = result.valueOrNull!;
    expect(recipe.title, 'Bolo');
    expect(recipe.tags, {'doce'});
    expect(recipe.isFavorite, isFalse);
  });

  test('search filters by query, tags, and favorite', () async {
    await repo.upsert(
      const NewRecipe(
        id: '1',
        title: 'Bolo de Cenoura',
        ingredients: [],
        prepText: '',
        timeMinutes: 40,
        servings: 8,
        tags: {'doce', 'rapido'},
        isFavorite: true,
      ),
    );
    await repo.upsert(
      const NewRecipe(
        id: '2',
        title: 'Sopa',
        ingredients: [],
        prepText: '',
        timeMinutes: 20,
        servings: 2,
        tags: {'salgado', 'rapido'},
      ),
    );
    await repo.upsert(
      const NewRecipe(
        id: '3',
        title: 'Bolo de Chocolate',
        ingredients: [],
        prepText: '',
        timeMinutes: 60,
        servings: 10,
        tags: {'doce'},
      ),
    );

    // Sem filtros
    var res = await repo.search();
    expect(res.valueOrNull!.length, 3);

    // Por query
    res = await repo.search(query: 'bolo');
    expect(res.valueOrNull!.length, 2);

    // Por tag
    res = await repo.search(tags: {'rapido'});
    expect(res.valueOrNull!.length, 2);

    // By multiple tags (AND)
    res = await repo.search(tags: {'doce', 'rapido'});
    expect(res.valueOrNull!.length, 1);
    expect(res.valueOrNull!.first.title, 'Bolo de Cenoura');

    // Por favorito
    res = await repo.search(favorite: true);
    expect(res.valueOrNull!.length, 1);
    expect(res.valueOrNull!.first.title, 'Bolo de Cenoura');

    // Combinado
    res = await repo.search(query: 'sopa', favorite: false);
    expect(res.valueOrNull!.length, 1);
    expect(res.valueOrNull!.first.title, 'Sopa');
  });

  test('setFavorite toggles favorite status', () async {
    await repo.upsert(
      const NewRecipe(
        id: '1',
        title: 'Bolo',
        ingredients: [],
        prepText: '',
        timeMinutes: 40,
        servings: 8,
      ),
    );

    var res = await repo.search(favorite: true);
    expect(res.valueOrNull!.length, 0);

    final setRes = await repo.setFavorite('1', true);
    expect(setRes.isOk, isTrue);

    res = await repo.search(favorite: true);
    expect(res.valueOrNull!.length, 1);
    expect(res.valueOrNull!.first.isFavorite, isTrue);
  });
}
