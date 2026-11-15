import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'My Sweet Home'**
  String get appName;

  /// No description provided for @productsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get productsTitle;

  /// No description provided for @expensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expensesTitle;

  /// No description provided for @budgetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento'**
  String get budgetTitle;

  /// No description provided for @billsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get billsTitle;

  /// No description provided for @tasksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get tasksTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Calendário'**
  String get calendarTitle;

  /// No description provided for @recipesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get recipesTitle;

  /// No description provided for @expenseQuickAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Despesa'**
  String get expenseQuickAddTitle;

  /// No description provided for @expenseQuickAddSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get expenseQuickAddSave;

  /// No description provided for @expenseQuickAddError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String expenseQuickAddError(Object error);

  /// No description provided for @recipeDraftNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Receita'**
  String get recipeDraftNewTitle;

  /// No description provided for @recipeDraftTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get recipeDraftTitleLabel;

  /// No description provided for @recipeDraftPrepLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Preparo'**
  String get recipeDraftPrepLabel;

  /// No description provided for @recipeDraftTimeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tempo (min)'**
  String get recipeDraftTimeLabel;

  /// No description provided for @recipeDraftServingsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Porções'**
  String get recipeDraftServingsLabel;

  /// No description provided for @recipeDraftIngredientsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes'**
  String get recipeDraftIngredientsLabel;

  /// No description provided for @recipeDraftNewIngredientButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Ingrediente'**
  String get recipeDraftNewIngredientButton;

  /// No description provided for @recipeDraftFavoriteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Favorito'**
  String get recipeDraftFavoriteLabel;

  /// No description provided for @recipeDraftTagsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get recipeDraftTagsLabel;

  /// No description provided for @recipeDraftAddTagButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Tag'**
  String get recipeDraftAddTagButton;

  /// No description provided for @recipeDraftNewTagPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Nova tag'**
  String get recipeDraftNewTagPlaceholder;

  /// No description provided for @recipeDraftNewIngredientPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Novo Ingrediente'**
  String get recipeDraftNewIngredientPlaceholder;

  /// No description provided for @recipePreparationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Preparo'**
  String get recipePreparationTitle;

  /// No description provided for @recipePreparationBody.
  ///
  /// In pt, this message translates to:
  /// **'Preparo da Receita'**
  String get recipePreparationBody;

  /// No description provided for @recipeListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma receita ainda. Comece pela que você mais faz.'**
  String get recipeListEmpty;

  /// No description provided for @recipeListCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar receita'**
  String get recipeListCreate;

  /// No description provided for @recipeListError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar receitas'**
  String get recipeListError;

  /// No description provided for @recipeListRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get recipeListRetry;

  /// No description provided for @recipeDetailError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar receita'**
  String get recipeDetailError;

  /// No description provided for @recipeDetailRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get recipeDetailRetry;

  /// No description provided for @recipeDetailNoCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo indisponível'**
  String get recipeDetailNoCost;

  /// No description provided for @recipeDetailCostExplain.
  ///
  /// In pt, this message translates to:
  /// **'Faltam preços para muitos ingredientes.'**
  String get recipeDetailCostExplain;

  /// No description provided for @recipeDetailRegisterPrices.
  ///
  /// In pt, this message translates to:
  /// **'Registrar preços'**
  String get recipeDetailRegisterPrices;

  /// No description provided for @recipeDetailEstimatedCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo estimado: {amount}'**
  String recipeDetailEstimatedCost(String amount);

  /// No description provided for @recipeDetailCostMissing.
  ///
  /// In pt, this message translates to:
  /// **'{count} ingrediente(s) sem preço'**
  String recipeDetailCostMissing(int count);

  /// No description provided for @recipeDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ficha da Receita'**
  String get recipeDetailTitle;

  /// No description provided for @recipeListSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar receitas'**
  String get recipeListSearchHint;

  /// No description provided for @recipeListFavoriteFilter.
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get recipeListFavoriteFilter;

  /// No description provided for @recipeDetailIngredients.
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes'**
  String get recipeDetailIngredients;

  /// No description provided for @recipeDetailPreparation.
  ///
  /// In pt, this message translates to:
  /// **'Modo de preparo'**
  String get recipeDetailPreparation;

  /// No description provided for @recipeDetailTime.
  ///
  /// In pt, this message translates to:
  /// **'{time} min'**
  String recipeDetailTime(int time);

  /// No description provided for @recipeDetailServings.
  ///
  /// In pt, this message translates to:
  /// **'{servings} porções'**
  String recipeDetailServings(int servings);

  /// No description provided for @taskQuickAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Tarefa'**
  String get taskQuickAddTitle;

  /// No description provided for @taskQuickAddSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get taskQuickAddSave;

  /// No description provided for @taskQuickAddError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String taskQuickAddError(Object error);

  /// No description provided for @taskQuickAddPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Título da tarefa'**
  String get taskQuickAddPlaceholder;

  /// No description provided for @billsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre suas contas fixas e nunca mais pague multa.'**
  String get billsEmpty;

  /// No description provided for @billsCreate.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar conta'**
  String get billsCreate;

  /// No description provided for @billsAllPaid.
  ///
  /// In pt, this message translates to:
  /// **'Nada a pagar este mês'**
  String get billsAllPaid;

  /// No description provided for @billsError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar'**
  String get billsError;

  /// No description provided for @billsRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get billsRetry;

  /// No description provided for @billsNotificationWarning.
  ///
  /// In pt, this message translates to:
  /// **'As notificações não estão chegando?'**
  String get billsNotificationWarning;

  /// No description provided for @billsNotificationWarningExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Seu celular pode estar bloqueando os avisos do My Sweet Home para economizar bateria. Você pode desligar essa economia nas configurações do aparelho para garantir que vai ser lembrado no dia do vencimento. Mesmo se a notificação falhar, os vencimentos continuam visíveis aqui na tela de contas.'**
  String get billsNotificationWarningExplanation;

  /// No description provided for @billsNotificationAllow.
  ///
  /// In pt, this message translates to:
  /// **'Resolver'**
  String get billsNotificationAllow;

  /// No description provided for @billsBatteryOptimizationDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisos importantes'**
  String get billsBatteryOptimizationDialogTitle;

  /// No description provided for @billsStatusOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get billsStatusOverdue;

  /// No description provided for @billsStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get billsStatusPaid;

  /// No description provided for @billsStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get billsStatusPending;

  /// No description provided for @billsMarkAsPaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar {billName} como pago'**
  String billsMarkAsPaid(String billName);

  /// No description provided for @productSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar produtos'**
  String get productSearchHint;

  /// No description provided for @productEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado.'**
  String get productEmptyState;

  /// No description provided for @productNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Produto'**
  String get productNew;

  /// No description provided for @productName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get productName;

  /// No description provided for @productCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get productCategory;

  /// No description provided for @productUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get productUnit;

  /// No description provided for @productAliases.
  ///
  /// In pt, this message translates to:
  /// **'Apelidos e variações'**
  String get productAliases;

  /// No description provided for @productAddAlias.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar apelido'**
  String get productAddAlias;

  /// No description provided for @productAliasPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Novo apelido'**
  String get productAliasPlaceholder;

  /// No description provided for @productAliasesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apelido cadastrado.'**
  String get productAliasesEmpty;

  /// No description provided for @productError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar produtos.'**
  String get productError;

  /// No description provided for @productDetailError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar detalhes.'**
  String get productDetailError;

  /// No description provided for @productRemoveAliasConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Remover apelido?'**
  String get productRemoveAliasConfirm;

  /// No description provided for @productRemoveAliasA11y.
  ///
  /// In pt, this message translates to:
  /// **'Remover apelido {alias}'**
  String productRemoveAliasA11y(String alias);

  /// No description provided for @productSuggestionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Isso é o mesmo que {productName}?'**
  String productSuggestionTitle(String productName);

  /// No description provided for @productSuggestionYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim, {alias} é o mesmo que {productName}'**
  String productSuggestionYes(String alias, String productName);

  /// No description provided for @productSuggestionNo.
  ///
  /// In pt, this message translates to:
  /// **'Não, são coisas diferentes'**
  String get productSuggestionNo;

  /// No description provided for @productSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get productSave;

  /// No description provided for @productCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get productCancel;

  /// No description provided for @expensesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma despesa este mês.'**
  String get expensesEmpty;

  /// No description provided for @expensesError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o resumo de despesas.'**
  String get expensesError;

  /// No description provided for @expensesRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get expensesRetry;

  /// No description provided for @expensesChartAltText.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico circular mostrando o uso do orçamento.'**
  String get expensesChartAltText;

  /// No description provided for @expensesTotal.
  ///
  /// In pt, this message translates to:
  /// **'Realizado: {amount}'**
  String expensesTotal(String amount);

  /// No description provided for @expensesBudgetSet.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento: {amount}'**
  String expensesBudgetSet(String amount);

  /// No description provided for @expensesRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Restante: {amount}'**
  String expensesRemaining(String amount);

  /// No description provided for @expensesOverBudget.
  ///
  /// In pt, this message translates to:
  /// **'Estourou: {amount}'**
  String expensesOverBudget(String amount);

  /// No description provided for @billHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de pagamentos'**
  String get billHistoryTitle;

  /// No description provided for @expenseDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Despesa excluída'**
  String get expenseDeleted;

  /// No description provided for @billHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagamento registrado para esta conta.'**
  String get billHistoryEmpty;

  /// No description provided for @billHistoryError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar o histórico.'**
  String get billHistoryError;

  /// No description provided for @billHistoryRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get billHistoryRetry;

  /// No description provided for @billHistoryDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento: {date}'**
  String billHistoryDueOn(String date);

  /// No description provided for @billHistoryPaidOn.
  ///
  /// In pt, this message translates to:
  /// **'Pago em: {date}'**
  String billHistoryPaidOn(String date);

  /// No description provided for @expensesEmptyCallToAction.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma despesa este mês. Que tal lançar a primeira?'**
  String get expensesEmptyCallToAction;

  /// No description provided for @expensesLaunchFirst.
  ///
  /// In pt, this message translates to:
  /// **'lançar despesa'**
  String get expensesLaunchFirst;

  /// No description provided for @expensesNoBudgetInvite.
  ///
  /// In pt, this message translates to:
  /// **'convite para definir orçamento'**
  String get expensesNoBudgetInvite;

  /// No description provided for @expensesSetBudget.
  ///
  /// In pt, this message translates to:
  /// **'definir orçamento'**
  String get expensesSetBudget;

  /// No description provided for @expensesForecastNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há histórico suficiente para prever o fechamento do mês.'**
  String get expensesForecastNoHistory;

  /// No description provided for @expensesForecastExplanation.
  ///
  /// In pt, this message translates to:
  /// **'A previsão considera seus gastos atuais, contas fixas pendentes e a média de gastos dos últimos meses.'**
  String get expensesForecastExplanation;

  /// No description provided for @expensesForecastTitle.
  ///
  /// In pt, this message translates to:
  /// **'Previsão de fechamento'**
  String get expensesForecastTitle;

  /// No description provided for @expensesForecastAmount.
  ///
  /// In pt, this message translates to:
  /// **'Previsão: {amount}'**
  String expensesForecastAmount(String amount);

  /// No description provided for @expensesChartCategoryAlt.
  ///
  /// In pt, this message translates to:
  /// **'{category}: {amount} ({percent}%)'**
  String expensesChartCategoryAlt(
    String category,
    String amount,
    String percent,
  );

  /// No description provided for @expensesByCategoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Despesas por categoria'**
  String get expensesByCategoryTitle;

  /// No description provided for @billsNotificationPermissionDeniedWarning.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão, você não será avisado antes do vencimento e pode pagar multa.'**
  String get billsNotificationPermissionDeniedWarning;

  /// No description provided for @billsNotificationPermissionDeniedSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ir para Ajustes'**
  String get billsNotificationPermissionDeniedSettings;

  /// No description provided for @billsNotificationPermissionDeniedDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get billsNotificationPermissionDeniedDismiss;

  /// No description provided for @shoppingListsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Listas de compras'**
  String get shoppingListsTitle;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Lista vazia. Adicione o que falta em casa.'**
  String get shoppingListEmpty;

  /// No description provided for @shoppingListAllDone.
  ///
  /// In pt, this message translates to:
  /// **'Tudo comprado 🎉'**
  String get shoppingListAllDone;

  /// No description provided for @shoppingListRegisterPurchase.
  ///
  /// In pt, this message translates to:
  /// **'registrar a compra'**
  String get shoppingListRegisterPurchase;

  /// No description provided for @shoppingListMarkAsBought.
  ///
  /// In pt, this message translates to:
  /// **'Marcar {item} como comprado'**
  String shoppingListMarkAsBought(String item);

  /// No description provided for @shoppingListUnmarkAsBought.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar {item} como comprado'**
  String shoppingListUnmarkAsBought(String item);

  /// No description provided for @shoppingListAddItemLabel.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar item'**
  String get shoppingListAddItemLabel;

  /// No description provided for @shoppingListAddItemHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 2kg de arroz'**
  String get shoppingListAddItemHint;

  /// No description provided for @shoppingListUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get shoppingListUndo;

  /// No description provided for @shoppingListEstimateWithUnknowns.
  ///
  /// In pt, this message translates to:
  /// **'{total} + {count} itens sem preço'**
  String shoppingListEstimateWithUnknowns(String total, int count);

  /// No description provided for @shoppingListEstimateWithOneUnknown.
  ///
  /// In pt, this message translates to:
  /// **'{total} + 1 item sem preço'**
  String shoppingListEstimateWithOneUnknown(String total);

  /// No description provided for @shoppingListEstimateExact.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa: {total}'**
  String shoppingListEstimateExact(String total);

  /// No description provided for @shoppingListItemQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Qtd: {quantity} {unit}'**
  String shoppingListItemQuantity(String quantity, String unit);

  /// No description provided for @shoppingListError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar lista de compras'**
  String get shoppingListError;

  /// No description provided for @shoppingListRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get shoppingListRetry;

  /// No description provided for @purchasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get purchasesTitle;

  /// No description provided for @purchaseNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Compra'**
  String get purchaseNew;

  /// No description provided for @pricesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Preços'**
  String get pricesTitle;

  /// No description provided for @pricesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem preços. Registre uma compra para começar.'**
  String get pricesEmpty;

  /// No description provided for @pricesFewData.
  ///
  /// In pt, this message translates to:
  /// **'poucas observações para concluir'**
  String get pricesFewData;

  /// No description provided for @pricesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'falha ao carregar histórico'**
  String get pricesLoadError;

  /// No description provided for @pricesRetry.
  ///
  /// In pt, this message translates to:
  /// **'tentar de novo'**
  String get pricesRetry;

  /// No description provided for @pricesRankingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ranking por estabelecimento'**
  String get pricesRankingTitle;

  /// No description provided for @storeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estabelecimento'**
  String get storeTitle;

  /// No description provided for @cheapestStore.
  ///
  /// In pt, this message translates to:
  /// **'Mais barato no {store}'**
  String cheapestStore(String store);

  /// No description provided for @notEnoughData.
  ///
  /// In pt, this message translates to:
  /// **'pouca informação'**
  String get notEnoughData;

  /// No description provided for @priceAverage.
  ///
  /// In pt, this message translates to:
  /// **'Costuma custar {amount}'**
  String priceAverage(String amount);

  /// No description provided for @priceAverageObservations.
  ///
  /// In pt, this message translates to:
  /// **'baseado em {count} observações'**
  String priceAverageObservations(int count);

  /// No description provided for @priceVariationAlert.
  ///
  /// In pt, this message translates to:
  /// **'Alerta de variação'**
  String get priceVariationAlert;

  /// No description provided for @priceVariationUp.
  ///
  /// In pt, this message translates to:
  /// **'Alta de {percent}% sobre a média de 30 dias'**
  String priceVariationUp(String percent);

  /// No description provided for @priceVariationDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixa de {percent}% sobre a média de 30 dias'**
  String priceVariationDown(String percent);

  /// No description provided for @purchaseTotalMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Divergência de {amount}. O sistema não ajusta automaticamente.'**
  String purchaseTotalMismatch(String amount);

  /// No description provided for @purchaseInvalidCnpj.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ inválido. Digite um CNPJ válido.'**
  String get purchaseInvalidCnpj;

  /// No description provided for @purchaseChartA11y.
  ///
  /// In pt, this message translates to:
  /// **'{amount} em média nos últimos 30 dias, menor valor {minAmount} no {store} em {date}'**
  String purchaseChartA11y(
    String amount,
    String minAmount,
    String store,
    String date,
  );

  /// No description provided for @ocrTitle.
  ///
  /// In pt, this message translates to:
  /// **'Leitor de Nota Fiscal'**
  String get ocrTitle;

  /// No description provided for @ocrCameraPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de câmera negada'**
  String get ocrCameraPermissionDenied;

  /// No description provided for @ocrCameraPermissionSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ir para Ajustes'**
  String get ocrCameraPermissionSettings;

  /// No description provided for @ocrFlashOn.
  ///
  /// In pt, this message translates to:
  /// **'Ligar flash'**
  String get ocrFlashOn;

  /// No description provided for @ocrFlashOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligar flash'**
  String get ocrFlashOff;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get ocrReviewTitle;

  /// No description provided for @ocrReviewSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get ocrReviewSave;

  /// No description provided for @ocrReviewAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get ocrReviewAdd;

  /// No description provided for @ocrReviewDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get ocrReviewDelete;

  /// No description provided for @ocrTotalMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Soma dos itens difere do total'**
  String get ocrTotalMismatch;

  /// No description provided for @ocrItemLowConfidence.
  ///
  /// In pt, this message translates to:
  /// **'Confira este item'**
  String get ocrItemLowConfidence;

  /// No description provided for @ocrGalleryOption.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get ocrGalleryOption;

  /// No description provided for @purchaseDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Compra'**
  String get purchaseDate;

  /// No description provided for @purchaseItemsSection.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get purchaseItemsSection;

  /// No description provided for @purchaseAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Item'**
  String get purchaseAddItem;

  /// No description provided for @purchaseNoStores.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum estabelecimento cadastrado. (Adicione um na tela de lojas)'**
  String get purchaseNoStores;

  /// No description provided for @purchaseLoadStoresError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar lojas: {error}'**
  String purchaseLoadStoresError(String error);

  /// No description provided for @purchaseProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get purchaseProductLabel;

  /// No description provided for @purchaseLoadProductsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar produtos'**
  String get purchaseLoadProductsError;

  /// No description provided for @purchaseQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get purchaseQuantityLabel;

  /// No description provided for @purchaseTotalPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço Total'**
  String get purchaseTotalPriceLabel;

  /// No description provided for @purchaseDiscountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto Total'**
  String get purchaseDiscountLabel;

  /// No description provided for @purchaseDeclaredTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total Declarado (Cupom)'**
  String get purchaseDeclaredTotalLabel;

  /// No description provided for @purchaseItemsSum.
  ///
  /// In pt, this message translates to:
  /// **'Soma dos Itens: {amount}'**
  String purchaseItemsSum(String amount);

  /// No description provided for @purchaseFormError.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos corretamente'**
  String get purchaseFormError;

  /// No description provided for @priceTrendUp.
  ///
  /// In pt, this message translates to:
  /// **'Alta de preço no período'**
  String get priceTrendUp;

  /// No description provided for @priceTrendDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixa de preço no período'**
  String get priceTrendDown;

  /// No description provided for @priceHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preços'**
  String get priceHistoryTitle;

  /// No description provided for @checklistTitle.
  ///
  /// In pt, this message translates to:
  /// **'Checklist da casa'**
  String get checklistTitle;

  /// No description provided for @checklistEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item no checklist.'**
  String get checklistEmpty;

  /// No description provided for @checklistCategoryAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cômodos'**
  String get checklistCategoryAll;

  /// No description provided for @checklistSendToShoppingList.
  ///
  /// In pt, this message translates to:
  /// **'Enviar para lista de compras'**
  String get checklistSendToShoppingList;

  /// No description provided for @stockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estoque doméstico'**
  String get stockTitle;

  /// No description provided for @stockEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto no estoque.'**
  String get stockEmpty;

  /// No description provided for @stockLowAlert.
  ///
  /// In pt, this message translates to:
  /// **'Está acabando'**
  String get stockLowAlert;

  /// No description provided for @stockEstimateNotice.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa de consumo'**
  String get stockEstimateNotice;

  /// No description provided for @searchGlobalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Busca'**
  String get searchGlobalTitle;

  /// No description provided for @searchGlobalHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar em todo o app...'**
  String get searchGlobalHint;

  /// No description provided for @searchGlobalNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado.'**
  String get searchGlobalNoResults;

  /// No description provided for @economyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo Economia'**
  String get economyTitle;

  /// No description provided for @economyMetaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meta de economia'**
  String get economyMetaTitle;

  /// No description provided for @economyProgressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da meta'**
  String get economyProgressLabel;

  /// No description provided for @widgetsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Widgets'**
  String get widgetsTitle;

  /// No description provided for @backupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup e Exportação'**
  String get backupTitle;

  /// No description provided for @backupExportSection.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Dados'**
  String get backupExportSection;

  /// No description provided for @backupImportSection.
  ///
  /// In pt, this message translates to:
  /// **'Importar Dados'**
  String get backupImportSection;

  /// No description provided for @backupClearAllSection.
  ///
  /// In pt, this message translates to:
  /// **'Apagar Tudo'**
  String get backupClearAllSection;

  /// No description provided for @backupCloudSection.
  ///
  /// In pt, this message translates to:
  /// **'Backup em Nuvem'**
  String get backupCloudSection;

  /// No description provided for @mascotDefaultName.
  ///
  /// In pt, this message translates to:
  /// **'Momo'**
  String get mascotDefaultName;

  /// No description provided for @mascotCustomizeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar Mascote'**
  String get mascotCustomizeTitle;

  /// No description provided for @mascotCustomizeSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar e aplicar'**
  String get mascotCustomizeSave;

  /// No description provided for @mascotCustomizeCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get mascotCustomizeCancel;

  /// No description provided for @mascotCustomizeRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get mascotCustomizeRetry;

  /// No description provided for @mascotCustomizeNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da mascote'**
  String get mascotCustomizeNameLabel;

  /// No description provided for @mascotCustomizeNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Momo'**
  String get mascotCustomizeNameHint;

  /// No description provided for @mascotCustomizePreview.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização'**
  String get mascotCustomizePreview;

  /// No description provided for @mascotCustomizeAnimalSection.
  ///
  /// In pt, this message translates to:
  /// **'Animal'**
  String get mascotCustomizeAnimalSection;

  /// No description provided for @mascotCustomizePaletteSection.
  ///
  /// In pt, this message translates to:
  /// **'Paleta de cores'**
  String get mascotCustomizePaletteSection;

  /// No description provided for @mascotCustomizeAccessorySection.
  ///
  /// In pt, this message translates to:
  /// **'Acessório'**
  String get mascotCustomizeAccessorySection;

  /// No description provided for @mascotAnimalCat.
  ///
  /// In pt, this message translates to:
  /// **'Gato'**
  String get mascotAnimalCat;

  /// No description provided for @mascotAnimalDog.
  ///
  /// In pt, this message translates to:
  /// **'Cachorro'**
  String get mascotAnimalDog;

  /// No description provided for @mascotAnimalBunny.
  ///
  /// In pt, this message translates to:
  /// **'Coelho'**
  String get mascotAnimalBunny;

  /// No description provided for @mascotPaletteRose.
  ///
  /// In pt, this message translates to:
  /// **'Rose'**
  String get mascotPaletteRose;

  /// No description provided for @mascotPaletteLavender.
  ///
  /// In pt, this message translates to:
  /// **'Lavender'**
  String get mascotPaletteLavender;

  /// No description provided for @mascotPaletteMint.
  ///
  /// In pt, this message translates to:
  /// **'Mint'**
  String get mascotPaletteMint;

  /// No description provided for @mascotAccessoryNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get mascotAccessoryNone;

  /// No description provided for @mascotAccessoryBow.
  ///
  /// In pt, this message translates to:
  /// **'Lacinho'**
  String get mascotAccessoryBow;

  /// No description provided for @mascotAccessoryCollar.
  ///
  /// In pt, this message translates to:
  /// **'Coleira'**
  String get mascotAccessoryCollar;

  /// No description provided for @mascotAccessoryScarf.
  ///
  /// In pt, this message translates to:
  /// **'Lenço'**
  String get mascotAccessoryScarf;

  /// No description provided for @mascotSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Personalização salva com carinho!'**
  String get mascotSaveSuccess;

  /// No description provided for @mascotSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar a personalização. Tente de novo.'**
  String get mascotSaveError;

  /// No description provided for @settingsMascotOption.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar Momo'**
  String get settingsMascotOption;

  /// No description provided for @settingsMascotSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o animal, cores e acessórios da sua companheira'**
  String get settingsMascotSubtitle;

  /// No description provided for @settingsTutorialOption.
  ///
  /// In pt, this message translates to:
  /// **'Ver tutorial com a Momo'**
  String get settingsTutorialOption;

  /// No description provided for @settingsTutorialSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Relembre o funcionamento do app com a mascote'**
  String get settingsTutorialSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular introdução'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingStart;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In pt, this message translates to:
  /// **'Oi! Eu sou a Momo 💕'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Description.
  ///
  /// In pt, this message translates to:
  /// **'Estou aqui para cuidar do seu cantinho com você e tornar tudo mais leve!'**
  String get onboardingStep1Description;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In pt, this message translates to:
  /// **'Aqui a gente cuida do dinheirinho juntas'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Description.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe seus gastos, registre comprinhas e mantenha o orçamento sem sustos no fim do mês.'**
  String get onboardingStep2Description;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In pt, this message translates to:
  /// **'E também das comprinhas!'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Description.
  ///
  /// In pt, this message translates to:
  /// **'Monte sua listinha de compras no mercado e escaneie a nota fiscal num piscar de olhos.'**
  String get onboardingStep3Description;

  /// No description provided for @onboardingStep4Title.
  ///
  /// In pt, this message translates to:
  /// **'Não esquece das tarefinhas do dia'**
  String get onboardingStep4Title;

  /// No description provided for @onboardingStep4Description.
  ///
  /// In pt, this message translates to:
  /// **'Organize tarefas de limpeza, cuidados com a casa e rotinas para manter seu lar acolhedor.'**
  String get onboardingStep4Description;

  /// No description provided for @onboardingStep5Title.
  ///
  /// In pt, this message translates to:
  /// **'Eu te aviso quando algo precisa de atenção'**
  String get onboardingStep5Title;

  /// No description provided for @onboardingStep5Description.
  ///
  /// In pt, this message translates to:
  /// **'Fique tranquila com os lembretes de contas a vencer para nunca mais pagar juros ou multas.'**
  String get onboardingStep5Description;

  /// No description provided for @onboardingStep6Title.
  ///
  /// In pt, this message translates to:
  /// **'Pode personalizar meu visual quando quiser!'**
  String get onboardingStep6Title;

  /// No description provided for @onboardingStep6Description.
  ///
  /// In pt, this message translates to:
  /// **'Você pode trocar meu animalzinho, colocar acessórios e escolher as cores que mais combinam com você.'**
  String get onboardingStep6Description;

  /// No description provided for @onboardingCustomizePrompt.
  ///
  /// In pt, this message translates to:
  /// **'Quer personalizar meu visual agora?'**
  String get onboardingCustomizePrompt;

  /// No description provided for @onboardingCustomizeButton.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar agora'**
  String get onboardingCustomizeButton;

  /// No description provided for @dashboardMonthBalanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu dinheirinho este mês'**
  String get dashboardMonthBalanceTitle;

  /// No description provided for @dashboardDueBillsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas que precisam de carinho'**
  String get dashboardDueBillsTitle;

  /// No description provided for @dashboardTodayTasksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tarefinhas do dia'**
  String get dashboardTodayTasksTitle;

  /// No description provided for @momoGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Oi! Eu sou a Momo 💕'**
  String get momoGreeting;

  /// No description provided for @momoShoppingAllBought.
  ///
  /// In pt, this message translates to:
  /// **'Tudo comprado! Quer que eu anote essa comprinha?'**
  String get momoShoppingAllBought;

  /// No description provided for @momoDayOff.
  ///
  /// In pt, this message translates to:
  /// **'Hoje pode ser um dia de folga ☕'**
  String get momoDayOff;

  /// No description provided for @momoEmptyExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Momo está pensativa — nenhuma despesa registrada ainda'**
  String get momoEmptyExpenses;

  /// No description provided for @momoEmptyShoppingList.
  ///
  /// In pt, this message translates to:
  /// **'Momo pronta para as compras — nenhuma listinha criada ainda'**
  String get momoEmptyShoppingList;

  /// No description provided for @momoEmptyShoppingListCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Momo está feliz porque você completou a lista'**
  String get momoEmptyShoppingListCompleted;

  /// No description provided for @momoEmptyTasks.
  ///
  /// In pt, this message translates to:
  /// **'Momo relaxada — nenhuma tarefinha para hoje'**
  String get momoEmptyTasks;

  /// No description provided for @celebrationShoppingCompletedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns!'**
  String get celebrationShoppingCompletedTitle;

  /// No description provided for @celebrationShoppingCompletedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tudo comprado! Sua lista está completa 💕'**
  String get celebrationShoppingCompletedMessage;

  /// No description provided for @celebrationTasksCompletedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pronto!'**
  String get celebrationTasksCompletedTitle;

  /// No description provided for @celebrationTasksCompletedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você concluiu todas as tarefinhas do dia! Descanse bastante 💕'**
  String get celebrationTasksCompletedMessage;

  /// No description provided for @mascotSemanticsNeutral.
  ///
  /// In pt, this message translates to:
  /// **'Momo está presente acompanhando você'**
  String get mascotSemanticsNeutral;

  /// No description provided for @mascotSemanticsHappy.
  ///
  /// In pt, this message translates to:
  /// **'Momo está feliz'**
  String get mascotSemanticsHappy;

  /// No description provided for @mascotSemanticsWorried.
  ///
  /// In pt, this message translates to:
  /// **'Momo está preocupada com as continhas'**
  String get mascotSemanticsWorried;

  /// No description provided for @mascotSemanticsSleepy.
  ///
  /// In pt, this message translates to:
  /// **'Momo está com soninho'**
  String get mascotSemanticsSleepy;

  /// No description provided for @mascotSemanticsPointing.
  ///
  /// In pt, this message translates to:
  /// **'Momo está apontando uma dica importante'**
  String get mascotSemanticsPointing;

  /// No description provided for @mascotSemanticsWaving.
  ///
  /// In pt, this message translates to:
  /// **'Momo está acenando com carinho para você'**
  String get mascotSemanticsWaving;

  /// No description provided for @mascotSemanticsThinking.
  ///
  /// In pt, this message translates to:
  /// **'Momo está pensativa'**
  String get mascotSemanticsThinking;

  /// No description provided for @mascotSemanticsRelaxed.
  ///
  /// In pt, this message translates to:
  /// **'Momo está relaxada e tranquila'**
  String get mascotSemanticsRelaxed;

  /// No description provided for @mascotSemanticsShopping.
  ///
  /// In pt, this message translates to:
  /// **'Momo está pronta para as compras'**
  String get mascotSemanticsShopping;

  /// No description provided for @mascotSemanticsBudget.
  ///
  /// In pt, this message translates to:
  /// **'Momo está de olho no orçamento do mês'**
  String get mascotSemanticsBudget;

  /// No description provided for @mascotSemanticsPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Ilustração da mascote Momo'**
  String get mascotSemanticsPlaceholder;

  /// No description provided for @taskPresetsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões para a casa'**
  String get taskPresetsTitle;

  /// No description provided for @taskPresetsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ideias de tarefas comuns com frequências recomendadas'**
  String get taskPresetsSubtitle;

  /// No description provided for @taskPresetsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar sugestões...'**
  String get taskPresetsSearchHint;

  /// No description provided for @taskPresetsEmptySearch.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sugestão encontrada para \"{query}\"'**
  String taskPresetsEmptySearch(String query);

  /// No description provided for @taskPresetsCustomTaskCta.
  ///
  /// In pt, this message translates to:
  /// **'Criar tarefa personalizada'**
  String get taskPresetsCustomTaskCta;

  /// No description provided for @taskPresetsAreaKitchen.
  ///
  /// In pt, this message translates to:
  /// **'Cozinha'**
  String get taskPresetsAreaKitchen;

  /// No description provided for @taskPresetsAreaBathroom.
  ///
  /// In pt, this message translates to:
  /// **'Banheiro'**
  String get taskPresetsAreaBathroom;

  /// No description provided for @taskPresetsAreaBedroom.
  ///
  /// In pt, this message translates to:
  /// **'Quarto'**
  String get taskPresetsAreaBedroom;

  /// No description provided for @taskPresetsAreaLaundry.
  ///
  /// In pt, this message translates to:
  /// **'Roupas'**
  String get taskPresetsAreaLaundry;

  /// No description provided for @taskPresetsAreaGeneralCleaning.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza geral'**
  String get taskPresetsAreaGeneralCleaning;

  /// No description provided for @taskPresetsAreaShopping.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get taskPresetsAreaShopping;

  /// No description provided for @taskPresetsAlreadyInRoutine.
  ///
  /// In pt, this message translates to:
  /// **'Já na sua rotina'**
  String get taskPresetsAlreadyInRoutine;

  /// No description provided for @taskPresetsDuplicateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa já existe na rotina'**
  String get taskPresetsDuplicateTitle;

  /// No description provided for @taskPresetsDuplicateMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você já tem uma tarefa ativa para esta predefinição. Deseja adicionar outra mesmo assim?'**
  String get taskPresetsDuplicateMessage;

  /// No description provided for @taskPresetsDuplicateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar mesmo assim'**
  String get taskPresetsDuplicateConfirm;

  /// No description provided for @taskPresetsDuplicateCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get taskPresetsDuplicateCancel;

  /// No description provided for @taskPresetsAddSelected.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar {count, plural, one{1 tarefa} other{{count} tarefas}}'**
  String taskPresetsAddSelected(int count);

  /// No description provided for @taskPresetsSelectedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 selecionada} other{{count} selecionadas}}'**
  String taskPresetsSelectedCount(int count);

  /// No description provided for @taskPresetsBatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Datas de início'**
  String get taskPresetsBatchTitle;

  /// No description provided for @taskPresetsBatchConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar rotina'**
  String get taskPresetsBatchConfirm;

  /// No description provided for @taskPresetsBatchUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get taskPresetsBatchUndo;

  /// No description provided for @taskPresetsBatchSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 tarefa adicionada!} other{{count} tarefas adicionadas!}}'**
  String taskPresetsBatchSuccess(int count);

  /// No description provided for @taskPresetsBatchStartDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Início de {task}'**
  String taskPresetsBatchStartDateLabel(String task);

  /// No description provided for @taskPresetsEmptyStatePrompt.
  ///
  /// In pt, this message translates to:
  /// **'Que tal ver sugestões para a rotina da sua casa?'**
  String get taskPresetsEmptyStatePrompt;

  /// No description provided for @taskPresetsEmptyStateButton.
  ///
  /// In pt, this message translates to:
  /// **'Ver sugestões para a casa'**
  String get taskPresetsEmptyStateButton;

  /// No description provided for @onboardingRoutineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Monte sua rotina da casa'**
  String get onboardingRoutineTitle;

  /// No description provided for @onboardingRoutineDescription.
  ///
  /// In pt, this message translates to:
  /// **'Escolha tarefas comuns para começar sua rotina sem complicação. Você pode mudar tudo depois!'**
  String get onboardingRoutineDescription;

  /// No description provided for @onboardingRoutineSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular este passo'**
  String get onboardingRoutineSkip;

  /// No description provided for @householdTitle.
  ///
  /// In pt, this message translates to:
  /// **'Casa compartilhada'**
  String get householdTitle;

  /// No description provided for @householdSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronize tarefas e finanças em rede local'**
  String get householdSubtitle;

  /// No description provided for @householdEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe a sua casa'**
  String get householdEmptyTitle;

  /// No description provided for @householdEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Sincronize com quem mora com você sem intermediários, sem criar conta e com segurança de ponta a ponta na rede local.'**
  String get householdEmptyDescription;

  /// No description provided for @householdCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar casa'**
  String get householdCreateButton;

  /// No description provided for @householdJoinButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar numa casa'**
  String get householdJoinButton;

  /// No description provided for @householdSyncNowButton.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar agora'**
  String get householdSyncNowButton;

  /// No description provided for @householdGenerateBundleButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar pacote'**
  String get householdGenerateBundleButton;

  /// No description provided for @householdInviteButton.
  ///
  /// In pt, this message translates to:
  /// **'Convidar aparelho'**
  String get householdInviteButton;

  /// No description provided for @householdOnlyThisDevice.
  ///
  /// In pt, this message translates to:
  /// **'Mudanças só neste aparelho'**
  String get householdOnlyThisDevice;

  /// No description provided for @householdAllSynced.
  ///
  /// In pt, this message translates to:
  /// **'Tudo sincronizado'**
  String get householdAllSynced;

  /// No description provided for @householdSyncing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando...'**
  String get householdSyncing;

  /// No description provided for @householdLastSync.
  ///
  /// In pt, this message translates to:
  /// **'Última sincronização: {time}'**
  String householdLastSync(String time);

  /// No description provided for @householdMembersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aparelhos na casa'**
  String get householdMembersTitle;

  /// No description provided for @householdAreasTitle.
  ///
  /// In pt, this message translates to:
  /// **'Áreas compartilhadas'**
  String get householdAreasTitle;

  /// No description provided for @householdAreaHome.
  ///
  /// In pt, this message translates to:
  /// **'Casa (Tarefas, Estoque, Receitas)'**
  String get householdAreaHome;

  /// No description provided for @householdAreaFinance.
  ///
  /// In pt, this message translates to:
  /// **'Finanças (Despesas, Contas, Preços)'**
  String get householdAreaFinance;

  /// No description provided for @householdPairingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conectar aparelho'**
  String get householdPairingTitle;

  /// No description provided for @householdPairingScanPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o QR code no outro aparelho'**
  String get householdPairingScanPrompt;

  /// No description provided for @householdPairingShowPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Mostre este QR code no aparelho que deseja conectar'**
  String get householdPairingShowPrompt;

  /// No description provided for @householdPairingCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de confirmação: {code}'**
  String householdPairingCodeLabel(String code);

  /// No description provided for @householdLeaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Sair da casa'**
  String get householdLeaveButton;

  /// No description provided for @householdLeaveKeepData.
  ///
  /// In pt, this message translates to:
  /// **'Manter uma cópia local'**
  String get householdLeaveKeepData;

  /// No description provided for @householdLeaveWipeData.
  ///
  /// In pt, this message translates to:
  /// **'Apagar dados compartilhados'**
  String get householdLeaveWipeData;

  /// No description provided for @householdRemoveMemberTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover aparelho'**
  String get householdRemoveMemberTitle;

  /// No description provided for @householdRemoveMemberConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get householdRemoveMemberConfirm;

  /// No description provided for @householdRemoveMemberWarning.
  ///
  /// In pt, this message translates to:
  /// **'O aparelho removido perderá o acesso e as futuras alterações não serão mais sincronizadas com ele.'**
  String get householdRemoveMemberWarning;

  /// No description provided for @householdErrorIncompatibleProtocol.
  ///
  /// In pt, this message translates to:
  /// **'Aparelho usa versão incompatível do protocolo de sincronização.'**
  String get householdErrorIncompatibleProtocol;

  /// No description provided for @householdErrorInviteExpired.
  ///
  /// In pt, this message translates to:
  /// **'O convite expirou. Gere um novo convite para parear.'**
  String get householdErrorInviteExpired;

  /// No description provided for @householdErrorNoNetwork.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aparelho encontrado na rede local. Verifique se ambos estão no mesmo Wi-Fi.'**
  String get householdErrorNoNetwork;

  /// No description provided for @customizeDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar início'**
  String get customizeDashboardTitle;

  /// No description provided for @customizeDashboardAction.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar início'**
  String get customizeDashboardAction;

  /// No description provided for @customizeDashboardAddCards.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao painel'**
  String get customizeDashboardAddCards;

  /// No description provided for @customizeDashboardEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item visível no painel'**
  String get customizeDashboardEmptyTitle;

  /// No description provided for @customizeDashboardEmptyAction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar itens ao painel'**
  String get customizeDashboardEmptyAction;

  /// No description provided for @customizeDashboardRestoreDefault.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get customizeDashboardRestoreDefault;

  /// No description provided for @customizeDashboardMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get customizeDashboardMoveUp;

  /// No description provided for @customizeDashboardMoveDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get customizeDashboardMoveDown;

  /// No description provided for @customizeDashboardHide.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar'**
  String get customizeDashboardHide;

  /// No description provided for @customizeDashboardAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get customizeDashboardAdd;

  /// No description provided for @dashboardCardMascotGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Saudação da Momo'**
  String get dashboardCardMascotGreeting;

  /// No description provided for @dashboardCardMonthBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do Mês'**
  String get dashboardCardMonthBalance;

  /// No description provided for @dashboardCardDueBills.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Vencer'**
  String get dashboardCardDueBills;

  /// No description provided for @dashboardCardTodayTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas de Hoje'**
  String get dashboardCardTodayTasks;

  /// No description provided for @dashboardCardShoppingList.
  ///
  /// In pt, this message translates to:
  /// **'Lista de Compras'**
  String get dashboardCardShoppingList;

  /// No description provided for @dashboardCardStockAlert.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Doméstico'**
  String get dashboardCardStockAlert;

  /// No description provided for @dashboardCardFirstHomeChecklist.
  ///
  /// In pt, this message translates to:
  /// **'Checklist da Primeira Casa'**
  String get dashboardCardFirstHomeChecklist;

  /// No description provided for @dashboardCardEconomyGoal.
  ///
  /// In pt, this message translates to:
  /// **'Modo Economia'**
  String get dashboardCardEconomyGoal;

  /// No description provided for @dashboardCardFavoriteRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Favoritas'**
  String get dashboardCardFavoriteRecipes;

  /// No description provided for @settingsRetentionNotificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes gentis da Momo'**
  String get settingsRetentionNotificationsTitle;

  /// No description provided for @settingsRetentionNotificationsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisar em intervalos espaçados se você ficar dias sem abrir o app'**
  String get settingsRetentionNotificationsSubtitle;

  /// No description provided for @retentionNotificationTitle.
  ///
  /// In pt, this message translates to:
  /// **'A Momo sentiu sua falta!'**
  String get retentionNotificationTitle;

  /// No description provided for @retentionNotificationBody.
  ///
  /// In pt, this message translates to:
  /// **'Faz {days} dias que não organizamos a casa juntos. Que tal conferir suas tarefas e contas?'**
  String retentionNotificationBody(int days);

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get commonDone;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navShopping.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get navShopping;

  /// No description provided for @navTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// No description provided for @navBills.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get navBills;

  /// No description provided for @navExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get navExpenses;

  /// No description provided for @navScanReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Escanear Nota Fiscal'**
  String get navScanReceipt;

  /// No description provided for @pageNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada'**
  String get pageNotFound;

  /// No description provided for @dashboardSearchTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Busca global'**
  String get dashboardSearchTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @dashboardEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Personalize seu painel inicial adicionando os módulos que desejar.'**
  String get dashboardEmptyDescription;

  /// No description provided for @mascotGreetingNamed.
  ///
  /// In pt, this message translates to:
  /// **'Oi! Eu sou a {name} 💕'**
  String mascotGreetingNamed(String name);

  /// No description provided for @mascotGreetingSubtitleDefault.
  ///
  /// In pt, this message translates to:
  /// **'Estou aqui para cuidar do seu cantinho com você!'**
  String get mascotGreetingSubtitleDefault;

  /// No description provided for @mascotGreetingSubtitleOverBudget.
  ///
  /// In pt, this message translates to:
  /// **'Atenção com as continhas este mês! Mas estamos juntas nisso 💕'**
  String get mascotGreetingSubtitleOverBudget;

  /// No description provided for @mascotGreetingSubtitleNearBudget.
  ///
  /// In pt, this message translates to:
  /// **'Quase no limite do orçamento! Vamos cuidar com carinho dos gastos 💕'**
  String get mascotGreetingSubtitleNearBudget;

  /// No description provided for @mascotGreetingSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Mascote {name}: {title}. {subtitle}'**
  String mascotGreetingSemantics(String name, String title, String subtitle);

  /// No description provided for @recoveryResetConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recomeçar do zero?'**
  String get recoveryResetConfirmTitle;

  /// No description provided for @recoveryResetConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados locais existentes serão permanentemente apagados.'**
  String get recoveryResetConfirmBody;

  /// No description provided for @recoveryResetFinalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação definitiva'**
  String get recoveryResetFinalTitle;

  /// No description provided for @recoveryResetFinalBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação é irreversível. Tem certeza absoluta que deseja apagar todos os dados e recomeçar?'**
  String get recoveryResetFinalBody;

  /// No description provided for @recoveryResetFinalConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar e apagar'**
  String get recoveryResetFinalConfirm;

  /// No description provided for @recoveryKeyUnavailableAppBar.
  ///
  /// In pt, this message translates to:
  /// **'Chave do banco inacessível'**
  String get recoveryKeyUnavailableAppBar;

  /// No description provided for @recoverySecurityFailureAppBar.
  ///
  /// In pt, this message translates to:
  /// **'Falha na segurança do banco'**
  String get recoverySecurityFailureAppBar;

  /// No description provided for @recoveryKeyUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Chave de segurança inacessível'**
  String get recoveryKeyUnavailableTitle;

  /// No description provided for @recoveryConversionFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conversão de segurança falhou'**
  String get recoveryConversionFailedTitle;

  /// No description provided for @recoveryKeyUnavailableBody.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível acessar a chave de segurança no dispositivo. Para proteger seus dados, nenhum banco vazio foi criado.\n\nVocê pode restaurar um backup anterior ou recomeçar do zero.'**
  String get recoveryKeyUnavailableBody;

  /// No description provided for @recoveryConversionFailedBody.
  ///
  /// In pt, this message translates to:
  /// **'A conversão do banco existente para o formato cifrado falhou, mas seus dados continuam intactos no banco original.\n\nRecomendamos exportar um backup antes de prosseguir.'**
  String get recoveryConversionFailedBody;

  /// No description provided for @recoveryImportBackup.
  ///
  /// In pt, this message translates to:
  /// **'Importar backup'**
  String get recoveryImportBackup;

  /// No description provided for @recoveryStartFromScratch.
  ///
  /// In pt, this message translates to:
  /// **'Recomeçar do zero'**
  String get recoveryStartFromScratch;

  /// No description provided for @recoveryExportBackup.
  ///
  /// In pt, this message translates to:
  /// **'Exportar backup'**
  String get recoveryExportBackup;

  /// No description provided for @recoveryContinuePlaintextSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Continuar no formato original'**
  String get recoveryContinuePlaintextSemantics;

  /// No description provided for @celebrationDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns!'**
  String get celebrationDefaultTitle;

  /// No description provided for @celebrationDefaultMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você concluiu tudo com sucesso! 💕'**
  String get celebrationDefaultMessage;

  /// No description provided for @celebrationMascotSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Momo alegre celebrando sua conquista'**
  String get celebrationMascotSemantics;

  /// No description provided for @mascotNameFieldSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Campo para alterar o nome da mascote'**
  String get mascotNameFieldSemantics;

  /// No description provided for @mascotNameBlankHelper.
  ///
  /// In pt, this message translates to:
  /// **'Se deixar em branco, usaremos \"{name}\" 💕'**
  String mascotNameBlankHelper(String name);

  /// No description provided for @mascotPreviewSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização da mascote {name} na paleta {palette}'**
  String mascotPreviewSemantics(String name, String palette);

  /// No description provided for @splashInitError.
  ///
  /// In pt, this message translates to:
  /// **'Ops! Ocorreu uma instabilidade na inicialização.'**
  String get splashInitError;

  /// No description provided for @onboardingOpenSourceBadge.
  ///
  /// In pt, this message translates to:
  /// **'Código aberto, sem anúncios e com dados salvos apenas no seu aparelho'**
  String get onboardingOpenSourceBadge;

  /// No description provided for @onboardingFirstHomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Está montando sua casa nova?'**
  String get onboardingFirstHomeTitle;

  /// No description provided for @onboardingFirstHomeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Se você acabou de se mudar ou está organizando seu cantinho pela primeira vez, posso ativar um checklist especial com itens essenciais no seu início!'**
  String get onboardingFirstHomeDescription;

  /// No description provided for @onboardingFirstHomeEnable.
  ///
  /// In pt, this message translates to:
  /// **'Sim, ativar checklist da primeira casa'**
  String get onboardingFirstHomeEnable;

  /// No description provided for @onboardingFirstHomeSkip.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho tudo / Pular'**
  String get onboardingFirstHomeSkip;

  /// No description provided for @onboardingPageIndicatorSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Página {current} de {total}'**
  String onboardingPageIndicatorSemantics(int current, int total);

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o My Sweet Home'**
  String get aboutTitle;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão '**
  String get aboutVersionLabel;

  /// No description provided for @aboutUpToDate.
  ///
  /// In pt, this message translates to:
  /// **'Você já está na versão mais recente.'**
  String get aboutUpToDate;

  /// No description provided for @aboutUpdateCheckFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar atualizações no momento.'**
  String get aboutUpdateCheckFailed;

  /// No description provided for @aboutLicensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Licenças de código aberto'**
  String get aboutLicensesTitle;

  /// No description provided for @aboutLicensesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Licenças de pacotes e dependências'**
  String get aboutLicensesSubtitle;

  /// No description provided for @aboutAttributionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atribuições'**
  String get aboutAttributionsTitle;

  /// No description provided for @aboutAttributionsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atribuições de ativos e terceiros'**
  String get aboutAttributionsSubtitle;

  /// No description provided for @aboutGithubTitle.
  ///
  /// In pt, this message translates to:
  /// **'Código-fonte no GitHub'**
  String get aboutGithubTitle;

  /// No description provided for @aboutGithubCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link do GitHub copiado para a área de transferência.'**
  String get aboutGithubCopied;

  /// No description provided for @aboutDocsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Documentação e privacidade'**
  String get aboutDocsTitle;

  /// No description provided for @aboutDocsCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link da documentação copiado para a área de transferência.'**
  String get aboutDocsCopied;

  /// No description provided for @aboutCheckUpdatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verificar atualizações'**
  String get aboutCheckUpdatesTitle;

  /// No description provided for @aboutCheckUpdatesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscar novas versões na loja de aplicativos'**
  String get aboutCheckUpdatesSubtitle;

  /// No description provided for @aboutCheckUpdatesPlayStoreOnly.
  ///
  /// In pt, this message translates to:
  /// **'Disponível apenas para instalações feitas pela Google Play'**
  String get aboutCheckUpdatesPlayStoreOnly;

  /// No description provided for @aboutAttributionsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar atribuições: {error}'**
  String aboutAttributionsError(String error);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência e Experiência'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsMascotShortSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Animal, paleta de cor e acessório'**
  String get settingsMascotShortSubtitle;

  /// No description provided for @settingsVisualEffectsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Efeitos visuais e partículas'**
  String get settingsVisualEffectsTitle;

  /// No description provided for @settingsVisualEffectsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Partículas, confetes e animações contínuas'**
  String get settingsVisualEffectsSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do aplicativo'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático (sistema)'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSystemSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Segue o idioma configurado no aparelho'**
  String get settingsLanguageSystemSubtitle;

  /// No description provided for @settingsOcrFormatTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelo de nota fiscal (OCR)'**
  String get settingsOcrFormatTitle;

  /// No description provided for @settingsOcrFormatAuto.
  ///
  /// In pt, this message translates to:
  /// **'Automático (melhor modelo)'**
  String get settingsOcrFormatAuto;

  /// No description provided for @settingsOcrFormatAutoSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona automaticamente o formato com maior pontuação'**
  String get settingsOcrFormatAutoSubtitle;

  /// No description provided for @settingsSectionModules.
  ///
  /// In pt, this message translates to:
  /// **'Sua Casa e Módulos'**
  String get settingsSectionModules;

  /// No description provided for @settingsRecipesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Livro de receitas e ingredientes'**
  String get settingsRecipesSubtitle;

  /// No description provided for @settingsStockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get settingsStockTitle;

  /// No description provided for @settingsStockSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Despensa e itens essenciais'**
  String get settingsStockSubtitle;

  /// No description provided for @settingsEconomySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas e metas de economia'**
  String get settingsEconomySubtitle;

  /// No description provided for @settingsChecklistTitle.
  ///
  /// In pt, this message translates to:
  /// **'Checklist da 1ª Casa'**
  String get settingsChecklistTitle;

  /// No description provided for @settingsChecklistSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Itens essenciais para a casa nova'**
  String get settingsChecklistSubtitle;

  /// No description provided for @settingsSuggestionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões de Manutenção'**
  String get settingsSuggestionsTitle;

  /// No description provided for @settingsSuggestionsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo de tarefas sugeridas para o lar'**
  String get settingsSuggestionsSubtitle;

  /// No description provided for @settingsProductsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos e Sinônimos'**
  String get settingsProductsTitle;

  /// No description provided for @settingsProductsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar catálogo de produtos'**
  String get settingsProductsSubtitle;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade, Segurança e Dados'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsDeleteReceiptPhotoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar foto do cupom após leitura'**
  String get settingsDeleteReceiptPhotoTitle;

  /// No description provided for @settingsDeleteReceiptPhotoSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir arquivo de imagem após processamento do OCR'**
  String get settingsDeleteReceiptPhotoSubtitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar, importar e gerenciar dados'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e Sobre'**
  String get settingsSectionHelp;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informações sobre o aplicativo'**
  String get settingsAboutSubtitle;

  /// No description provided for @backupMenuExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Backup'**
  String get backupMenuExportTitle;

  /// No description provided for @backupMenuExportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gere um arquivo criptografado com seus dados'**
  String get backupMenuExportSubtitle;

  /// No description provided for @backupMenuImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar Backup'**
  String get backupMenuImportTitle;

  /// No description provided for @backupMenuImportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar ou mesclar dados de um arquivo de backup'**
  String get backupMenuImportSubtitle;

  /// No description provided for @backupMenuWipeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir permanentemente todos os dados armazenados'**
  String get backupMenuWipeSubtitle;

  /// No description provided for @backupExportShareText.
  ///
  /// In pt, this message translates to:
  /// **'Backup criptografado My Sweet Home'**
  String get backupExportShareText;

  /// No description provided for @backupExportEncryptedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Dados Criptografados'**
  String get backupExportEncryptedTitle;

  /// No description provided for @backupExportEncryptedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gere um arquivo de backup seguro de todos os seus dados e fotos para salvar localmente ou compartilhar.'**
  String get backupExportEncryptedSubtitle;

  /// No description provided for @backupExportError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar backup: {error}'**
  String backupExportError(String error);

  /// No description provided for @backupExportSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Backup gerado e exportado com sucesso!'**
  String get backupExportSuccess;

  /// No description provided for @backupExportCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar e Exportar Backup'**
  String get backupExportCreateButton;

  /// No description provided for @backupStageCollecting.
  ///
  /// In pt, this message translates to:
  /// **'Coletando dados do aplicativo...'**
  String get backupStageCollecting;

  /// No description provided for @backupStageEncrypting.
  ///
  /// In pt, this message translates to:
  /// **'Criptografando com AES-256 e Argon2id...'**
  String get backupStageEncrypting;

  /// No description provided for @backupStageWriting.
  ///
  /// In pt, this message translates to:
  /// **'Finalizando arquivo de backup...'**
  String get backupStageWriting;

  /// No description provided for @backupStageDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído!'**
  String get backupStageDone;

  /// No description provided for @backupEncryptedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup Criptografado'**
  String get backupEncryptedTitle;

  /// No description provided for @backupWarningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Importante (RN-234)'**
  String get backupWarningTitle;

  /// No description provided for @backupWarningLostPassword.
  ///
  /// In pt, this message translates to:
  /// **'Se você perder a senha, o backup é perdido.'**
  String get backupWarningLostPassword;

  /// No description provided for @backupWarningNoRecovery.
  ///
  /// In pt, this message translates to:
  /// **'O aplicativo não salva sua senha nem consegue ler o backup sem ela. Não há opção de recuperação.'**
  String get backupWarningNoRecovery;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha do Backup *'**
  String get backupPasswordLabel;

  /// No description provided for @backupPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma senha para proteger o backup'**
  String get backupPasswordRequired;

  /// No description provided for @backupPasswordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 4 caracteres'**
  String get backupPasswordMinLength;

  /// No description provided for @backupConfirmPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha *'**
  String get backupConfirmPasswordLabel;

  /// No description provided for @backupPasswordsMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get backupPasswordsMismatch;

  /// No description provided for @backupIncludePhotosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Incluir fotos no backup (RN-237)'**
  String get backupIncludePhotosTitle;

  /// No description provided for @backupIncludePhotosWithSize.
  ///
  /// In pt, this message translates to:
  /// **'Fotos de cupons e receitas (Tamanho estimado: {size})'**
  String backupIncludePhotosWithSize(String size);

  /// No description provided for @backupIncludePhotosDefault.
  ///
  /// In pt, this message translates to:
  /// **'Fotos de cupons e receitas ficam fora do backup por padrão'**
  String get backupIncludePhotosDefault;

  /// No description provided for @backupExportEncryptedButton.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Criptografado'**
  String get backupExportEncryptedButton;

  /// No description provided for @backupRestoreEncryptedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Backup Criptografado'**
  String get backupRestoreEncryptedTitle;

  /// No description provided for @backupRestoreEncryptedBody.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo de backup está protegido por senha. Informe a senha definida durante a exportação para continuar.'**
  String get backupRestoreEncryptedBody;

  /// No description provided for @backupRestorePasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Digite a senha do backup'**
  String get backupRestorePasswordRequired;

  /// No description provided for @backupRestoreEncryptedButton.
  ///
  /// In pt, this message translates to:
  /// **'Descriptografar e Restaurar'**
  String get backupRestoreEncryptedButton;

  /// No description provided for @backupImportProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Processando backup...'**
  String get backupImportProcessing;

  /// No description provided for @backupImportReplacedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup restaurado com sucesso!'**
  String get backupImportReplacedTitle;

  /// No description provided for @backupImportMergedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados mesclados com sucesso!'**
  String get backupImportMergedTitle;

  /// No description provided for @backupImportReplacedBody.
  ///
  /// In pt, this message translates to:
  /// **'Os dados do aplicativo foram totalmente substituídos pelos do backup.'**
  String get backupImportReplacedBody;

  /// No description provided for @backupImportMergedBody.
  ///
  /// In pt, this message translates to:
  /// **'Os registros do backup foram mesclados aos dados existentes.'**
  String get backupImportMergedBody;

  /// No description provided for @backupImportFailedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Falha na importação'**
  String get backupImportFailedTitle;

  /// No description provided for @backupPreviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização do Backup'**
  String get backupPreviewTitle;

  /// No description provided for @backupPreviewAffectedRecords.
  ///
  /// In pt, this message translates to:
  /// **'{count} registros afetados'**
  String backupPreviewAffectedRecords(int count);

  /// No description provided for @backupPreviewSchemaVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão do schema: v{version}'**
  String backupPreviewSchemaVersion(int version);

  /// No description provided for @backupPreviewExportedAt.
  ///
  /// In pt, this message translates to:
  /// **'Data da exportação: {date}'**
  String backupPreviewExportedAt(String date);

  /// No description provided for @backupImportModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a forma de importação:'**
  String get backupImportModeTitle;

  /// No description provided for @backupImportModeReplace.
  ///
  /// In pt, this message translates to:
  /// **'Substituir tudo'**
  String get backupImportModeReplace;

  /// No description provided for @backupImportModeMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar'**
  String get backupImportModeMerge;

  /// No description provided for @backupImportConfirmReplace.
  ///
  /// In pt, this message translates to:
  /// **'Substituir e restaurar backup'**
  String get backupImportConfirmReplace;

  /// No description provided for @backupImportConfirmMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar dados do backup'**
  String get backupImportConfirmMerge;

  /// No description provided for @backupImportNoFile.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum backup selecionado para pré-visualização.'**
  String get backupImportNoFile;

  /// No description provided for @backupImportSelectFile.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar arquivo de backup'**
  String get backupImportSelectFile;

  /// No description provided for @backupImportPasswordField.
  ///
  /// In pt, this message translates to:
  /// **'Senha do backup'**
  String get backupImportPasswordField;

  /// No description provided for @backupImportRestoreButton.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get backupImportRestoreButton;

  /// No description provided for @wipeConfirmFirstTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão de dados'**
  String get wipeConfirmFirstTitle;

  /// No description provided for @wipeConfirmFirstBody.
  ///
  /// In pt, this message translates to:
  /// **'Você tem certeza de que deseja apagar todos os dados do aplicativo? Esta é a primeira confirmação.'**
  String get wipeConfirmFirstBody;

  /// No description provided for @wipeConfirmSecondTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação Final'**
  String get wipeConfirmSecondTitle;

  /// No description provided for @wipeConfirmSecondBody.
  ///
  /// In pt, this message translates to:
  /// **'ESTA AÇÃO É DEFINITIVA E IRREVERSÍVEL. Todos os seus registros, fotos, tarefas, despesas e configurações serão apagados sem resíduo.'**
  String get wipeConfirmSecondBody;

  /// No description provided for @wipeConfirmSecondButton.
  ///
  /// In pt, this message translates to:
  /// **'Apagar tudo permanentemente'**
  String get wipeConfirmSecondButton;

  /// No description provided for @wipeLoading.
  ///
  /// In pt, this message translates to:
  /// **'Apagando todos os dados...'**
  String get wipeLoading;

  /// No description provided for @wipeSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados foram apagados permanentemente.'**
  String get wipeSuccessTitle;

  /// No description provided for @wipeSuccessBody.
  ///
  /// In pt, this message translates to:
  /// **'O banco de dados, arquivos e configurações foram limpos sem deixar resíduos.'**
  String get wipeSuccessBody;

  /// No description provided for @wipeWarningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atenção: Ação Irreversível'**
  String get wipeWarningTitle;

  /// No description provided for @wipeWarningBody.
  ///
  /// In pt, this message translates to:
  /// **'Ao apagar tudo, todos os registros cadastrados (produtos, despesas, contas fixas, tarefas, receitas, compras e estoque), fotos de cupons e preferências do aplicativo serão apagados permanentemente.'**
  String get wipeWarningBody;

  /// No description provided for @wipeWarningTokens.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum token ou arquivo temporário permanecerá no dispositivo.'**
  String get wipeWarningTokens;

  /// No description provided for @wipeDeleteAllButton.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os dados'**
  String get wipeDeleteAllButton;

  /// No description provided for @monthJanuary.
  ///
  /// In pt, this message translates to:
  /// **'Janeiro'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In pt, this message translates to:
  /// **'Fevereiro'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In pt, this message translates to:
  /// **'Março'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In pt, this message translates to:
  /// **'Abril'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In pt, this message translates to:
  /// **'Maio'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In pt, this message translates to:
  /// **'Junho'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In pt, this message translates to:
  /// **'Julho'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In pt, this message translates to:
  /// **'Agosto'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In pt, this message translates to:
  /// **'Setembro'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In pt, this message translates to:
  /// **'Outubro'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In pt, this message translates to:
  /// **'Novembro'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In pt, this message translates to:
  /// **'Dezembro'**
  String get monthDecember;

  /// No description provided for @monthYearFormat.
  ///
  /// In pt, this message translates to:
  /// **'{month} de {year}'**
  String monthYearFormat(String month, String year);

  /// No description provided for @commonPreviousMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês anterior'**
  String get commonPreviousMonth;

  /// No description provided for @commonNextMonth.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get commonNextMonth;

  /// No description provided for @commonInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get commonInvalidValue;

  /// No description provided for @commonEnterAmount.
  ///
  /// In pt, this message translates to:
  /// **'Informe o valor'**
  String get commonEnterAmount;

  /// No description provided for @commonNotesOptional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get commonNotesOptional;

  /// No description provided for @commonRepeatDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diariamente'**
  String get commonRepeatDaily;

  /// No description provided for @commonRepeatWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanalmente'**
  String get commonRepeatWeekly;

  /// No description provided for @commonRepeatMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensalmente'**
  String get commonRepeatMonthly;

  /// No description provided for @commonRepeatCustomDays.
  ///
  /// In pt, this message translates to:
  /// **'A cada X dias'**
  String get commonRepeatCustomDays;

  /// No description provided for @commonDaysCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de dias *'**
  String get commonDaysCountLabel;

  /// No description provided for @billsUnpayTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar pagamento de {title}'**
  String billsUnpayTooltip(String title);

  /// No description provided for @billsOptionsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Opções da conta'**
  String get billsOptionsTooltip;

  /// No description provided for @billsDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta?'**
  String get billsDeleteConfirmTitle;

  /// No description provided for @billsDeleteConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja excluir a conta \"{title}\"?'**
  String billsDeleteConfirmBody(String title);

  /// No description provided for @billsMarkUnpaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como não pago'**
  String get billsMarkUnpaid;

  /// No description provided for @billsPauseAction.
  ///
  /// In pt, this message translates to:
  /// **'Pausar conta'**
  String get billsPauseAction;

  /// No description provided for @billsDeleteAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get billsDeleteAction;

  /// No description provided for @billsCreateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta \"{title}\" cadastrada com sucesso!'**
  String billsCreateSuccess(String title);

  /// No description provided for @billsCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao cadastrar conta: {error}'**
  String billsCreateError(String error);

  /// No description provided for @billsPaidSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta \"{title}\" marcada como paga!'**
  String billsPaidSuccess(String title);

  /// No description provided for @billsUnpaidSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta \"{title}\" marcada como não paga!'**
  String billsUnpaidSuccess(String title);

  /// No description provided for @billsPausedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta \"{title}\" pausada com sucesso!'**
  String billsPausedSuccess(String title);

  /// No description provided for @billsDeletedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta \"{title}\" excluída com sucesso!'**
  String billsDeletedSuccess(String title);

  /// No description provided for @billsDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir conta: {error}'**
  String billsDeleteError(String error);

  /// No description provided for @billsNewDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Conta a Vencer'**
  String get billsNewDialogTitle;

  /// No description provided for @billsTitleFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título * (ex: Aluguel, Luz, Internet)'**
  String get billsTitleFieldLabel;

  /// No description provided for @billsTitleRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o título'**
  String get billsTitleRequired;

  /// No description provided for @billsAmountFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor em R\$ * (ex: 150.00)'**
  String get billsAmountFieldLabel;

  /// No description provided for @billsDueDayFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia do Vencimento * (1 a 31)'**
  String get billsDueDayFieldLabel;

  /// No description provided for @billsDueDayInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um dia entre 1 e 31'**
  String get billsDueDayInvalid;

  /// No description provided for @billsFrequencyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Frequência da Conta'**
  String get billsFrequencyLabel;

  /// No description provided for @billsFrequencyMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get billsFrequencyMonthly;

  /// No description provided for @billsFrequencyBiweekly.
  ///
  /// In pt, this message translates to:
  /// **'Quinzenal'**
  String get billsFrequencyBiweekly;

  /// No description provided for @billsFrequencyWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get billsFrequencyWeekly;

  /// No description provided for @billsFrequencyAnnual.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get billsFrequencyAnnual;

  /// No description provided for @billsCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria *'**
  String get billsCategoryLabel;

  /// No description provided for @billsSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Conta'**
  String get billsSaveButton;

  /// No description provided for @expensesExportError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao exportar despesas: {error}'**
  String expensesExportError(String error);

  /// No description provided for @expensesMonthBudgetTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento do mês'**
  String get expensesMonthBudgetTooltip;

  /// No description provided for @expensesPurchasesReceiptsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Compras e Notas Fiscais'**
  String get expensesPurchasesReceiptsTooltip;

  /// No description provided for @expensesExportTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar despesas'**
  String get expensesExportTooltip;

  /// No description provided for @expensesExportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get expensesExportCsv;

  /// No description provided for @expensesExportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get expensesExportPdf;

  /// No description provided for @expensesDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir despesa?'**
  String get expensesDeleteConfirmTitle;

  /// No description provided for @expensesDeleteConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja excluir esta despesa?'**
  String get expensesDeleteConfirmBody;

  /// No description provided for @expensesViewPurchaseTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ver Compra / Nota'**
  String get expensesViewPurchaseTooltip;

  /// No description provided for @expensesViewBillTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ver Conta'**
  String get expensesViewBillTooltip;

  /// No description provided for @expensesEditBudget.
  ///
  /// In pt, this message translates to:
  /// **'Editar Orçamento'**
  String get expensesEditBudget;

  /// No description provided for @expensesEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Despesa'**
  String get expensesEditTitle;

  /// No description provided for @expensesDeleteTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Excluir despesa'**
  String get expensesDeleteTooltip;

  /// No description provided for @expensesAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor *'**
  String get expensesAmountLabel;

  /// No description provided for @expensesNameDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome / Descrição'**
  String get expensesNameDescriptionLabel;

  /// No description provided for @expensesNameDescriptionHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: Supermercado, Aluguel, Farmácia'**
  String get expensesNameDescriptionHint;

  /// No description provided for @expensesNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes adicionais...'**
  String get expensesNotesHint;

  /// No description provided for @expensesRepeatExpense.
  ///
  /// In pt, this message translates to:
  /// **'Repetir despesa'**
  String get expensesRepeatExpense;

  /// No description provided for @expensesRepeatFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência de repetição'**
  String get expensesRepeatFrequency;

  /// No description provided for @expensesCustomDaysHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: 4'**
  String get expensesCustomDaysHint;

  /// No description provided for @expensesCustomDaysRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a quantidade de dias (entre 1 e 365)'**
  String get expensesCustomDaysRequired;

  /// No description provided for @expensesCustomDaysInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número de dias válido entre 1 e 365'**
  String get expensesCustomDaysInvalid;

  /// No description provided for @budgetCategoryDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento para {category}'**
  String budgetCategoryDialogTitle(String category);

  /// No description provided for @budgetCategoryLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limite em R\$ * (ex: 500,00)'**
  String get budgetCategoryLimitLabel;

  /// No description provided for @budgetTotalDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento Total de {month}'**
  String budgetTotalDialogTitle(String month);

  /// No description provided for @budgetBaseIncomeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Receita base recorrente *'**
  String get budgetBaseIncomeLabel;

  /// No description provided for @budgetBaseIncomeHint.
  ///
  /// In pt, this message translates to:
  /// **'ex: 3000,00'**
  String get budgetBaseIncomeHint;

  /// No description provided for @budgetIncomeRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe ao menos uma receita'**
  String get budgetIncomeRequired;

  /// No description provided for @budgetExtraIncomeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Receitas adicionais avulsas no mês'**
  String get budgetExtraIncomeLabel;

  /// No description provided for @budgetExtraIncomeHint.
  ///
  /// In pt, this message translates to:
  /// **'ex: 500,00'**
  String get budgetExtraIncomeHint;

  /// No description provided for @budgetTotalSumLabel.
  ///
  /// In pt, this message translates to:
  /// **'Soma total do orçamento:'**
  String get budgetTotalSumLabel;

  /// No description provided for @budgetMonthTotalCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento Total do Mês'**
  String get budgetMonthTotalCardTitle;

  /// No description provided for @budgetEditIncomeTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar receita e orçamento'**
  String get budgetEditIncomeTooltip;

  /// No description provided for @budgetNoCategories.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma categoria cadastrada.'**
  String get budgetNoCategories;

  /// No description provided for @commonAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get commonAdd;

  /// No description provided for @checklistGenerateShoppingList.
  ///
  /// In pt, this message translates to:
  /// **'Gerar lista de compras'**
  String get checklistGenerateShoppingList;

  /// No description provided for @checklistNewItem.
  ///
  /// In pt, this message translates to:
  /// **'Novo item'**
  String get checklistNewItem;

  /// No description provided for @checklistLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar checklist: {error}'**
  String checklistLoadError(String error);

  /// No description provided for @checklistEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens ou selecione outro cômodo.'**
  String get checklistEmptyDescription;

  /// No description provided for @checklistProgressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da casa'**
  String get checklistProgressTitle;

  /// No description provided for @checklistMarkedCount.
  ///
  /// In pt, this message translates to:
  /// **'{marked} de {total} itens marcados'**
  String checklistMarkedCount(int marked, int total);

  /// No description provided for @checklistCreateListCount.
  ///
  /// In pt, this message translates to:
  /// **'Criar lista ({count})'**
  String checklistCreateListCount(int count);

  /// No description provided for @checklistAddItemTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar item ao checklist'**
  String get checklistAddItemTitle;

  /// No description provided for @checklistItemLabel.
  ///
  /// In pt, this message translates to:
  /// **'Item *'**
  String get checklistItemLabel;

  /// No description provided for @checklistItemHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Toalha de rosto'**
  String get checklistItemHint;

  /// No description provided for @checklistRoomLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cômodo / Categoria *'**
  String get checklistRoomLabel;

  /// No description provided for @checklistRoomHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Banheiro'**
  String get checklistRoomHint;

  /// No description provided for @checklistEditItemTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar item'**
  String get checklistEditItemTitle;

  /// No description provided for @checklistItemTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título do item *'**
  String get checklistItemTitleLabel;

  /// No description provided for @checklistDeleteItemTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir item?'**
  String get checklistDeleteItemTitle;

  /// No description provided for @checklistDeleteItemBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover \"{title}\" do checklist?'**
  String checklistDeleteItemBody(String title);

  /// No description provided for @checklistDefaultListNameCategory.
  ///
  /// In pt, this message translates to:
  /// **'Lista da Casa - {category}'**
  String checklistDefaultListNameCategory(String category);

  /// No description provided for @checklistDefaultListName.
  ///
  /// In pt, this message translates to:
  /// **'Lista da Casa (Checklist)'**
  String get checklistDefaultListName;

  /// No description provided for @checklistExportBody.
  ///
  /// In pt, this message translates to:
  /// **'Criar uma lista de compras com os {count} itens pendentes do checklist.'**
  String checklistExportBody(int count);

  /// No description provided for @checklistListNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da lista *'**
  String get checklistListNameLabel;

  /// No description provided for @checklistListCreated.
  ///
  /// In pt, this message translates to:
  /// **'Lista \"{name}\" criada com {count} itens!'**
  String checklistListCreated(String name, int count);

  /// No description provided for @checklistListCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao criar lista: {error}'**
  String checklistListCreateError(String error);

  /// No description provided for @checklistGenerateListButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar lista'**
  String get checklistGenerateListButton;

  /// No description provided for @checklistCardSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{title}, {percent}% concluído, toque para ver detalhes'**
  String checklistCardSemantics(String title, String percent);

  /// No description provided for @customizeVisibleCardsCount.
  ///
  /// In pt, this message translates to:
  /// **'Cards exibidos ({count})'**
  String customizeVisibleCardsCount(int count);

  /// No description provided for @customizeReorderHint.
  ///
  /// In pt, this message translates to:
  /// **'Arraste para reordenar ou utilize os botões acessíveis.'**
  String get customizeReorderHint;

  /// No description provided for @customizeNoVisibleCards.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card visível no momento.'**
  String get customizeNoVisibleCards;

  /// No description provided for @customizeAvailableModulesHint.
  ///
  /// In pt, this message translates to:
  /// **'Módulos disponíveis para inclusão na sua tela inicial.'**
  String get customizeAvailableModulesHint;

  /// No description provided for @customizeAllCardsVisible.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cards já estão visíveis no painel.'**
  String get customizeAllCardsVisible;

  /// No description provided for @customizeDragSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Arrastar {title} para reordenar'**
  String customizeDragSemantics(String title);

  /// No description provided for @customizeMoveUpSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Mover {title} para cima'**
  String customizeMoveUpSemantics(String title);

  /// No description provided for @customizeMoveDownSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Mover {title} para baixo'**
  String customizeMoveDownSemantics(String title);

  /// No description provided for @customizeHideSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar {title}'**
  String customizeHideSemantics(String title);

  /// No description provided for @customizeAddSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar {title} ao painel'**
  String customizeAddSemantics(String title);

  /// No description provided for @dueBillsWidgetSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Widget de contas a vencer'**
  String get dueBillsWidgetSemantics;

  /// No description provided for @dueBillsDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas a vencer'**
  String get dueBillsDefaultTitle;

  /// No description provided for @dueBillsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta a vencer'**
  String get dueBillsEmptyTitle;

  /// No description provided for @dueBillsEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Todas as suas contas deste mês estão em dia.'**
  String get dueBillsEmptyDescription;

  /// No description provided for @dueBillsVariableAmount.
  ///
  /// In pt, this message translates to:
  /// **'Variável'**
  String get dueBillsVariableAmount;

  /// No description provided for @dueBillsItemSemanticsHidden.
  ///
  /// In pt, this message translates to:
  /// **'{title}, {dueLabel}, valor oculto'**
  String dueBillsItemSemanticsHidden(String title, String dueLabel);

  /// No description provided for @dueBillsItemSemanticsVisible.
  ///
  /// In pt, this message translates to:
  /// **'{title}, {dueLabel}, valor {amount}'**
  String dueBillsItemSemanticsVisible(
    String title,
    String dueLabel,
    String amount,
  );

  /// No description provided for @dueBillsViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as contas'**
  String get dueBillsViewAll;

  /// No description provided for @economySetGoalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definir Meta de Economia'**
  String get economySetGoalTitle;

  /// No description provided for @economySetGoalFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Meta de Economia do Mês'**
  String get economySetGoalFieldLabel;

  /// No description provided for @economySaveGoalButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Meta'**
  String get economySaveGoalButton;

  /// No description provided for @economyLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados: {error}'**
  String economyLoadError(String error);

  /// No description provided for @economyMonthGoalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meta do Mês ({month})'**
  String economyMonthGoalTitle(String month);

  /// No description provided for @economySetGoalFallback.
  ///
  /// In pt, this message translates to:
  /// **'Definir meta de economia'**
  String get economySetGoalFallback;

  /// No description provided for @economyCardSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{title}, {goalText}, toque para ver detalhes'**
  String economyCardSemantics(String title, String goalText);

  /// No description provided for @searchGlobalScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Busca Global'**
  String get searchGlobalScreenTitle;

  /// No description provided for @searchGlobalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Buscar em todo o app'**
  String get searchGlobalLabel;

  /// No description provided for @searchGlobalInputHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite produtos, despesas, tarefas...'**
  String get searchGlobalInputHint;

  /// No description provided for @searchGlobalEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Busca no app'**
  String get searchGlobalEmptyTitle;

  /// No description provided for @searchGlobalEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Busque por produtos, despesas, tarefas, receitas e listas.'**
  String get searchGlobalEmptyDescription;

  /// No description provided for @searchGlobalNoResultsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get searchGlobalNoResultsTitle;

  /// No description provided for @searchGlobalNoResultsForQuery.
  ///
  /// In pt, this message translates to:
  /// **'Não encontramos nada para \"{query}\". Tente outro termo.'**
  String searchGlobalNoResultsForQuery(String query);

  /// No description provided for @monthBalanceLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar saldo do mês: {error}'**
  String monthBalanceLoadError(String error);

  /// No description provided for @monthBalanceNotSet.
  ///
  /// In pt, this message translates to:
  /// **'Não definido'**
  String get monthBalanceNotSet;

  /// No description provided for @monthBalanceSemanticsHidden.
  ///
  /// In pt, this message translates to:
  /// **'Widget de saldo do mês, valor oculto'**
  String get monthBalanceSemanticsHidden;

  /// No description provided for @monthBalanceSemanticsVisible.
  ///
  /// In pt, this message translates to:
  /// **'Widget de saldo do mês, gasto {actual} de {budget}'**
  String monthBalanceSemanticsVisible(String actual, String budget);

  /// No description provided for @monthBalanceDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês'**
  String get monthBalanceDefaultTitle;

  /// No description provided for @monthBalanceSpentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gasto no mês'**
  String get monthBalanceSpentLabel;

  /// No description provided for @monthBalanceBudgetedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Orçado: {budget}'**
  String monthBalanceBudgetedLabel(String budget);

  /// No description provided for @monthBalanceViewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver resumo financeiro'**
  String get monthBalanceViewDetails;

  /// No description provided for @recipesCardSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{title}, {count} receitas favoritas, toque para ver detalhes'**
  String recipesCardSemantics(String title, int count);

  /// No description provided for @shoppingWidgetSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Widget de listas de compras'**
  String get shoppingWidgetSemantics;

  /// No description provided for @shoppingWidgetEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista de compras'**
  String get shoppingWidgetEmptyTitle;

  /// No description provided for @shoppingWidgetEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma lista para acompanhar suas compras.'**
  String get shoppingWidgetEmptyDescription;

  /// No description provided for @shoppingWidgetOnePending.
  ///
  /// In pt, this message translates to:
  /// **'1 item pendente'**
  String get shoppingWidgetOnePending;

  /// No description provided for @shoppingWidgetPendingOfTotal.
  ///
  /// In pt, this message translates to:
  /// **'{pending} de {total} itens pendentes'**
  String shoppingWidgetPendingOfTotal(int pending, int total);

  /// No description provided for @shoppingWidgetViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as listas'**
  String get shoppingWidgetViewAll;

  /// No description provided for @stockCardSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{title}, toque para ver detalhes'**
  String stockCardSemantics(String title);

  /// No description provided for @stockCardEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto monitorado no estoque.'**
  String get stockCardEmpty;

  /// No description provided for @stockCardCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} produto(s) no estoque doméstico'**
  String stockCardCount(int count);

  /// No description provided for @stockRegisterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar no Estoque'**
  String get stockRegisterTitle;

  /// No description provided for @stockProductNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Produto *'**
  String get stockProductNameLabel;

  /// No description provided for @stockProductNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Arroz Tipo 1'**
  String get stockProductNameHint;

  /// No description provided for @stockApproxQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade aproximada *'**
  String get stockApproxQuantityLabel;

  /// No description provided for @stockApproxQuantityHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 4'**
  String get stockApproxQuantityHint;

  /// No description provided for @stockAddProductButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar produto'**
  String get stockAddProductButton;

  /// No description provided for @stockLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar estoque: {error}'**
  String stockLoadError(String error);

  /// No description provided for @stockEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estoque vazio'**
  String get stockEmptyTitle;

  /// No description provided for @stockEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto registrado no estoque doméstico.'**
  String get stockEmptyDescription;

  /// No description provided for @stockNoEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Sem estimativa de consumo (compras no histórico: {count}, mínimo: 3)'**
  String stockNoEstimate(int count);

  /// No description provided for @stockAvgInterval.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo médio de compra: {days} dias'**
  String stockAvgInterval(String days);

  /// No description provided for @stockEstimatedRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa restante: ~{days} dias'**
  String stockEstimatedRemaining(int days);

  /// No description provided for @todayTasksWidgetSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Widget de tarefas do dia'**
  String get todayTasksWidgetSemantics;

  /// No description provided for @todayTasksDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas de hoje'**
  String get todayTasksDefaultTitle;

  /// No description provided for @todayTasksEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa para hoje'**
  String get todayTasksEmptyTitle;

  /// No description provided for @todayTasksEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem tarefas agendadas para hoje.'**
  String get todayTasksEmptyDescription;

  /// No description provided for @todayTasksDoneStatus.
  ///
  /// In pt, this message translates to:
  /// **'concluída'**
  String get todayTasksDoneStatus;

  /// No description provided for @todayTasksPendingStatus.
  ///
  /// In pt, this message translates to:
  /// **'pendente'**
  String get todayTasksPendingStatus;

  /// No description provided for @todayTasksAllDoneMessage.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tarefas de hoje foram concluídas! 🎉'**
  String get todayTasksAllDoneMessage;

  /// No description provided for @todayTasksViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as tarefas'**
  String get todayTasksViewAll;

  /// No description provided for @commonAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get commonAll;

  /// No description provided for @economyNoGoalSet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma meta definida'**
  String get economyNoGoalSet;

  /// No description provided for @economyChangeGoalButton.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Meta'**
  String get economyChangeGoalButton;

  /// No description provided for @economyGoalProgressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da Meta'**
  String get economyGoalProgressTitle;

  /// No description provided for @economyContextualTipsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas Contextuais'**
  String get economyContextualTipsTitle;

  /// No description provided for @stockProductFallback.
  ///
  /// In pt, this message translates to:
  /// **'Produto: {id}'**
  String stockProductFallback(String id);

  /// No description provided for @stockReportedQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade informada: {quantity} {unit}'**
  String stockReportedQuantity(String quantity, String unit);

  /// No description provided for @dueBillsWidgetLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar contas a vencer: {error}'**
  String dueBillsWidgetLoadError(String error);

  /// No description provided for @shoppingListCompletedCelebration.
  ///
  /// In pt, this message translates to:
  /// **'Você completou a lista de compras! 💕'**
  String get shoppingListCompletedCelebration;

  /// No description provided for @shoppingListRegisterPurchaseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar compra'**
  String get shoppingListRegisterPurchaseTitle;

  /// No description provided for @shoppingListManageLists.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar listas'**
  String get shoppingListManageLists;

  /// No description provided for @shoppingListClearPurchased.
  ///
  /// In pt, this message translates to:
  /// **'Limpar comprados'**
  String get shoppingListClearPurchased;

  /// No description provided for @shoppingListItemsMarkedCount.
  ///
  /// In pt, this message translates to:
  /// **'{marked} de {total} itens marcados'**
  String shoppingListItemsMarkedCount(int marked, int total);

  /// No description provided for @shoppingListEmptyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens para não esquecer nada no mercado.'**
  String get shoppingListEmptyDescription;

  /// No description provided for @shoppingShortcutPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get shoppingShortcutPurchases;

  /// No description provided for @shoppingShortcutPrices.
  ///
  /// In pt, this message translates to:
  /// **'Preços'**
  String get shoppingShortcutPrices;

  /// No description provided for @shoppingShortcutStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get shoppingShortcutStock;

  /// No description provided for @shoppingQuantitySemantics.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get shoppingQuantitySemantics;

  /// No description provided for @shoppingQuantityShortLabel.
  ///
  /// In pt, this message translates to:
  /// **'Qtd'**
  String get shoppingQuantityShortLabel;

  /// No description provided for @shoppingUnitSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Unidade de medida'**
  String get shoppingUnitSemantics;

  /// No description provided for @shoppingUnitUnShort.
  ///
  /// In pt, this message translates to:
  /// **'Un'**
  String get shoppingUnitUnShort;

  /// No description provided for @shoppingErrorSaveChange.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar alteração'**
  String get shoppingErrorSaveChange;

  /// No description provided for @shoppingErrorAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao adicionar item'**
  String get shoppingErrorAddItem;

  /// No description provided for @shoppingErrorRemoveItem.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao remover item'**
  String get shoppingErrorRemoveItem;

  /// No description provided for @shoppingErrorClearCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao limpar itens concluídos'**
  String get shoppingErrorClearCompleted;

  /// No description provided for @shoppingTileRegisterSingle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar compra deste item'**
  String get shoppingTileRegisterSingle;

  /// No description provided for @shoppingTileRemoveItem.
  ///
  /// In pt, this message translates to:
  /// **'Remover item'**
  String get shoppingTileRemoveItem;

  /// No description provided for @shoppingSheetsMyListsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Listas de Compras'**
  String get shoppingSheetsMyListsTitle;

  /// No description provided for @shoppingSheetsNewList.
  ///
  /// In pt, this message translates to:
  /// **'Nova Lista'**
  String get shoppingSheetsNewList;

  /// No description provided for @shoppingSheetsNoLists.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista encontrada.'**
  String get shoppingSheetsNoLists;

  /// No description provided for @shoppingSheetsArchivedCount.
  ///
  /// In pt, this message translates to:
  /// **'Arquivada • {count} itens'**
  String shoppingSheetsArchivedCount(int count);

  /// No description provided for @shoppingSheetsItemsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} itens'**
  String shoppingSheetsItemsCount(int count);

  /// No description provided for @shoppingSheetsListOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções da lista'**
  String get shoppingSheetsListOptions;

  /// No description provided for @shoppingSheetsDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get shoppingSheetsDuplicate;

  /// No description provided for @shoppingSheetsRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get shoppingSheetsRename;

  /// No description provided for @shoppingSheetsDuplicateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lista duplicada com sucesso.'**
  String get shoppingSheetsDuplicateSuccess;

  /// No description provided for @shoppingSheetsDuplicateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao duplicar lista.'**
  String get shoppingSheetsDuplicateError;

  /// No description provided for @shoppingSheetsRenameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Renomear Lista'**
  String get shoppingSheetsRenameTitle;

  /// No description provided for @shoppingSheetsListNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da lista *'**
  String get shoppingSheetsListNameLabel;

  /// No description provided for @shoppingSheetsArchivedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lista arquivada com sucesso.'**
  String get shoppingSheetsArchivedSuccess;

  /// No description provided for @shoppingSheetsUnarchivedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lista desarquivada com sucesso.'**
  String get shoppingSheetsUnarchivedSuccess;

  /// No description provided for @shoppingSheetsCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Lista de Compras'**
  String get shoppingSheetsCreateTitle;

  /// No description provided for @shoppingSheetsCreateHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: Feira, Farmácia, Churrasco'**
  String get shoppingSheetsCreateHint;

  /// No description provided for @shoppingSheetsCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get shoppingSheetsCreateButton;

  /// No description provided for @taskPresetsAreaSemantics.
  ///
  /// In pt, this message translates to:
  /// **'área {area}'**
  String taskPresetsAreaSemantics(String area);

  /// No description provided for @calendarTabDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get calendarTabDay;

  /// No description provided for @calendarTabWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get calendarTabWeek;

  /// No description provided for @calendarTabMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get calendarTabMonth;

  /// No description provided for @calendarMaintenanceSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões de manutenção'**
  String get calendarMaintenanceSuggestions;

  /// No description provided for @calendarSyncGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar com Google'**
  String get calendarSyncGoogle;

  /// No description provided for @calendarSyncStarting.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando sincronização...'**
  String get calendarSyncStarting;

  /// No description provided for @calendarSyncDone.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização concluída!'**
  String get calendarSyncDone;

  /// No description provided for @calendarTodayTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get calendarTodayTooltip;

  /// No description provided for @calendarShowingToday.
  ///
  /// In pt, this message translates to:
  /// **'Exibindo hoje'**
  String get calendarShowingToday;

  /// No description provided for @calendarNewTask.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get calendarNewTask;

  /// No description provided for @calendarEditTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Tarefa'**
  String get calendarEditTaskTitle;

  /// No description provided for @calendarTaskTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título *'**
  String get calendarTaskTitleLabel;

  /// No description provided for @calendarDayBillsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} conta(s)'**
  String calendarDayBillsCount(int count);

  /// No description provided for @calendarBillsDueToday.
  ///
  /// In pt, this message translates to:
  /// **'Contas a vencer hoje ({count}):'**
  String calendarBillsDueToday(int count);

  /// No description provided for @calendarBillPaidStatus.
  ///
  /// In pt, this message translates to:
  /// **'(Paga)'**
  String get calendarBillPaidStatus;

  /// No description provided for @calendarBillPendingStatus.
  ///
  /// In pt, this message translates to:
  /// **'(Pendente)'**
  String get calendarBillPendingStatus;

  /// No description provided for @calendarDeleteTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tarefa?'**
  String get calendarDeleteTaskTitle;

  /// No description provided for @calendarDeleteTaskConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja excluir \"{title}\"?'**
  String calendarDeleteTaskConfirm(String title);

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @taskAllDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia inteiro'**
  String get taskAllDayLabel;

  /// No description provided for @taskRepeatLabel.
  ///
  /// In pt, this message translates to:
  /// **'Repetição'**
  String get taskRepeatLabel;

  /// No description provided for @taskRepeatNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem repetição'**
  String get taskRepeatNone;

  /// No description provided for @calendarEditTaskAction.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa'**
  String get calendarEditTaskAction;

  /// No description provided for @calendarDeleteTaskAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tarefa'**
  String get calendarDeleteTaskAction;

  /// No description provided for @priceSearchProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar produto'**
  String get priceSearchProductLabel;

  /// No description provided for @priceSearchProductHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite para buscar um produto...'**
  String get priceSearchProductHint;

  /// No description provided for @priceClearSearchTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Limpar busca'**
  String get priceClearSearchTooltip;

  /// No description provided for @purchaseSaveTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Salvar compra'**
  String get purchaseSaveTooltip;

  /// No description provided for @purchaseNewProductTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Novo produto'**
  String get purchaseNewProductTooltip;

  /// No description provided for @purchaseRemoveItemTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover item'**
  String get purchaseRemoveItemTooltip;

  /// No description provided for @purchasesHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compras e Notas Fiscais'**
  String get purchasesHistoryTitle;

  /// No description provided for @purchasesPriceHistoryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Preços'**
  String get purchasesPriceHistoryTooltip;

  /// No description provided for @purchasesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar compras: {error}'**
  String purchasesLoadError(String error);

  /// No description provided for @purchasesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra registrada'**
  String get purchasesEmptyTitle;

  /// No description provided for @purchasesRegisterButton.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Compra'**
  String get purchasesRegisterButton;

  /// No description provided for @purchasesDeleteTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Excluir compra'**
  String get purchasesDeleteTooltip;

  /// No description provided for @purchasesNewTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova Compra'**
  String get purchasesNewTooltip;

  /// No description provided for @purchasesDeleteDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir compra?'**
  String get purchasesDeleteDialogTitle;

  /// No description provided for @purchasesDeleteDialogBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta compra e seus pontos de preço serão excluídos.'**
  String get purchasesDeleteDialogBody;

  /// No description provided for @purchasesDeleteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Compra excluída com sucesso'**
  String get purchasesDeleteSuccess;

  /// No description provided for @purchasesDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir compra'**
  String get purchasesDeleteError;

  /// No description provided for @purchasesTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get purchasesTotalLabel;

  /// No description provided for @purchasesDiscountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto'**
  String get purchasesDiscountLabel;

  /// No description provided for @purchasesItemsCount.
  ///
  /// In pt, this message translates to:
  /// **'Itens ({count})'**
  String purchasesItemsCount(int count);

  /// No description provided for @purchasesNoDetailedItems.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item detalhado nesta compra.'**
  String get purchasesNoDetailedItems;

  /// No description provided for @purchasesProductFallback.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get purchasesProductFallback;

  /// No description provided for @purchasesItemPriceHistoryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de preço'**
  String get purchasesItemPriceHistoryTooltip;

  /// No description provided for @priceChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{price} em {store} no {date}'**
  String priceChartSemantics(String price, String store, String date);

  /// No description provided for @productTrackPricesTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhar preços'**
  String get productTrackPricesTooltip;

  /// No description provided for @productMergeTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Unir com outro produto'**
  String get productMergeTooltip;

  /// No description provided for @productTrackPriceHistoryButton.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhar histórico de preços'**
  String get productTrackPriceHistoryButton;

  /// No description provided for @productPreferredNameSet.
  ///
  /// In pt, this message translates to:
  /// **'\"{alias}\" definido como nome padrão de exibição.'**
  String productPreferredNameSet(String alias);

  /// No description provided for @productSeparateAliasDescription.
  ///
  /// In pt, this message translates to:
  /// **'Você pode separar \"{alias}\" como um produto independente (com seu próprio histórico de preços) ou apenas remover o apelido.'**
  String productSeparateAliasDescription(String alias);

  /// No description provided for @productSeparateAliasAction.
  ///
  /// In pt, this message translates to:
  /// **'Separar como outro produto'**
  String get productSeparateAliasAction;

  /// No description provided for @productNoMergeCandidates.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum outro produto disponível para união.'**
  String get productNoMergeCandidates;

  /// No description provided for @productMergeSearchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Buscar produto destino'**
  String get productMergeSearchLabel;

  /// No description provided for @productMergeNoneFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado.'**
  String get productMergeNoneFound;

  /// No description provided for @productMergeConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar união'**
  String get productMergeConfirmTitle;

  /// No description provided for @productMergeConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja unir \"{source}\" com \"{target}\"?\n\nTodas as compras, itens, preços e sinônimos serão transferidos para \"{target}\" e este produto será arquivado.'**
  String productMergeConfirmBody(String source, String target);

  /// No description provided for @productMergeConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Unir produtos'**
  String get productMergeConfirmButton;

  /// No description provided for @productMergeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Produto unido com \"{target}\".'**
  String productMergeSuccess(String target);

  /// No description provided for @productNewDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Produto'**
  String get productNewDialogTitle;

  /// No description provided for @productCanonicalNameRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome Canônico *'**
  String get productCanonicalNameRequiredLabel;

  /// No description provided for @productCanonicalNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome'**
  String get productCanonicalNameError;

  /// No description provided for @productDefaultUnitRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade Padrão *'**
  String get productDefaultUnitRequiredLabel;

  /// No description provided for @productAliasesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Apelidos / Sinônimos'**
  String get productAliasesLabel;

  /// No description provided for @productAliasesHint.
  ///
  /// In pt, this message translates to:
  /// **'Separados por vírgula (opcional)'**
  String get productAliasesHint;

  /// No description provided for @productCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar produto'**
  String get productCreateError;

  /// No description provided for @recipeListServiceUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Serviço de listas não disponível'**
  String get recipeListServiceUnavailable;

  /// No description provided for @recipeNoActiveShoppingLists.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma lista de compras ativa encontrada.'**
  String get recipeNoActiveShoppingLists;

  /// No description provided for @recipeSelectShoppingListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a lista de compras'**
  String get recipeSelectShoppingListTitle;

  /// No description provided for @recipeIngredientsSentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes enviados para a lista de compras!'**
  String get recipeIngredientsSentSuccess;

  /// No description provided for @recipeIngredientsSentError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao enviar ingredientes: {error}'**
  String recipeIngredientsSentError(String error);

  /// No description provided for @recipeDecreaseServingsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir porções'**
  String get recipeDecreaseServingsTooltip;

  /// No description provided for @recipeIncreaseServingsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar porções'**
  String get recipeIncreaseServingsTooltip;

  /// No description provided for @recipeSendIngredientsButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar ingredientes para lista de compras'**
  String get recipeSendIngredientsButton;

  /// No description provided for @recipeDraftTitleRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'O título é obrigatório.'**
  String get recipeDraftTitleRequiredError;

  /// No description provided for @recipeDraftIngredientsRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'Adicione pelo menos um ingrediente.'**
  String get recipeDraftIngredientsRequiredError;

  /// No description provided for @recipeDraftSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar receita: {error}'**
  String recipeDraftSaveError(String error);

  /// No description provided for @recipePasteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Colar receita'**
  String get recipePasteTitle;

  /// No description provided for @recipePasteHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole a receita aqui (título, ingredientes, modo de preparo)...'**
  String get recipePasteHint;

  /// No description provided for @recipeImportButton.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get recipeImportButton;

  /// No description provided for @recipeIngredientNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do ingrediente'**
  String get recipeIngredientNameLabel;

  /// No description provided for @recipeIngredientNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 2 xícaras de farinha'**
  String get recipeIngredientNameHint;

  /// No description provided for @recipeTagNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da tag'**
  String get recipeTagNameLabel;

  /// No description provided for @recipeTagNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Sobremesa, Rápido, Vegano'**
  String get recipeTagNameHint;

  /// No description provided for @recipeSaveTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Salvar receita'**
  String get recipeSaveTooltip;

  /// No description provided for @recipeRemoveIngredientSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Remover ingrediente {name}'**
  String recipeRemoveIngredientSemantics(String name);

  /// No description provided for @recipeRemoveIngredientTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover ingrediente'**
  String get recipeRemoveIngredientTooltip;

  /// No description provided for @recipeAddPhotoButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get recipeAddPhotoButton;

  /// No description provided for @recipePhotoAttached.
  ///
  /// In pt, this message translates to:
  /// **'Foto anexada à receita.'**
  String get recipePhotoAttached;

  /// No description provided for @recipeSpinDecrease.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir {label}'**
  String recipeSpinDecrease(String label);

  /// No description provided for @recipeSpinIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar {label}'**
  String recipeSpinIncrease(String label);

  /// No description provided for @recipeListTimeAndServings.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min • {servings} porções'**
  String recipeListTimeAndServings(int minutes, int servings);

  /// No description provided for @recipeUnfavoriteTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar favorito'**
  String get recipeUnfavoriteTooltip;

  /// No description provided for @recipeFavoriteTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como favorito'**
  String get recipeFavoriteTooltip;

  /// No description provided for @recipeRepoUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Repositório de receitas não disponível'**
  String get recipeRepoUnavailable;

  /// No description provided for @recipeNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Receita não encontrada'**
  String get recipeNotFound;

  /// No description provided for @recipeNoInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Sem instruções cadastradas.'**
  String get recipeNoInstructions;

  /// No description provided for @ocrScanReceiptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escanear nota fiscal'**
  String get ocrScanReceiptTitle;

  /// No description provided for @ocrDisableFlashTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Desativar flash'**
  String get ocrDisableFlashTooltip;

  /// No description provided for @ocrEnableFlashTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ativar flash'**
  String get ocrEnableFlashTooltip;

  /// No description provided for @ocrBenchmarkTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Benchmark de Precisão OCR'**
  String get ocrBenchmarkTooltip;

  /// No description provided for @ocrGalleryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Escolher foto da galeria'**
  String get ocrGalleryTooltip;

  /// No description provided for @ocrGalleryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get ocrGalleryLabel;

  /// No description provided for @ocrTakePhotoSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto da nota fiscal'**
  String get ocrTakePhotoSemantics;

  /// No description provided for @ocrManualEntryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Lançar manualmente'**
  String get ocrManualEntryTooltip;

  /// No description provided for @ocrReceiptSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Nota Fiscal salva com sucesso!'**
  String get ocrReceiptSavedSuccess;

  /// No description provided for @ocrReceiptSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar nota: {error}'**
  String ocrReceiptSaveError(String error);

  /// No description provided for @ocrRecognizeError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao reconhecer nota fiscal.'**
  String get ocrRecognizeError;

  /// No description provided for @ocrTotalDivergenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Divergência no total'**
  String get ocrTotalDivergenceTitle;

  /// No description provided for @ocrTotalDivergenceBody.
  ///
  /// In pt, this message translates to:
  /// **'A soma dos itens selecionados ({itemsSum}) difere do total lido ({total}).\n\nDivergência de {divergence}. Deseja salvar assim mesmo?'**
  String ocrTotalDivergenceBody(
    String itemsSum,
    String total,
    String divergence,
  );

  /// No description provided for @ocrWriteOffTitle.
  ///
  /// In pt, this message translates to:
  /// **'Baixar itens da lista de compras'**
  String get ocrWriteOffTitle;

  /// No description provided for @ocrWriteOffSingleConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja dar baixa nos itens desta compra na lista de compras \"{listName}\"?'**
  String ocrWriteOffSingleConfirm(String listName);

  /// No description provided for @commonNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get commonNo;

  /// No description provided for @ocrWriteOffYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim, dar baixa'**
  String get ocrWriteOffYes;

  /// No description provided for @ocrWriteOffSelectPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a lista de compras para dar baixa nos itens comprados:'**
  String get ocrWriteOffSelectPrompt;

  /// No description provided for @ocrSaveWithoutWriteOff.
  ///
  /// In pt, this message translates to:
  /// **'Salvar sem baixa'**
  String get ocrSaveWithoutWriteOff;

  /// No description provided for @ocrWriteOffButton.
  ///
  /// In pt, this message translates to:
  /// **'Dar baixa'**
  String get ocrWriteOffButton;

  /// No description provided for @ocrCouponItemsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Itens do cupom ({selected}/{total})'**
  String ocrCouponItemsHeader(int selected, int total);

  /// No description provided for @ocrAddItemButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar item'**
  String get ocrAddItemButton;

  /// No description provided for @ocrNoItemsPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item. Toque em Adicionar item.'**
  String get ocrNoItemsPlaceholder;

  /// No description provided for @ocrCloudConsentBody.
  ///
  /// In pt, this message translates to:
  /// **'A leitura no aparelho teve baixa precisão. Como você permitiu o OCR na nuvem nas configurações, deseja tentar melhorar a leitura enviando esta nota para o serviço em nuvem nesta operação?'**
  String get ocrCloudConsentBody;

  /// No description provided for @ocrRetakePhotoButton.
  ///
  /// In pt, this message translates to:
  /// **'Tirar outra foto'**
  String get ocrRetakePhotoButton;

  /// No description provided for @ocrContinueWithoutCloud.
  ///
  /// In pt, this message translates to:
  /// **'Continuar sem nuvem'**
  String get ocrContinueWithoutCloud;

  /// No description provided for @ocrUseCloudOcr.
  ///
  /// In pt, this message translates to:
  /// **'Usar OCR na nuvem'**
  String get ocrUseCloudOcr;

  /// No description provided for @ocrLowPrecisionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Leitura com baixa precisão'**
  String get ocrLowPrecisionTitle;

  /// No description provided for @ocrLowPrecisionBody.
  ///
  /// In pt, this message translates to:
  /// **'A leitura da nota fiscal no aparelho teve baixa precisão. Recomendamos tirar uma nova foto com melhor iluminação e enquadramento.'**
  String get ocrLowPrecisionBody;

  /// No description provided for @ocrContinueWithData.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com estes dados'**
  String get ocrContinueWithData;

  /// No description provided for @ocrFramingGuideSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Guia de enquadramento de nota fiscal. {instruction}'**
  String ocrFramingGuideSemantics(String instruction);

  /// No description provided for @ocrFramingDefaultInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Posicione a nota fiscal na vertical dentro do guia'**
  String get ocrFramingDefaultInstruction;

  /// No description provided for @ocrTotalFailureTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler a nota'**
  String get ocrTotalFailureTitle;

  /// No description provided for @ocrAttachedPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Foto anexada: {path}'**
  String ocrAttachedPhoto(String path);

  /// No description provided for @ocrQualityContinueAnyway.
  ///
  /// In pt, this message translates to:
  /// **'Continuar mesmo assim'**
  String get ocrQualityContinueAnyway;

  /// No description provided for @ocrQualityBlur.
  ///
  /// In pt, this message translates to:
  /// **'Imagem desfocada. Tente segurar a câmera com firmeza.'**
  String get ocrQualityBlur;

  /// No description provided for @ocrQualityTooDark.
  ///
  /// In pt, this message translates to:
  /// **'Iluminação muito baixa. Ligue o flash ou ilumine a nota.'**
  String get ocrQualityTooDark;

  /// No description provided for @ocrQualityTooBright.
  ///
  /// In pt, this message translates to:
  /// **'Excesso de iluminação ou reflexo brilhante na imagem.'**
  String get ocrQualityTooBright;

  /// No description provided for @ocrQualityBadFraming.
  ///
  /// In pt, this message translates to:
  /// **'Enquadramento ruim ou foto muito pequena.'**
  String get ocrQualityBadFraming;

  /// No description provided for @ocrQualityInvalidImage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível decodificar os dados da imagem.'**
  String get ocrQualityInvalidImage;

  /// No description provided for @ocrStoreUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Estabelecimento não identificado'**
  String get ocrStoreUnknown;

  /// No description provided for @ocrEditStoreTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar estabelecimento'**
  String get ocrEditStoreTooltip;

  /// No description provided for @ocrCnpjLabel.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ: {cnpj}'**
  String ocrCnpjLabel(String cnpj);

  /// No description provided for @ocrNotInformed.
  ///
  /// In pt, this message translates to:
  /// **'Não informado'**
  String get ocrNotInformed;

  /// No description provided for @ocrCnpjUnconfirmed.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ não confirmado'**
  String get ocrCnpjUnconfirmed;

  /// No description provided for @ocrTotalDivergenceCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Divergência no valor total'**
  String get ocrTotalDivergenceCardTitle;

  /// No description provided for @ocrTotalDivergenceCardBody.
  ///
  /// In pt, this message translates to:
  /// **'Divergência de {absDiv}. O sistema não ajusta automaticamente.\nSoma dos itens: {itemsSum} | Total lido: {total}'**
  String ocrTotalDivergenceCardBody(
    String absDiv,
    String itemsSum,
    String total,
  );

  /// No description provided for @ocrLowConfidenceBanner.
  ///
  /// In pt, this message translates to:
  /// **'Há {count} item(ns) com baixa confiança lidos do cupom. Verifique e marque os corretos.'**
  String ocrLowConfidenceBanner(int count);

  /// No description provided for @ocrReceiptTotalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Totais da Nota'**
  String get ocrReceiptTotalsTitle;

  /// No description provided for @ocrEditTotalsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar totais'**
  String get ocrEditTotalsTooltip;

  /// No description provided for @ocrSubtotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal:'**
  String get ocrSubtotalLabel;

  /// No description provided for @ocrDiscountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto:'**
  String get ocrDiscountLabel;

  /// No description provided for @ocrOriginExactAlias.
  ///
  /// In pt, this message translates to:
  /// **'exato (apelido)'**
  String get ocrOriginExactAlias;

  /// No description provided for @ocrOriginSeed.
  ///
  /// In pt, this message translates to:
  /// **'semente'**
  String get ocrOriginSeed;

  /// No description provided for @ocrOriginFuzzy.
  ///
  /// In pt, this message translates to:
  /// **'aproximado ({percent}%)'**
  String ocrOriginFuzzy(int percent);

  /// No description provided for @ocrOriginUnknown.
  ///
  /// In pt, this message translates to:
  /// **'não identificado'**
  String get ocrOriginUnknown;

  /// No description provided for @ocrItemSelectedStatus.
  ///
  /// In pt, this message translates to:
  /// **'selecionado'**
  String get ocrItemSelectedStatus;

  /// No description provided for @ocrItemUnselectedStatus.
  ///
  /// In pt, this message translates to:
  /// **'desmarcado'**
  String get ocrItemUnselectedStatus;

  /// No description provided for @ocrItemLowConfidenceHint.
  ///
  /// In pt, this message translates to:
  /// **', baixa confiança, confira este item'**
  String get ocrItemLowConfidenceHint;

  /// No description provided for @ocrItemDetectedAs.
  ///
  /// In pt, this message translates to:
  /// **'detectado como {raw}'**
  String ocrItemDetectedAs(String raw);

  /// No description provided for @ocrItemUncheckHint.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar {title}'**
  String ocrItemUncheckHint(String title);

  /// No description provided for @ocrItemLinkOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Vínculo: {origin}'**
  String ocrItemLinkOrigin(String origin);

  /// No description provided for @ocrEditItemTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar item'**
  String get ocrEditItemTooltip;

  /// No description provided for @ocrDeleteItemTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Apagar item'**
  String get ocrDeleteItemTooltip;

  /// No description provided for @ocrEditHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar cabeçalho'**
  String get ocrEditHeaderTitle;

  /// No description provided for @ocrStoreRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estabelecimento *'**
  String get ocrStoreRequiredLabel;

  /// No description provided for @ocrStoreHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do supermercado ou loja'**
  String get ocrStoreHint;

  /// No description provided for @ocrStoreError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do estabelecimento'**
  String get ocrStoreError;

  /// No description provided for @ocrCnpjOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ (opcional)'**
  String get ocrCnpjOptionalLabel;

  /// No description provided for @ocrDateTimeRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data/Hora (dd/MM/yyyy HH:mm) *'**
  String get ocrDateTimeRequiredLabel;

  /// No description provided for @ocrDateTimeRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'Informe a data da compra'**
  String get ocrDateTimeRequiredError;

  /// No description provided for @ocrDateTimeInvalidError.
  ///
  /// In pt, this message translates to:
  /// **'Formato inválido (ex: 21/09/2026 14:30)'**
  String get ocrDateTimeInvalidError;

  /// No description provided for @ocrNfceKeyOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Chave da NFC-e (opcional)'**
  String get ocrNfceKeyOptionalLabel;

  /// No description provided for @ocrNfceKeyHint.
  ///
  /// In pt, this message translates to:
  /// **'44 dígitos da nota fiscal'**
  String get ocrNfceKeyHint;

  /// No description provided for @ocrSubtotalInputLabel.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal (R\$)'**
  String get ocrSubtotalInputLabel;

  /// No description provided for @ocrDiscountInputLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto (R\$)'**
  String get ocrDiscountInputLabel;

  /// No description provided for @ocrReadTotalInputLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total lido (R\$)'**
  String get ocrReadTotalInputLabel;

  /// No description provided for @ocrRegisterNewProductTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar novo produto'**
  String get ocrRegisterNewProductTitle;

  /// No description provided for @ocrCanonicalNameRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome canônico *'**
  String get ocrCanonicalNameRequiredLabel;

  /// No description provided for @ocrCanonicalNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Leite Integral 1L'**
  String get ocrCanonicalNameHint;

  /// No description provided for @ocrCanonicalNameRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome canônico'**
  String get ocrCanonicalNameRequiredError;

  /// No description provided for @ocrCategoryRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria *'**
  String get ocrCategoryRequiredLabel;

  /// No description provided for @ocrCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Alimentos, Limpeza, etc.'**
  String get ocrCategoryHint;

  /// No description provided for @ocrCategoryRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'Informe a categoria'**
  String get ocrCategoryRequiredError;

  /// No description provided for @ocrDefaultUnitRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade padrão *'**
  String get ocrDefaultUnitRequiredLabel;

  /// No description provided for @ocrAliasesOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sinônimos / Apelidos (opcional)'**
  String get ocrAliasesOptionalLabel;

  /// No description provided for @ocrAliasesHint.
  ///
  /// In pt, this message translates to:
  /// **'Separados por vírgula'**
  String get ocrAliasesHint;

  /// No description provided for @ocrLinkProductTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vincular produto'**
  String get ocrLinkProductTitle;

  /// No description provided for @ocrProductNameSearchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do produto'**
  String get ocrProductNameSearchLabel;

  /// No description provided for @ocrProductNameSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome do produto'**
  String get ocrProductNameSearchHint;

  /// No description provided for @ocrRegisterNamedAsNew.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar \"{name}\" como novo produto'**
  String ocrRegisterNamedAsNew(String name);

  /// No description provided for @ocrSuggestedProductsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produtos sugeridos:'**
  String get ocrSuggestedProductsLabel;

  /// No description provided for @ocrProductMetaRow.
  ///
  /// In pt, this message translates to:
  /// **'Categoria: {category} | Unidade: {unit}'**
  String ocrProductMetaRow(String category, String unit);

  /// No description provided for @ocrNoExistingProductFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto existente encontrado com esse nome.'**
  String get ocrNoExistingProductFound;

  /// No description provided for @ocrNoneLinked.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get ocrNoneLinked;

  /// No description provided for @ocrItemDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição lida / Nome *'**
  String get ocrItemDescriptionLabel;

  /// No description provided for @ocrItemDescriptionError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome ou descrição'**
  String get ocrItemDescriptionError;

  /// No description provided for @ocrQuantityRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade *'**
  String get ocrQuantityRequiredLabel;

  /// No description provided for @ocrQuantityRequiredError.
  ///
  /// In pt, this message translates to:
  /// **'Informe a qtd'**
  String get ocrQuantityRequiredError;

  /// No description provided for @ocrQuantityInvalidError.
  ///
  /// In pt, this message translates to:
  /// **'Qtd inválida'**
  String get ocrQuantityInvalidError;

  /// No description provided for @ocrUnitRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade *'**
  String get ocrUnitRequiredLabel;

  /// No description provided for @ocrUnitPriceRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço unitário (R\$) *'**
  String get ocrUnitPriceRequiredLabel;

  /// No description provided for @ocrTotalPriceRequiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço total (R\$) *'**
  String get ocrTotalPriceRequiredLabel;

  /// No description provided for @ocrIncludeItemInPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Incluir item na compra'**
  String get ocrIncludeItemInPurchase;

  /// No description provided for @ocrLinkedProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto vinculado:'**
  String get ocrLinkedProductLabel;

  /// No description provided for @ocrChangeOrLinkButton.
  ///
  /// In pt, this message translates to:
  /// **'Trocar / Vincular'**
  String get ocrChangeOrLinkButton;

  /// No description provided for @ocrRegisterProductButton.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar produto'**
  String get ocrRegisterProductButton;

  /// No description provided for @ocrUnlinkTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover vínculo'**
  String get ocrUnlinkTooltip;

  /// No description provided for @ocrUnnamedItemFallback.
  ///
  /// In pt, this message translates to:
  /// **'Item sem nome'**
  String get ocrUnnamedItemFallback;

  /// No description provided for @ocrTotalReadColonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total lido do cupom:'**
  String get ocrTotalReadColonLabel;

  /// No description provided for @ocrSelectedItemsSumColonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Soma dos itens selecionados:'**
  String get ocrSelectedItemsSumColonLabel;

  /// No description provided for @ocrItemSelectHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar {title}'**
  String ocrItemSelectHint(String title);

  /// No description provided for @householdSyncFailure.
  ///
  /// In pt, this message translates to:
  /// **'Falha na sincronização: {error}'**
  String householdSyncFailure(String error);

  /// No description provided for @householdSyncAppliedSuffix.
  ///
  /// In pt, this message translates to:
  /// **' ({count} alterações aplicadas).'**
  String householdSyncAppliedSuffix(int count);

  /// No description provided for @householdSyncSentSuffix.
  ///
  /// In pt, this message translates to:
  /// **' ({count} alterações enviadas).'**
  String householdSyncSentSuffix(int count);

  /// No description provided for @householdSyncCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização concluída: {sent} alterações enviadas, {applied} aplicadas.'**
  String householdSyncCompleted(int sent, int applied);

  /// No description provided for @householdCloudSyncNoChanges.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização em nuvem concluída. Nenhuma alteração pendente.'**
  String get householdCloudSyncNoChanges;

  /// No description provided for @householdSyncUnexpectedError.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado na sincronização: {error}'**
  String householdSyncUnexpectedError(String error);

  /// No description provided for @householdHowSyncWorksTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona a sincronização'**
  String get householdHowSyncWorksTooltip;

  /// No description provided for @householdImportBundleButton.
  ///
  /// In pt, this message translates to:
  /// **'Importar pacote'**
  String get householdImportBundleButton;

  /// No description provided for @householdCloudSyncTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permitir sincronização remota da casa (nuvem)'**
  String get householdCloudSyncTitle;

  /// No description provided for @householdCloudSyncSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar fora do Wi-Fi doméstico com criptografia de ponta a ponta'**
  String get householdCloudSyncSubtitle;

  /// No description provided for @householdCalendarLocalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar agenda neste aparelho'**
  String get householdCalendarLocalTitle;

  /// No description provided for @householdCalendarLocalSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Evita duplicação sincronizando tarefas do Google Calendar só aqui'**
  String get householdCalendarLocalSubtitle;

  /// No description provided for @householdMembersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar membros: {error}'**
  String householdMembersLoadError(String error);

  /// No description provided for @householdThisDevice.
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho'**
  String get householdThisDevice;

  /// No description provided for @householdLastSeen.
  ///
  /// In pt, this message translates to:
  /// **'Visto por último: {time}'**
  String householdLastSeen(String time);

  /// No description provided for @householdNeverSynced.
  ///
  /// In pt, this message translates to:
  /// **'Nunca sincronizou'**
  String get householdNeverSynced;

  /// No description provided for @householdRemoveMemberTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover membro'**
  String get householdRemoveMemberTooltip;

  /// No description provided for @householdDefaultDeviceName.
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
