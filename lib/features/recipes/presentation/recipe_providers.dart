import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/recipes/domain/services/pasted_recipe_parser.dart';
import 'package:my_sweet_home/features/recipes/domain/usecases/send_ingredients_to_shopping_list_usecase.dart';
import 'package:my_sweet_home/features/shopping/data/shopping_repository_provider.dart';

final pastedRecipeParserProvider = Provider<PastedRecipeParser>((ref) {
  return PastedRecipeParserImpl();
});

final sendIngredientsToShoppingListUseCaseProvider =
    Provider<SendIngredientsToShoppingListUseCase>((ref) {
      return SendIngredientsToShoppingListUseCase(
        ref.watch(shoppingListRepositoryProvider),
        ref.watch(idGeneratorProvider),
      );
    });
