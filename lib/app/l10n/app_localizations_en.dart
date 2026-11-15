// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'My Sweet Home';

  @override
  String get productsTitle => 'Products';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get billsTitle => 'Bills';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get recipesTitle => 'Recipes';

  @override
  String get expenseQuickAddTitle => 'New Expense';

  @override
  String get expenseQuickAddSave => 'Save';

  @override
  String expenseQuickAddError(Object error) {
    return 'Error: $error';
  }

  @override
  String get recipeDraftNewTitle => 'New Recipe';

  @override
  String get recipeDraftTitleLabel => 'Title';

  @override
  String get recipeDraftPrepLabel => 'Instructions';

  @override
  String get recipeDraftTimeLabel => 'Time (min)';

  @override
  String get recipeDraftServingsLabel => 'Servings';

  @override
  String get recipeDraftIngredientsLabel => 'Ingredients';

  @override
  String get recipeDraftNewIngredientButton => 'Add Ingredient';

  @override
  String get recipeDraftFavoriteLabel => 'Favorite';

  @override
  String get recipeDraftTagsLabel => 'Tags';

  @override
  String get recipeDraftAddTagButton => 'Add Tag';

  @override
  String get recipeDraftNewTagPlaceholder => 'New tag';

  @override
  String get recipeDraftNewIngredientPlaceholder => 'New Ingredient';

  @override
  String get recipePreparationTitle => 'Instructions';

  @override
  String get recipePreparationBody => 'Recipe Preparation';

  @override
  String get recipeListEmpty =>
      'No recipes yet. Start with the one you make most.';

  @override
  String get recipeListCreate => 'Create recipe';

  @override
  String get recipeListError => 'Failed to load recipes';

  @override
  String get recipeListRetry => 'Try again';

  @override
  String get recipeDetailError => 'Failed to load recipe';

  @override
  String get recipeDetailRetry => 'Try again';

  @override
  String get recipeDetailNoCost => 'Cost unavailable';

  @override
  String get recipeDetailCostExplain =>
      'Missing prices for too many ingredients.';

  @override
  String get recipeDetailRegisterPrices => 'Register prices';

  @override
  String recipeDetailEstimatedCost(String amount) {
    return 'Estimated cost: $amount';
  }

  @override
  String recipeDetailCostMissing(int count) {
    return '$count ingredient(s) without price';
  }

  @override
  String get recipeDetailTitle => 'Recipe Card';

  @override
  String get recipeListSearchHint => 'Search recipes';

  @override
  String get recipeListFavoriteFilter => 'Favorites';

  @override
  String get recipeDetailIngredients => 'Ingredients';

  @override
  String get recipeDetailPreparation => 'Instructions';

  @override
  String recipeDetailTime(int time) {
    return '$time min';
  }

  @override
  String recipeDetailServings(int servings) {
    return '$servings servings';
  }

  @override
  String get taskQuickAddTitle => 'New Task';

  @override
  String get taskQuickAddSave => 'Save';

  @override
  String taskQuickAddError(Object error) {
