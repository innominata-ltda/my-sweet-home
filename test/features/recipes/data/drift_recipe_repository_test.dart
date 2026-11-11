import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/features/recipes/data/repositories/drift_recipe_repository.dart';
import 'package:my_sweet_home/features/recipes/domain/models/ingredient.dart';
import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';

class TestClock extends Clock {
  const TestClock(this.time);
  final DateTime time;

  @override
  DateTime nowUtc() => time.toUtc();

  @override
  DateTime nowLocal() => time;
}

void main() {
  late AppDatabase db;
  late DriftRecipeRepository repo;
  late Clock clock;

  setUp(() {
    db = AppDatabase.memory();
    clock = TestClock(DateTime(2026, 1, 1));
    repo = DriftRecipeRepository(db, clock);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert creates a new recipe with tags and ingredients', () async {
    final recipe = NewRecipe(
      title: 'Bolo',
      prepText: 'Assar',
      timeMinutes: 40,
      servings: 8,
      tags: {'doce', 'festa'},
      ingredients: [
        Ingredient(name: 'Farinha', quantity: Quantity(500, Unit.g)),
        Ingredient(name: 'Ovos', quantity: Quantity(3, Unit.un)),
      ],
      isFavorite: true,
    );

    final result = await repo.upsert(recipe);
    expect(result.isOk, true);

    final created = result.valueOrNull!;
    expect(created.title, 'Bolo');
    expect(created.ingredients.length, 2);
    expect(created.tags.length, 2);
    expect(created.isFavorite, true);

    // Verify in db
    final fetchedResult = await repo.getById(created.id);
    expect(fetchedResult.isOk, true);
    final fetched = fetchedResult.valueOrNull!;
    expect(fetched.title, 'Bolo');
    expect(fetched.tags, {'doce', 'festa'});
    expect(fetched.ingredients[0].name, 'Farinha');
    expect(fetched.ingredients[0].quantity?.valueMilli, 500);
    expect(fetched.ingredients[0].quantity?.unit, Unit.g);
  });

  test('search filters by query and tags without N+1', () async {
    await repo.upsert(
      const NewRecipe(
        title: 'Bolo de Cenoura',
        prepText: 'Assar',
        timeMinutes: 40,
        servings: 8,
        tags: {'doce', 'festa'},
        ingredients: [Ingredient(name: 'Cenoura')],
      ),
    );
    await repo.upsert(
      const NewRecipe(
        title: 'Sopa',
        prepText: 'Ferver',
        timeMinutes: 30,
        servings: 4,
        tags: {'salgado'},
        ingredients: [Ingredient(name: 'Batata')],
      ),
    );

    final result = await repo.search(query: 'bolo');
    expect(result.isOk, true);
    final recipes = result.valueOrNull!;
    expect(recipes.length, 1);
    expect(recipes.first.title, 'Bolo de Cenoura');
    expect(recipes.first.tags, {'doce', 'festa'});
    expect(recipes.first.ingredients.first.name, 'Cenoura');

    final resultTags = await repo.search(tags: {'salgado'});
    expect(resultTags.isOk, true);
    expect(resultTags.valueOrNull!.first.title, 'Sopa');
  });

  test('setFavorite updates favorite status', () async {
    final result = await repo.upsert(
      const NewRecipe(
        title: 'Teste',
        prepText: '',
        timeMinutes: 10,
        servings: 1,
        ingredients: [],
      ),
    );
    final id = result.valueOrNull!.id;

    await repo.setFavorite(id, true);
    final updated = (await repo.getById(id)).valueOrNull!;
    expect(updated.isFavorite, true);
  });

  test('remove deletes recipe', () async {
    final result = await repo.upsert(
      const NewRecipe(
        title: 'Teste',
        prepText: '',
        timeMinutes: 10,
        servings: 1,
        ingredients: [],
      ),
    );
    final id = result.valueOrNull!.id;

    final removeResult = await repo.remove(id);
    expect(removeResult.isOk, true);

    final fetchResult = await repo.getById(id);
    expect(fetchResult.isErr, true);
  });

  test('search handles many recipes avoiding SQLite parameter limit', () async {
    for (var i = 0; i < 1100; i++) {
      await repo.upsert(
        NewRecipe(
          title: 'Receita ${i.toString().padLeft(4, '0')}',
          prepText: 'Fazer',
          timeMinutes: 10,
          servings: 1,
          ingredients: [Ingredient(name: 'Ingrediente $i')],
          tags: {'tag$i'},
        ),
      );
    }

    final result = await repo.search();
    expect(result.isOk, true);
    final recipes = result.valueOrNull!;
    expect(recipes.length, 1100);
    // Verifies chunking logic didn't drop data
    expect(recipes.first.ingredients.length, 1);
    expect(recipes.last.tags.length, 1);
  });
}
