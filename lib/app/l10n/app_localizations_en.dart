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
    return 'Error: $error';
  }

  @override
  String get taskQuickAddPlaceholder => 'Task title';

  @override
  String get billsEmpty =>
      'Add your recurring bills and never pay a late fee again.';

  @override
  String get billsCreate => 'Add bill';

  @override
  String get billsAllPaid => 'Nothing to pay this month';

  @override
  String get billsError => 'Failed to load';

  @override
  String get billsRetry => 'Try again';

  @override
  String get billsNotificationWarning => 'Notifications aren\'t arriving?';

  @override
  String get billsNotificationWarningExplanation =>
      'Your phone may be blocking My Sweet Home alerts to save battery. You can turn off battery optimization in your device settings to make sure you\'re reminded on the due date. Even if a notification fails, due dates remain visible here on the bills screen.';

  @override
  String get billsNotificationAllow => 'Fix';

  @override
  String get billsBatteryOptimizationDialogTitle => 'Important notices';

  @override
  String get billsStatusOverdue => 'Overdue';

  @override
  String get billsStatusPaid => 'Paid';

  @override
  String get billsStatusPending => 'Pending';

  @override
  String billsMarkAsPaid(String billName) {
    return 'Mark $billName as paid';
  }

  @override
  String get productSearchHint => 'Search products';

  @override
  String get productEmptyState => 'No products found.';

  @override
  String get productNew => 'New Product';

  @override
  String get productName => 'Name';

  @override
  String get productCategory => 'Category';

  @override
  String get productUnit => 'Unit';

  @override
  String get productAliases => 'Aliases and variations';

  @override
  String get productAddAlias => 'Add alias';

  @override
  String get productAliasPlaceholder => 'New alias';

  @override
  String get productAliasesEmpty => 'No aliases registered.';

  @override
  String get productError => 'Error loading products.';

  @override
  String get productDetailError => 'Error loading details.';

  @override
  String get productRemoveAliasConfirm => 'Remove alias?';

  @override
  String productRemoveAliasA11y(String alias) {
    return 'Remove alias $alias';
  }

  @override
  String productSuggestionTitle(String productName) {
    return 'Is this the same as $productName?';
  }

  @override
  String productSuggestionYes(String alias, String productName) {
    return 'Yes, $alias is the same as $productName';
  }

  @override
  String get productSuggestionNo => 'No, they are different things';

  @override
  String get productSave => 'Save';

  @override
  String get productCancel => 'Cancel';

  @override
  String get expensesEmpty => 'No expenses this month.';

  @override
  String get expensesError => 'Error loading expense summary.';

  @override
  String get expensesRetry => 'Try again';

  @override
  String get expensesChartAltText => 'Donut chart showing budget usage.';

  @override
  String expensesTotal(String amount) {
    return 'Spent: $amount';
  }

  @override
  String expensesBudgetSet(String amount) {
    return 'Budget: $amount';
  }

  @override
  String expensesRemaining(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String expensesOverBudget(String amount) {
    return 'Over budget: $amount';
  }

  @override
  String get billHistoryTitle => 'Payment history';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get billHistoryEmpty => 'No payments recorded for this bill.';

  @override
  String get billHistoryError => 'Failed to load history.';

  @override
  String get billHistoryRetry => 'Try again';

  @override
  String billHistoryDueOn(String date) {
    return 'Due date: $date';
  }

  @override
  String billHistoryPaidOn(String date) {
    return 'Paid on: $date';
  }

  @override
  String get expensesEmptyCallToAction =>
      'No expenses this month. How about adding your first one?';

  @override
  String get expensesLaunchFirst => 'add expense';

  @override
  String get expensesNoBudgetInvite => 'prompt to set a budget';

  @override
  String get expensesSetBudget => 'set budget';

  @override
  String get expensesForecastNoHistory =>
      'Not enough history yet to forecast month-end.';

  @override
  String get expensesForecastExplanation =>
      'The forecast considers your current spending, pending recurring bills, and average spending from recent months.';

  @override
  String get expensesForecastTitle => 'Month-end forecast';

  @override
  String expensesForecastAmount(String amount) {
    return 'Forecast: $amount';
  }

  @override
  String expensesChartCategoryAlt(
    String category,
    String amount,
    String percent,
  ) {
    return '$category: $amount ($percent%)';
  }

  @override
  String get expensesByCategoryTitle => 'Expenses by category';

  @override
  String get billsNotificationPermissionDeniedWarning =>
      'Without permission, you won\'t be notified before the due date and may incur late fees.';

  @override
  String get billsNotificationPermissionDeniedSettings => 'Go to Settings';

  @override
  String get billsNotificationPermissionDeniedDismiss => 'Got it';

  @override
  String get shoppingListsTitle => 'Shopping lists';

  @override
  String get shoppingListEmpty => 'Empty list. Add what you need at home.';

  @override
  String get shoppingListAllDone => 'All bought 🎉';

  @override
  String get shoppingListRegisterPurchase => 'record purchase';

  @override
  String shoppingListMarkAsBought(String item) {
    return 'Mark $item as bought';
  }

  @override
  String shoppingListUnmarkAsBought(String item) {
    return 'Unmark $item as bought';
  }

  @override
  String get shoppingListAddItemLabel => 'Add item';

  @override
  String get shoppingListAddItemHint => 'e.g. 2kg of rice';

  @override
  String get shoppingListUndo => 'Undo';

  @override
  String shoppingListEstimateWithUnknowns(String total, int count) {
    return '$total + $count items without price';
  }

  @override
  String shoppingListEstimateWithOneUnknown(String total) {
    return '$total + 1 item without price';
  }

  @override
  String shoppingListEstimateExact(String total) {
    return 'Estimate: $total';
  }

  @override
  String shoppingListItemQuantity(String quantity, String unit) {
    return 'Qty: $quantity $unit';
  }

  @override
  String get shoppingListError => 'Failed to load shopping list';

  @override
  String get shoppingListRetry => 'Try again';

  @override
  String get purchasesTitle => 'Purchases';

  @override
  String get purchaseNew => 'New Purchase';

  @override
  String get pricesTitle => 'Price History';

  @override
  String get pricesEmpty => 'No prices yet. Record a purchase to get started.';

  @override
  String get pricesFewData => 'too few observations to conclude';

  @override
  String get pricesLoadError => 'failed to load history';

  @override
  String get pricesRetry => 'try again';

  @override
  String get pricesRankingTitle => 'Store ranking';

  @override
  String get storeTitle => 'Store';

  @override
  String cheapestStore(String store) {
    return 'Cheapest at $store';
  }

  @override
  String get notEnoughData => 'not enough data';

  @override
  String priceAverage(String amount) {
    return 'Usually costs $amount';
  }

  @override
  String priceAverageObservations(int count) {
    return 'based on $count observations';
