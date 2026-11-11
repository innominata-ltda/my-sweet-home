import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_recipe_repository.dart';

import 'package:my_sweet_home/features/recipes/domain/models/recipe.dart';
import 'package:my_sweet_home/features/recipes/presentation/recipe_list_controller.dart';

import '../../fakes/fake_clock.dart';

void main() {
  late FakeClock clock;
  late FakeRecipeRepository repo;
  late RecipeListController controller;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 9, 23));
    repo = FakeRecipeRepository(clock);

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

    controller = RecipeListController(repo);
    // Wait for the initial load to complete
    await Future.microtask(() {});
  });

  test('initial state loads all recipes', () async {
    final state = controller.value;
    expect(state, isA<RecipeListSuccess>());

    final success = state as RecipeListSuccess;
    expect(success.recipes.length, 3);
    expect(success.filter.query, '');
    expect(success.filter.tags, isEmpty);
    expect(success.filter.favorite, isNull);
  });

  test('updateFilter by query filters recipes', () async {
    controller.updateFilter(query: 'bolo');
    // Wait for load
    await Future.microtask(() {});

    final state = controller.value as RecipeListSuccess;
    expect(state.recipes.length, 2);
    expect(state.filter.query, 'bolo');
  });

  test('updateFilter by tags filters recipes', () async {
    controller.updateFilter(tags: {'rapido'});
    await Future.microtask(() {});

    final state = controller.value as RecipeListSuccess;
    expect(state.recipes.length, 2);
    expect(state.filter.tags, {'rapido'});
  });

  test('updateFilter by favorite filters recipes', () async {
    controller.updateFilter(favorite: true);
    await Future.microtask(() {});

    final state = controller.value as RecipeListSuccess;
    expect(state.recipes.length, 1);
    expect(state.recipes.first.title, 'Bolo de Cenoura');
    expect(state.filter.favorite, isTrue);
  });

  test('updateFilter can clear favorite filter', () async {
    controller.updateFilter(favorite: true);
    await Future.microtask(() {});

    controller.updateFilter(clearFavorite: true);
    await Future.microtask(() {});

    final state = controller.value as RecipeListSuccess;
    expect(state.recipes.length, 3);
    expect(state.filter.favorite, isNull);
  });

  test('toggleFavorite updates recipe and refreshes list', () async {
    // Sopa is not favorite initially
    await controller.toggleFavorite('2', false);
    await Future.microtask(() {});

    // Check if repo was updated
    final res = await repo.search(favorite: true);
    expect(res.valueOrNull!.length, 2);

    // Filter by favorite to see if Sopa shows up
    controller.updateFilter(favorite: true);
    await Future.microtask(() {});

    final state = controller.value as RecipeListSuccess;
    expect(state.recipes.length, 2);
    expect(state.recipes.any((r) => r.title == 'Sopa'), isTrue);
  });
}
