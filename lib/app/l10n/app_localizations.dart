import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

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
