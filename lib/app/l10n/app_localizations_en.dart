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
  }

  @override
  String get priceVariationAlert => 'Price variation alert';

  @override
  String priceVariationUp(String percent) {
    return 'Up $percent% above the 30-day average';
  }

  @override
  String priceVariationDown(String percent) {
    return 'Down $percent% below the 30-day average';
  }

  @override
  String purchaseTotalMismatch(String amount) {
    return 'Difference of $amount. The system does not adjust automatically.';
  }

  @override
  String get purchaseInvalidCnpj => 'Invalid CNPJ. Enter a valid CNPJ.';

  @override
  String purchaseChartA11y(
    String amount,
    String minAmount,
    String store,
    String date,
  ) {
    return '$amount on average in the last 30 days, lowest price $minAmount at $store on $date';
  }

  @override
  String get ocrTitle => 'Receipt Scanner';

  @override
  String get ocrCameraPermissionDenied => 'Camera permission denied';

  @override
  String get ocrCameraPermissionSettings => 'Go to Settings';

  @override
  String get ocrFlashOn => 'Turn flash on';

  @override
  String get ocrFlashOff => 'Turn flash off';

  @override
  String get ocrReviewTitle => 'Review';

  @override
  String get ocrReviewSave => 'Save';

  @override
  String get ocrReviewAdd => 'Add';

  @override
  String get ocrReviewDelete => 'Delete';

  @override
  String get ocrTotalMismatch => 'Sum of items differs from total';

  @override
  String get ocrItemLowConfidence => 'Check this item';

  @override
  String get ocrGalleryOption => 'Gallery';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get purchaseItemsSection => 'Items';

  @override
  String get purchaseAddItem => 'Add Item';

  @override
  String get purchaseNoStores =>
      'No stores registered. (Add one on the stores screen)';

  @override
  String purchaseLoadStoresError(String error) {
    return 'Error loading stores: $error';
  }

  @override
  String get purchaseProductLabel => 'Product';

  @override
  String get purchaseLoadProductsError => 'Error loading products';

  @override
  String get purchaseQuantityLabel => 'Quantity';

  @override
  String get purchaseTotalPriceLabel => 'Total Price';

  @override
  String get purchaseDiscountLabel => 'Total Discount';

  @override
  String get purchaseDeclaredTotalLabel => 'Declared Total (Receipt)';

  @override
  String purchaseItemsSum(String amount) {
    return 'Items Sum: $amount';
  }

  @override
  String get purchaseFormError => 'Fill in all fields correctly';

  @override
  String get priceTrendUp => 'Price increase in the period';

  @override
  String get priceTrendDown => 'Price decrease in the period';

  @override
  String get priceHistoryTitle => 'Price history';

  @override
  String get checklistTitle => 'Home checklist';

  @override
  String get checklistEmpty => 'No items in checklist.';

  @override
  String get checklistCategoryAll => 'All rooms';

  @override
  String get checklistSendToShoppingList => 'Send to shopping list';

  @override
  String get stockTitle => 'Home stock';

  @override
  String get stockEmpty => 'No products in stock.';

  @override
  String get stockLowAlert => 'Running low';

  @override
  String get stockEstimateNotice => 'Consumption estimate';

  @override
  String get searchGlobalTitle => 'Search';

  @override
  String get searchGlobalHint => 'Search across the app...';

  @override
  String get searchGlobalNoResults => 'No results found.';

  @override
  String get economyTitle => 'Economy Mode';

  @override
  String get economyMetaTitle => 'Savings goal';

  @override
  String get economyProgressLabel => 'Goal progress';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get backupTitle => 'Backup & Export';

  @override
  String get backupExportSection => 'Export Data';

  @override
  String get backupImportSection => 'Import Data';

  @override
  String get backupClearAllSection => 'Clear All';

  @override
  String get backupCloudSection => 'Cloud Backup';

  @override
  String get mascotDefaultName => 'Momo';

  @override
  String get mascotCustomizeTitle => 'Customize Mascot';

  @override
  String get mascotCustomizeSave => 'Save and apply';

  @override
  String get mascotCustomizeCancel => 'Cancel';

  @override
  String get mascotCustomizeRetry => 'Try again';

  @override
  String get mascotCustomizeNameLabel => 'Mascot name';

  @override
  String get mascotCustomizeNameHint => 'e.g. Momo';

  @override
  String get mascotCustomizePreview => 'Preview';

  @override
  String get mascotCustomizeAnimalSection => 'Animal';

  @override
  String get mascotCustomizePaletteSection => 'Color palette';

  @override
  String get mascotCustomizeAccessorySection => 'Accessory';

  @override
  String get mascotAnimalCat => 'Cat';

  @override
  String get mascotAnimalDog => 'Dog';

  @override
  String get mascotAnimalBunny => 'Bunny';

  @override
  String get mascotPaletteRose => 'Rose';

  @override
  String get mascotPaletteLavender => 'Lavender';

  @override
  String get mascotPaletteMint => 'Mint';

  @override
  String get mascotAccessoryNone => 'None';

  @override
  String get mascotAccessoryBow => 'Bow';

  @override
  String get mascotAccessoryCollar => 'Collar';

  @override
  String get mascotAccessoryScarf => 'Scarf';

  @override
  String get mascotSaveSuccess => 'Customization saved with care!';

  @override
  String get mascotSaveError => 'Error saving customization. Try again.';

  @override
  String get settingsMascotOption => 'Customize Momo';

  @override
  String get settingsMascotSubtitle =>
      'Choose your companion\'s animal, colors, and accessories';

  @override
  String get settingsTutorialOption => 'View tutorial with Momo';

  @override
  String get settingsTutorialSubtitle =>
      'Review how the app works with the mascot';

  @override
  String get onboardingSkip => 'Skip intro';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingStep1Title => 'Hi! I\'m Momo 💕';

  @override
  String get onboardingStep1Description =>
      'I\'m here to help take care of your cozy home and make everything lighter!';

  @override
  String get onboardingStep2Title => 'Here we look after your money together';

  @override
  String get onboardingStep2Description =>
      'Track your expenses, log purchases, and keep your budget on track without end-of-month surprises.';

  @override
  String get onboardingStep3Title => 'And your shopping too!';

  @override
  String get onboardingStep3Description =>
      'Build your grocery list at the store and scan receipts in the blink of an eye.';

  @override
  String get onboardingStep4Title => 'Don\'t forget your daily chores';

  @override
  String get onboardingStep4Description =>
      'Organize cleaning tasks, home care, and routines to keep your place welcoming.';

  @override
  String get onboardingStep5Title =>
      'I\'ll remind you when something needs attention';

  @override
  String get onboardingStep5Description =>
      'Stay calm with upcoming bill reminders so you never pay interest or late fees again.';

  @override
  String get onboardingStep6Title => 'You can customize my look anytime!';

  @override
  String get onboardingStep6Description =>
      'You can switch my animal, add accessories, and pick the colors that match you best.';

  @override
  String get onboardingCustomizePrompt => 'Want to customize my look now?';

  @override
  String get onboardingCustomizeButton => 'Customize now';

  @override
  String get dashboardMonthBalanceTitle => 'Your money this month';

  @override
  String get dashboardDueBillsTitle => 'Bills that need attention';

  @override
  String get dashboardTodayTasksTitle => 'Today\'s tasks';

  @override
  String get momoGreeting => 'Hi! I\'m Momo 💕';

  @override
  String get momoShoppingAllBought =>
      'All bought! Want me to log this purchase?';

  @override
  String get momoDayOff => 'Today can be a day off ☕';

  @override
  String get momoEmptyExpenses => 'Momo is thinking — no expenses recorded yet';

  @override
  String get momoEmptyShoppingList =>
      'Momo is ready to shop — no list created yet';

  @override
  String get momoEmptyShoppingListCompleted =>
      'Momo is happy because you completed the list';

  @override
  String get momoEmptyTasks => 'Momo is relaxed — no tasks for today';

  @override
  String get celebrationShoppingCompletedTitle => 'Congratulations!';

  @override
  String get celebrationShoppingCompletedMessage =>
      'All bought! Your list is complete 💕';

  @override
  String get celebrationTasksCompletedTitle => 'All done!';

  @override
  String get celebrationTasksCompletedMessage =>
      'You finished all of today\'s tasks! Get plenty of rest 💕';

  @override
  String get mascotSemanticsNeutral => 'Momo is here with you';

  @override
  String get mascotSemanticsHappy => 'Momo is happy';

  @override
  String get mascotSemanticsWorried => 'Momo is worried about the bills';

  @override
  String get mascotSemanticsSleepy => 'Momo is sleepy';

  @override
  String get mascotSemanticsPointing => 'Momo is pointing out an important tip';

  @override
  String get mascotSemanticsWaving => 'Momo is waving warmly at you';

  @override
  String get mascotSemanticsThinking => 'Momo is thinking';

  @override
  String get mascotSemanticsRelaxed => 'Momo is relaxed and calm';

  @override
  String get mascotSemanticsShopping => 'Momo is ready for shopping';

  @override
  String get mascotSemanticsBudget =>
      'Momo is keeping an eye on this month\'s budget';

  @override
  String get mascotSemanticsPlaceholder => 'Momo mascot illustration';

  @override
  String get taskPresetsTitle => 'Home suggestions';

  @override
  String get taskPresetsSubtitle =>
      'Common task ideas with recommended frequencies';

  @override
  String get taskPresetsSearchHint => 'Search suggestions...';

  @override
  String taskPresetsEmptySearch(String query) {
    return 'No suggestions found for \"$query\"';
  }

  @override
  String get taskPresetsCustomTaskCta => 'Create custom task';

  @override
  String get taskPresetsAreaKitchen => 'Kitchen';

  @override
  String get taskPresetsAreaBathroom => 'Bathroom';

  @override
  String get taskPresetsAreaBedroom => 'Bedroom';

  @override
  String get taskPresetsAreaLaundry => 'Laundry';

  @override
  String get taskPresetsAreaGeneralCleaning => 'General cleaning';

  @override
  String get taskPresetsAreaShopping => 'Shopping';

  @override
  String get taskPresetsAlreadyInRoutine => 'Already in your routine';

  @override
  String get taskPresetsDuplicateTitle => 'Task already in routine';

  @override
  String get taskPresetsDuplicateMessage =>
      'You already have an active task for this preset. Do you want to add another one anyway?';

  @override
  String get taskPresetsDuplicateConfirm => 'Add anyway';

  @override
  String get taskPresetsDuplicateCancel => 'Cancel';

  @override
  String taskPresetsAddSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count tasks',
      one: 'Add 1 task',
    );
    return '$_temp0';
  }

  @override
  String taskPresetsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get taskPresetsBatchTitle => 'Start dates';

  @override
  String get taskPresetsBatchConfirm => 'Confirm routine';

  @override
  String get taskPresetsBatchUndo => 'Undo';

  @override
  String taskPresetsBatchSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks added!',
      one: '1 task added!',
    );
    return '$_temp0';
  }

  @override
  String taskPresetsBatchStartDateLabel(String task) {
    return 'Start of $task';
  }

  @override
  String get taskPresetsEmptyStatePrompt =>
      'How about seeing suggestions for your home routine?';

  @override
  String get taskPresetsEmptyStateButton => 'See home suggestions';

  @override
  String get onboardingRoutineTitle => 'Build your home routine';

  @override
  String get onboardingRoutineDescription =>
      'Pick common tasks to start your routine effortlessly. You can change everything later!';

  @override
  String get onboardingRoutineSkip => 'Skip this step';

  @override
  String get householdTitle => 'Shared home';

  @override
  String get householdSubtitle => 'Sync tasks and finances over local network';

  @override
  String get householdEmptyTitle => 'Share your home';

  @override
  String get householdEmptyDescription =>
      'Sync with the people you live with—no middlemen, no account needed, and end-to-end encrypted on your local network.';

  @override
  String get householdCreateButton => 'Create home';

  @override
  String get householdJoinButton => 'Join a home';

  @override
  String get householdSyncNowButton => 'Sync now';

  @override
  String get householdGenerateBundleButton => 'Generate bundle';

  @override
  String get householdInviteButton => 'Invite device';

  @override
  String get householdOnlyThisDevice => 'Changes only on this device';

  @override
  String get householdAllSynced => 'All synced';

  @override
  String get householdSyncing => 'Syncing...';

  @override
  String householdLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get householdMembersTitle => 'Devices in home';

  @override
  String get householdAreasTitle => 'Shared areas';

  @override
  String get householdAreaHome => 'Home (Tasks, Stock, Recipes)';

  @override
  String get householdAreaFinance => 'Finances (Expenses, Bills, Prices)';

  @override
  String get householdPairingTitle => 'Connect device';

  @override
  String get householdPairingScanPrompt =>
      'Point the camera at the QR code on the other device';

  @override
  String get householdPairingShowPrompt =>
      'Show this QR code on the device you want to connect';

  @override
  String householdPairingCodeLabel(String code) {
    return 'Confirmation code: $code';
  }

  @override
  String get householdLeaveButton => 'Leave home';

  @override
  String get householdLeaveKeepData => 'Keep a local copy';

  @override
  String get householdLeaveWipeData => 'Delete shared data';

  @override
  String get householdRemoveMemberTitle => 'Remove device';

  @override
  String get householdRemoveMemberConfirm => 'Remove';

  @override
  String get householdRemoveMemberWarning =>
      'The removed device will lose access and future changes will no longer sync with it.';

  @override
  String get householdErrorIncompatibleProtocol =>
      'Device uses an incompatible sync protocol version.';

  @override
  String get householdErrorInviteExpired =>
      'The invite has expired. Generate a new invite to pair.';

  @override
  String get householdErrorNoNetwork =>
      'No device found on the local network. Check that both are on the same Wi-Fi.';

  @override
  String get customizeDashboardTitle => 'Customize home';

  @override
  String get customizeDashboardAction => 'Customize home';

  @override
  String get customizeDashboardAddCards => 'Add to dashboard';

  @override
  String get customizeDashboardEmptyTitle => 'No visible items on dashboard';

  @override
  String get customizeDashboardEmptyAction => 'Add items to dashboard';

  @override
  String get customizeDashboardRestoreDefault => 'Restore default';

  @override
